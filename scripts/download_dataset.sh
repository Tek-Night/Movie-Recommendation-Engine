
#!/bin/bash

set -euo pipefail

# Movie Recommendation Engine
# Downloads and preprocesses the IMDb Top 1000 dataset.

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$PROJECT_DIR/data/raw"
OUTPUT_FILE="$PROJECT_DIR/data/movies_clean.csv"
RAW_FILE="$RAW_DIR/imdb_top_1000.csv"

DATASET_URL="https://raw.githubusercontent.com/Elliott-dev/Top-1000-IMDB-Rated-Movies-Analysis/main/imdb_top_1000.csv"

echo "=========================================="
echo "     MOVIE RECOMMENDATION ENGINE"
echo "       DATASET SETUP"
echo "=========================================="

# Allow optional forced re-download.
FORCE_DOWNLOAD=false

if [[ "${1:-}" == "--force" ]]; then
    FORCE_DOWNLOAD=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--force]"
    exit 1
fi

# Check dependencies.
for command in curl python3; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: Required command '$command' is not installed."
        exit 1
    fi
done

mkdir -p "$RAW_DIR"

TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

# Download the dataset only when necessary.
if [[ ! -f "$RAW_FILE" || "$FORCE_DOWNLOAD" == true ]]; then
    echo "Downloading IMDb Top 1000 dataset..."

    curl --fail --location --silent --show-error \
        --retry 3 \
        "$DATASET_URL" \
        --output "$TEMP_FILE"

    if [[ ! -s "$TEMP_FILE" ]]; then
        echo "Error: Dataset download failed or file is empty."
        exit 1
    fi

    mv "$TEMP_FILE" "$RAW_FILE"
    echo "Download completed."
else
    echo "Existing raw dataset found. Skipping download."
fi

# Validate and clean the dataset.
echo "Cleaning movie data..."

python3 - "$RAW_FILE" "$OUTPUT_FILE" <<'PYTHON'
import csv
import os
import re
import sys
import tempfile

raw_file = sys.argv[1]
output_file = sys.argv[2]

required_columns = [
    "Series_Title",
    "Released_Year",
    "Genre",
    "IMDB_Rating",
    "Director"
]

clean_columns = [
    "ID",
    "Title",
    "Genre",
    "Rating",
    "Year",
    "Director"
]

processed = 0
skipped = 0

output_dir = os.path.dirname(output_file)

with open(raw_file, "r", encoding="utf-8-sig", newline="") as source:
    reader = csv.DictReader(source)

    if not reader.fieldnames:
        raise SystemExit("Error: Dataset has no CSV header.")

    missing = set(required_columns) - set(reader.fieldnames)

    if missing:
        raise SystemExit(
            f"Error: Dataset is missing columns: {sorted(missing)}"
        )

    fd, temporary_output = tempfile.mkstemp(
        prefix="movies_clean_",
        suffix=".csv",
        dir=output_dir
    )

    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as destination:
            writer = csv.writer(destination)
            writer.writerow(clean_columns)

            for row in reader:
                title = (row.get("Series_Title") or "").strip()
                year = (row.get("Released_Year") or "").strip()
                genre = (row.get("Genre") or "").strip()
                director = (row.get("Director") or "").strip()
                rating = (row.get("IMDB_Rating") or "").strip()

                # Validate required values.
                if not title or not director:
                    skipped += 1
                    continue

                if not re.fullmatch(r"\d{4}", year):
                    skipped += 1
                    continue

                try:
                    rating_value = float(rating)
                except ValueError:
                    skipped += 1
                    continue

                if not 0 <= rating_value <= 10:
                    skipped += 1
                    continue

                # Convert genres into a pipe-separated list.
                genres = "|".join(
                    item.strip()
                    for item in genre.split(",")
                    if item.strip()
                )

                if not genres:
                    skipped += 1
                    continue

                # Keep titles on one line and avoid commas in titles
                # for easier compatibility with basic shell processing.
                title = re.sub(r"\s+", " ", title)
                title = title.replace(",", " -")

                processed += 1

                writer.writerow([
                    processed,
                    title,
                    genres,
                    f"{rating_value:.1f}",
                    year,
                    director
                ])

        if processed == 0:
            raise SystemExit("Error: No valid movie records found.")

        os.replace(temporary_output, output_file)

    finally:
        if os.path.exists(temporary_output):
            os.remove(temporary_output)

print(f"Movies processed: {processed}")
print(f"Invalid records skipped: {skipped}")
print(f"Clean dataset: {output_file}")
PYTHON

echo "=========================================="
echo "       DATASET SETUP COMPLETE"
echo "=========================================="

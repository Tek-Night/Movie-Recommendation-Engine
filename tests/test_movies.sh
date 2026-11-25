#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "Running project setup tests..."

# Check required files.
required_files=(
    "movies.sh"
    "lib/common.sh"
    "lib/genre.sh"
    "lib/rating.sh"
    "lib/year.sh"
    "lib/director.sh"
    "lib/feedback.sh"
    "lib/menu.sh"
    "data/movies_clean.csv"
    "data/user_ratings.csv"
    "data/user_preferences.csv"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "FAIL: Missing $file"
        exit 1
    fi
done

echo "PASS: Required files exist."

# Check dataset header.
expected_header="ID,Title,Genre,Rating,Year,Director"
actual_header="$(head -n 1 data/movies_clean.csv)"

if [[ "$actual_header" != "$expected_header" ]]; then
    echo "FAIL: Dataset header does not match."
    exit 1
fi

echo "PASS: Dataset header is correct."

# Check that the dataset contains movie records.
if [[ "$(wc -l < data/movies_clean.csv)" -le 1 ]]; then
    echo "FAIL: Dataset contains no movie records."
    exit 1
fi

echo "PASS: Dataset contains movie records."

# Check Bash syntax.
for file in movies.sh lib/*.sh tests/*.sh scripts/*.sh; do
    bash -n "$file"
done

echo "PASS: All Bash scripts pass syntax checks."

# Check the help command.
./movies.sh --help >/dev/null

echo "PASS: Main script help command works."
echo "=========================================="
echo "ALL SETUP TESTS PASSED"
echo "=========================================="

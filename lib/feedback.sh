#!/bin/bash

# Member 5: User ratings and preferences.

# Locations of the two user data files. movies.sh sets PROJECT_DIR; the
# fallback lets this file still find the data folder if it is sourced alone.
FEEDBACK_DATA_DIR="${PROJECT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}/data"
RATINGS_FILE="$FEEDBACK_DATA_DIR/user_ratings.csv"
PREFERENCES_FILE="$FEEDBACK_DATA_DIR/user_preferences.csv"

# Check that a value is a number from 0 to 10 (same two-step check as rating.sh).
# Arguments: value
# Returns 0 if valid, 1 otherwise. Prints nothing; the caller shows the error.
_is_valid_rating() {
    local value="$1"

    # Step 1: looks like a number (digits, optionally with a decimal part).
    if [[ ! "$value" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        return 1
    fi

    # Step 2: lies between 0 and 10 (awk handles decimals, bash cannot).
    awk -v r="$value" 'BEGIN { exit !(r >= 0 && r <= 10) }'
}

# Add or update one "key,value" row in a two-column CSV file.
# Arguments: file, header_line, key, value
# Prints "added" or "updated" on success. Returns 1 on any failure.
# The caller must already have validated key and value (no commas, no
# characters that are special to sed).
_upsert_csv_row() {
    local file="$1"
    local header="$2"
    local key="$3"
    local value="$4"

    # Create the file with its header if it is missing or empty.
    if [[ ! -s "$file" ]]; then
        if ! echo "$header" > "$file"; then
            print_error "Cannot write to $file"
            return 1
        fi
    fi

    # "^key," matches the whole first column, so ID 1 never matches ID 10.
    # grep sits inside an if, so "no match" does not trigger set -e.
    if grep -q "^${key}," "$file"; then
        # Row exists: replace the whole line with sed.
        # -i.bak works on both GNU and macOS sed; the backup is removed below.
        if ! sed -i.bak "s/^${key},.*/${key},${value}/" "$file"; then
            print_error "Could not update $file"
            return 1
        fi
        rm -f "$file.bak"

        # sed stays silent when it changes nothing, so confirm the new line exists.
        if ! grep -Fxq "${key},${value}" "$file"; then
            print_error "Update did not change $file"
            return 1
        fi
        echo "updated"
    else
        # New row: if the last line has no trailing newline, add one first
        # so the new row does not get glued onto it.
        if [[ -n "$(tail -c 1 "$file")" ]]; then
            echo >> "$file"
        fi
        if ! echo "${key},${value}" >> "$file"; then
            print_error "Could not write to $file"
            return 1
        fi
        echo "added"
    fi
}

# Save or update the user's rating for a movie.
# Arguments: movie_id, user_rating, dataset_path
# Returns 0 on success, 1 on invalid input or failure.
rate_movie() {
    local movie_id="${1:-}"
    local user_rating="${2:-}"
    local dataset="${3:-}"

    # Validate everything first; the ratings file is only touched at the end.
    if [[ -z "$movie_id" || -z "$user_rating" ]]; then
        print_error "Both a movie ID and a rating are required."
        return 1
    fi

    if [[ -z "$dataset" ]]; then
        print_error "Movie dataset path is required."
        return 1
    fi

    check_dataset "$dataset" || return 1

    # Positive whole number, no leading zeros ("01" would otherwise be stored
    # as a second row for movie 1).
    if [[ ! "$movie_id" =~ ^[1-9][0-9]*$ ]]; then
        print_error "Movie ID must be a positive whole number."
        return 1
    fi

    # Look up the title; it is empty if the ID is not in the first column.
    local title
    title=$(awk -F',' -v id="$movie_id" 'NR > 1 && $1 == id { print $2; exit }' "$dataset")
    if [[ -z "$title" ]]; then
        print_error "Movie ID $movie_id was not found in the dataset."
        return 1
    fi

    if ! _is_valid_rating "$user_rating"; then
        print_error "Rating must be a number between 0 and 10."
        return 1
    fi

    local action
    if ! action=$(_upsert_csv_row "$RATINGS_FILE" "MovieID,UserRating" "$movie_id" "$user_rating"); then
        return 1
    fi

    print_info "Rating ${action} for \"$title\" (ID $movie_id): $user_rating"
    return 0
}

# Save or update a user preference, for example:
#   save_preference genre "Sci-Fi"
#   save_preference min_rating 8.5
# Arguments: preference_name, preference_value
# Returns 0 on success, 1 on invalid input or failure.
save_preference() {
    local preference="${1:-}"
    local value="${2:-}"

    if [[ -z "$preference" || -z "$value" ]]; then
        print_error "Both a preference name and a value are required."
        return 1
    fi

    # The name becomes part of a sed pattern, so keep it to safe characters.
    if [[ ! "$preference" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        print_error "Preference name may only use letters, digits and underscores."
        return 1
    fi

    # "Preference" is the CSV header text; saving it would overwrite the header.
    if [[ "$preference" == "Preference" ]]; then
        print_error "\"Preference\" is a reserved name. Choose another."
        return 1
    fi

    # The value becomes part of a sed replacement and a CSV field, so allow
    # only words made of letters, digits and . _ | - separated by single
    # spaces. This blocks commas, slashes, & and backslashes.
    local value_pattern='^[A-Za-z0-9._|-]+( [A-Za-z0-9._|-]+)*$'
    if [[ ! "$value" =~ $value_pattern ]]; then
        print_error "Preference value may only use letters, digits, spaces and . _ | -"
        return 1
    fi

    # A saved minimum rating must be usable later by recommend_by_rating.
    if [[ "$preference" == "min_rating" ]] && ! _is_valid_rating "$value"; then
        print_error "min_rating must be a number between 0 and 10."
        return 1
    fi

    local action
    if ! action=$(_upsert_csv_row "$PREFERENCES_FILE" "Preference,Value" "$preference" "$value"); then
        return 1
    fi

    print_info "Preference ${action}: $preference = $value"
    return 0
}

#!/bin/bash

# Member 2: Minimum-rating recommendations.
# Arguments: minimum_rating, dataset_path

recommend_by_rating() {
    local minimum_rating="$1"
    local dataset="$2"

    # Check if rating was provided
    if [[ -z "$minimum_rating" ]]; then
        print_error "Please provide a minimum rating."
        return 1
    fi

    # Check if rating is numeric
    if [[ ! "$minimum_rating" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        print_error "Rating must be a number."
        return 1
    fi

    # Check rating range (0 to 10)
    if ! awk -v rating="$minimum_rating" 'BEGIN {
        exit !(rating >= 0 && rating <= 10)
    }'; then
        print_error "Rating must be between 0 and 10."
        return 1
    fi

    # Check if dataset exists
    if [[ ! -f "$dataset" ]]; then
        print_error "Movie dataset not found: $dataset"
        return 1
    fi

    # Create temporary file for filtered movies
    local temp_file
    temp_file=$(mktemp) || return 1

    # Filter movies with rating >= minimum rating
    awk -F',' -v min="$minimum_rating" '
        NR > 1 && $4 >= min {
            printf "%s\t%s\t%s\t%s\t%s\n", $4, $2, $3, $5, $6
        }
    ' "$dataset" > "$temp_file"

    # Check if any movies matched
    if [[ ! -s "$temp_file" ]]; then
        print_error "No movies found with rating $minimum_rating or higher."
        rm -f "$temp_file"
        return 1
    fi

    # Display results sorted by rating (highest first)
    echo
    echo "Movies rated $minimum_rating or higher:"
    echo
    printf "Rating\tTitle\tGenre\tYear\tDirector\n"

    sort -t $'\t' -k1,1nr "$temp_file" | column -t -s $'\t'

    # Remove temporary file
    rm -f "$temp_file"

    return 0
}
#!/bin/bash

# Member 1: Genre-based recommendations.
# Arguments: genre, dataset_path
recommend_by_genre() {
    local genre="$1"
    local dataset="$2"

    if [[ -z "$genre" ]]; then
       print_error "Genre cannot be empty."
       return 1
    fi

    local results
    results=$(awk -F',' -v target="$genre" '
        BEGIN { target_lowercase = tolower(target) }
        NR > 1 {
            n = split($3, genres, "|")
            for (i = 1; i <= n; i++) {
                if (tolower(genres[i]) == target_lowercase) {
                    print $0
                    break
                }
            }
        }
    ' "$dataset")

    if [[ -z "$results" ]]; then
        print_info "No movies found matching genre: $genre"
        return 0
    fi

    {
        head -n 1 "$dataset"
        printf "%s\n" "$results"
    } | column -t -s ','
	
}


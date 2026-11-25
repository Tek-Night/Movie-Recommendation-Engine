#!/bin/bash

# Shared utilities for the Movie Recommendation Engine.

# Print an error message to standard error.
print_error() {
    echo "Error: $*" >&2
}

# Print an informational message.
print_info() {
    echo "$*"
}

# Check that the movie dataset exists.
check_dataset() {
    local dataset="$1"

    if [[ ! -f "$dataset" ]]; then
        print_error "Movie dataset not found: $dataset"
        return 1
    fi

    return 0
}

# Print a standard application heading.
print_header() {
    echo "=========================================="
    echo "       MOVIE RECOMMENDATION ENGINE"
    echo "=========================================="
}

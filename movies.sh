#!/bin/bash

set -euo pipefail

# Resolve the project directory so the script works from any location.
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DATA="$PROJECT_DIR/data/movies_clean.csv"

# Load shared utilities and feature modules.
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/genre.sh"
source "$PROJECT_DIR/lib/rating.sh"
source "$PROJECT_DIR/lib/year.sh"
source "$PROJECT_DIR/lib/director.sh"
source "$PROJECT_DIR/lib/feedback.sh"
source "$PROJECT_DIR/lib/menu.sh"

show_usage() {
    cat <<USAGE
Usage:
  ./movies.sh --genre GENRE
  ./movies.sh --min-rating RATING
  ./movies.sh --year START-END
  ./movies.sh --director "DIRECTOR NAME"
  ./movies.sh --rate MOVIE_ID USER_RATING
  ./movies.sh

Options:
  --genre       Find movies by genre.
  --min-rating  Find movies at or above a minimum IMDb rating.
  --year        Find movies within an inclusive year range.
  --director    Find movies by director.
  --rate        Save or update a personal movie rating.
  --help        Display this help message.

Running without arguments opens the interactive menu.
USAGE
}

# Display the interactive menu when no arguments are supplied.
if [[ $# -eq 0 ]]; then
    check_dataset "$DATA"
    show_menu
    exit 0
fi

# Handle help without requiring the dataset.
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_usage
    exit 0
fi

# Validate the dataset before running a feature.
check_dataset "$DATA"

case "$1" in
    --genre)
        if [[ $# -ne 2 ]]; then
            print_error "Usage: ./movies.sh --genre GENRE"
            exit 1
        fi
        recommend_by_genre "$2" "$DATA"
        ;;

    --min-rating)
        if [[ $# -ne 2 ]]; then
            print_error "Usage: ./movies.sh --min-rating RATING"
            exit 1
        fi
        recommend_by_rating "$2" "$DATA"
        ;;

    --year)
        if [[ $# -ne 2 ]]; then
            print_error "Usage: ./movies.sh --year START-END"
            exit 1
        fi
        recommend_by_year "$2" "$DATA"
        ;;

    --director)
        if [[ $# -ne 2 ]]; then
            print_error 'Usage: ./movies.sh --director "DIRECTOR NAME"'
            exit 1
        fi
        recommend_by_director "$2" "$DATA"
        ;;

    --rate)
        if [[ $# -ne 3 ]]; then
            print_error "Usage: ./movies.sh --rate MOVIE_ID USER_RATING"
            exit 1
        fi
        rate_movie "$2" "$3" "$DATA"
        ;;

    *)
        print_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac

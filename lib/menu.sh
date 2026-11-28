#!/bin/bash

# Member 5: Interactive terminal menu.
#
# Every option calls the same functions the command-line flags use, so no
# search or validation logic is repeated here.
#
# movies.sh runs with "set -e", which ends the whole script when a command
# returns non-zero. The functions below return non-zero for invalid input and
# they already print their own error message, so each call ends with
# "|| true": the menu just carries on and shows the options again.
#
# "read -r" (with the default IFS) also strips leading and trailing spaces
# from what the user types.
#
# Uses DATA (the dataset path), which movies.sh sets before calling show_menu.
show_menu() {
    local dataset="${DATA:-}"
    local choice genre rating year_range director user_rating

    if [[ -z "$dataset" ]]; then
        print_error "Dataset path is not set."
        return 1
    fi

    print_header

    while true; do
        echo
        echo "  1) Find movies by genre"
        echo "  2) Find movies by minimum rating"
        echo "  3) Find movies by year range"
        echo "  4) Find movies by director"
        echo "  5) Rate a movie"
        echo "  6) Save preferences"
        echo "  7) Exit"
        echo

        # read fails at end of input (Ctrl-D); leave cleanly instead of looping forever.
        if ! read -r -p "Choose an option (1-7): " choice; then
            echo
            print_info "Goodbye!"
            return 0
        fi
        echo

        # The same applies to every prompt below: "|| return 0" leaves the
        # menu if input ends (Ctrl-D) in the middle of a question.
        case "$choice" in
            1)
                read -r -p "Genre (example: Drama): " genre || return 0
                recommend_by_genre "$genre" "$dataset" || true
                ;;
            2)
                read -r -p "Minimum rating, 0-10 (example: 8.5): " rating || return 0
                recommend_by_rating "$rating" "$dataset" || true
                ;;
            3)
                read -r -p "Year range (example: 2000-2010): " year_range || return 0
                recommend_by_year "$year_range" "$dataset" || true
                ;;
            4)
                read -r -p "Director name (example: Christopher Nolan): " director || return 0
                recommend_by_director "$director" "$dataset" || true
                ;;
            5)
                if _pick_movie_id "$dataset"; then
                    read -r -p "Your rating, 0-10: " user_rating || return 0
                    rate_movie "$MENU_MOVIE_ID" "$user_rating" "$dataset" || true
                fi
                ;;
            6)
                read -r -p "Preferred genre (Enter to skip): " genre || return 0
                read -r -p "Minimum rating, 0-10 (Enter to skip): " rating || return 0

                if [[ -z "$genre" && -z "$rating" ]]; then
                    print_info "No preferences entered."
                fi
                if [[ -n "$genre" ]]; then
                    save_preference "genre" "$genre" || true
                fi
                if [[ -n "$rating" ]]; then
                    save_preference "min_rating" "$rating" || true
                fi
                ;;
            7)
                print_info "Goodbye!"
                return 0
                ;;
            *)
                print_error "Invalid option. Please enter a number from 1 to 7."
                ;;
        esac
    done
}

# Look up movies by title, ignoring capitalization.
# Titles that match exactly are returned; if there are none, titles that
# merely contain the typed text are returned instead.
# Arguments: search_text, dataset_path
# Prints one "ID,Title,Year" line per match (nothing if there are none).
_find_movies_by_title() {
    local search="$1"
    local dataset="$2"

    awk -F',' -v search="$search" '
        BEGIN { search = tolower(search) }
        NR > 1 {
            name = tolower($2)
            if (name == search) {
                exact = exact $1 "," $2 "," $5 "\n"
            } else if (index(name, search) > 0) {
                partial = partial $1 "," $2 "," $5 "\n"
            }
        }
        END { printf "%s", (exact != "" ? exact : partial) }
    ' "$dataset"
}

# Ask for a movie name and work out its ID, so the user never needs to know it.
# On success sets MENU_MOVIE_ID and returns 0. Returns 1 (after printing a
# message where needed) if no single movie could be chosen.
# Argument: dataset_path
_pick_movie_id() {
    local dataset="$1"
    local name matches count choice line id title year n

    MENU_MOVIE_ID=""

    read -r -p "Movie name (any capitalization): " name || return 1
    if [[ -z "$name" ]]; then
        print_error "Movie name cannot be empty."
        return 1
    fi

    matches=$(_find_movies_by_title "$name" "$dataset")
    if [[ -z "$matches" ]]; then
        print_error "No movie found with the name: $name"
        return 1
    fi

    count=$(printf '%s\n' "$matches" | wc -l)
    line="$matches"

    if (( count > 10 )); then
        print_error "$count movies match \"$name\". Please type more of the name."
        return 1
    fi

    # Several matches (for example two movies with the same title): let the
    # user pick one from a numbered list.
    if (( count > 1 )); then
        echo "More than one movie matches:"
        n=0
        while IFS=, read -r id title year; do
            n=$((n + 1))
            echo "  $n) $title ($year)"
        done <<< "$matches"

        read -r -p "Enter the number of the movie you mean: " choice || return 1
        if [[ ! "$choice" =~ ^[1-9][0-9]{0,2}$ ]] || (( choice > count )); then
            print_error "Invalid choice."
            return 1
        fi
        line=$(sed -n "${choice}p" <<< "$matches")
    fi

    IFS=, read -r id title year <<< "$line"
    print_info "Found: $title ($year)"
    MENU_MOVIE_ID="$id"
    return 0
}

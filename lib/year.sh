
#!/bin/bash

# Member 3: Year-range recommendations.
# Arguments: year_range, dataset_path

recommend_by_year() {
    local year_range="$1"
    local dataset="$2"

    # Validate empty input.
    if [[ -z "$year_range" ]]; then
        print_error "Year range cannot be empty."
        return 1
    fi

    # Validate YYYY-YYYY format.
    if [[ ! "$year_range" =~ ^[0-9]{4}-[0-9]{4}$ ]]; then
        print_error "Invalid format. Use START-END (example: 2000-2010)."
        return 1
    fi

    local start_year="${year_range%-*}"
    local end_year="${year_range#*-}"

    # Validate range order.
    if (( start_year > end_year )); then
        print_error "Start year cannot be greater than end year."
        return 1
    fi

    # Check dataset.
    if ! check_dataset "$dataset"; then
        return 1
    fi

    local results

    results=$(awk -F',' -v start="$start_year" -v end="$end_year" '
        NR > 1 && $5 >= start && $5 <= end {
            print $0
        }
    ' "$dataset")

    # Handle no matching movies.
    if [[ -z "$results" ]]; then
        print_info "No movies found between $start_year and $end_year."
        return 0
    fi

    # Display header and results.
    {
        head -n 1 "$dataset"
        printf "%s\n" "$results"
    } | column -t -s ','
}

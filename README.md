# Movie Recommendation Engine

A command-line Movie Recommendation Engine developed using **Bash scripting** as part of the Scripting Workshop project.

The application allows users to discover movies based on genres, IMDb ratings, release years and directors. It also provides functionality for recording personal movie ratings and preferences.

---

## 1. Features

The application is designed to support the following features:

| Feature | Description |
|---|---|
| Genre-based recommendations | Find movies belonging to a specified genre |
| Rating-based recommendations | Find movies with an IMDb rating above a specified threshold |
| Year-based recommendations | Find movies released within a specified year or year range |
| Director-based recommendations | Find movies directed by a specified director |
| Movie ratings | Allow users to record their personal ratings for movies |
| User preferences | Store user preferences for future use |
| Interactive menu | Provide an interactive interface for accessing application features |

## 2. Dataset

This project uses the **IMDb Top 1000 Movies Dataset**.

The dataset contains information about 1,000 highly rated movies, including their titles, genres, IMDb ratings, release years and directors.

### Dataset source

- Dataset: IMDb Top 1000 Movies
- Source repository: [IMDb Top 1000 Movies CSV](https://github.com/Elliott-dev/Top-1000-IMDB-Rated-Movies-Analysis)
- Raw filename: `imdb_top_1000.csv`

The raw dataset is downloaded automatically by the project's setup script.

### Data preprocessing

The project includes a preprocessing script that:

1. Downloads the raw IMDb dataset.
2. Validates the required CSV columns.
3. Removes records containing invalid or missing required values.
4. Normalizes genre values using `|` as a separator.
5. Generates sequential movie IDs.
6. Extracts the relevant movie information.
7. Produces a cleaned CSV file for use by the recommendation modules.

The resulting cleaned dataset is stored at:

`data/movies_clean.csv`

### Cleaned dataset schema

The cleaned dataset uses the following six-column format:

| Column | Description |
|---|---|
| `ID` | Unique sequential identifier generated during preprocessing |
| `Title` | Movie title |
| `Genre` | Movie genres separated by `\|` |
| `Rating` | IMDb rating |
| `Year` | Release year |
| `Director` | Movie director |

Example:

```csv
ID,Title,Genre,Rating,Year,Director
1,The Shawshank Redemption,Drama,9.3,1994,Frank Darabont
2,The Godfather,Crime|Drama,9.2,1972,Francis Ford Coppola
3,The Dark Knight,Action|Crime|Drama,9.0,2008,Christopher Nolan
```

**Important:** All recommendation modules must use this cleaned six-column format. The schema should remain consistent across the project.

## 3. Project Structure

```text
Movie-Recommendation-Engine/
│
├── movies.sh
├── README.md
├── .gitignore
│
├── data/
│   ├── raw/
│   │   └── imdb_top_1000.csv
│   │
│   ├── movies_clean.csv
│   ├── user_ratings.csv
│   └── user_preferences.csv
│
├── scripts/
│   └── download_dataset.sh
│
├── lib/
│   ├── common.sh
│   ├── genre.sh
│   ├── rating.sh
│   ├── year.sh
│   ├── director.sh
│   ├── feedback.sh
│   └── menu.sh
│
└── tests/
    └── test_movies.sh
```

### Directory description

- `movies.sh`: Main application entry point and command dispatcher.
- `data/`: Contains the movie dataset and user-related CSV files.
- `data/raw/`: Stores the downloaded original dataset locally.
- `scripts/`: Contains dataset downloading and preprocessing scripts.
- `lib/`: Contains the individual application modules and shared functions.
- `tests/`: Contains project validation and testing scripts.

## 4. Requirements

The project requires:

- Bash
- Python 3
- `curl`
- A Unix-like environment (macOS or Linux)

Python is used only for downloading-related preprocessing and CSV handling. No third-party Python packages are required.

## 5. Setup and Installation

### Step 1: Clone the repository

```bash
git clone <repository-url>
cd Movie-Recommendation-Engine
```

### Step 2: Set executable permissions

```bash
chmod +x movies.sh
chmod +x scripts/download_dataset.sh
chmod +x tests/test_movies.sh
```

### Step 3: Set up the dataset

The cleaned dataset is included in the repository, so teammates can start working immediately after cloning.

To regenerate the dataset:

```bash
./scripts/download_dataset.sh
```

To force a fresh download of the raw dataset:

```bash
./scripts/download_dataset.sh --force
```

The script downloads the original CSV into `data/raw/`, validates it and regenerates `data/movies_clean.csv`.

**Note:** The raw CSV is not committed to the repository. The cleaned dataset is committed so that every team member has access to the same movie data without needing to download or preprocess it independently.

## 6. Usage

The application supports command-line arguments for accessing its recommendation features.

Run the application using:

```bash
./movies.sh [OPTION] [ARGUMENT]
```

### Genre-based recommendations

```bash
./movies.sh --genre Sci-Fi
```

Finds movies belonging to the specified genre.

### Minimum-rating recommendations

```bash
./movies.sh --min-rating 8.5
```

Finds movies with an IMDb rating greater than or equal to the specified threshold.

### Year-based recommendations

```bash
./movies.sh --year 2000-2010
```

Finds movies released within the specified year range.

### Director-based recommendations

```bash
./movies.sh --director "Christopher Nolan"
```

Finds movies directed by the specified director.

### Record a personal movie rating

```bash
./movies.sh --rate 1 9.5
```

Records a personal rating of 9.5 for the movie with ID 1.

### Interactive menu

```bash
./movies.sh
```

Launches the interactive application menu.

## 7. User Data Files

The application maintains separate CSV files for storing user-related information.

### `data/user_ratings.csv`

Stores movie ratings submitted by the user.

Header:

```csv
MovieID,UserRating
```

### `data/user_preferences.csv`

Stores user preferences.

Header:

```csv
Preference,Value
```

These files are maintained separately from the main movie dataset.

## 8. Testing

The project includes a basic test script:

```bash
./tests/test_movies.sh
```

The tests validate:

- Required project files exist.
- The cleaned dataset has the expected header.
- The dataset contains movie records.
- Shell scripts pass syntax validation.

Additional tests can be added as individual recommendation modules are implemented.

## 9. Team Development

The project is divided into separate modules to allow team members to work independently.

| Module | Responsibility |
|---|---|
| Genre | Genre-based movie recommendations |
| Rating | Minimum IMDb rating recommendations |
| Year | Release-year and year-range recommendations |
| Director | Director-based movie recommendations |
| Feedback | Recording user ratings and preferences |
| Menu | Interactive application interface |
| Common | Shared utility functions and error handling |
| Main | Application entry point and command dispatching |

Each module is maintained in its own shell script under `lib/`.

### Development guidelines

1. All modules must use the shared cleaned dataset.
2. Do not independently modify the cleaned CSV schema.
3. Keep module functions separate and reusable.
4. Use the shared functions in `lib/common.sh` wherever appropriate.
5. Test changes before integrating them into the main application.
6. Avoid modifying another team member's module without coordinating with them.

## 10. Limitations

- The dataset contains 1,000 selected movies rather than an exhaustive movie catalogue.
- Recommendations are based on the available metadata and filtering criteria.
- The project does not currently implement machine learning or collaborative filtering.
- User ratings and preferences are stored locally in CSV files.

## 11. License and Attribution

This project uses a third-party copy of IMDb Top 1000 movie data for educational purposes.

The dataset's redistribution and usage conditions should be checked against its original source before redistributing the raw data.

The application code and dataset should be treated as separate materials with their respective licensing terms.

---

**Project:** Movie Recommendation Engine  
**Course:** Scripting Workshop  
**Implementation:** Bash Shell Scripting
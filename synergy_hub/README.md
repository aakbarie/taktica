# Synergy Hub

**IT Business Relationship Management System**

Synergy Hub is a comprehensive Shiny application designed to manage IT business relationships, track performance scores, and analyze trends. This tool helps IT departments maintain strong partnerships with business units by providing structured feedback collection, relationship tracking, and performance analytics.

---

## Features

### 1. **Dashboard (Data Entry)**
- Record interactions between ITS partners and business partners
- Track service experience scores (1-10)
- Track work product scores (1-10)
- Add comments, leadership reviews, and action requests
- Dynamic filtering of business partners, departments, and divisions

### 2. **Entries View**
- Display all recorded entries in a sortable, filterable table
- Tooltips for long text fields
- Export capabilities

### 3. **Score Analysis**
- Monthly trend analysis of average scores
- Identification of lowest scorers
- Interactive Plotly visualizations
- 12-month rolling window

### 4. **Update Management**
- Edit leadership reviews, action requests, and resolutions
- Mark tickets as completed
- Track ticket status

### 5. **Unresolved Tickets**
- Filter view showing only incomplete tickets
- Quick resolution interface
- Full comment visibility

### 6. **Visualization**
- Sankey diagram showing relationships between:
  - ITS Partners → Business Partners → Departments
- Interactive network visualization

### 7. **Personnel Management**
- Add/edit/delete ITS personnel
- Add/edit/delete business partners
- Manage relationships between ITS and business partners
- Persist changes to CSV files

### 8. **How-To Guide**
- Integrated user documentation
- Step-by-step instructions

---

## Project Structure

```
synergy_hub/
├── app.R                          # Main Shiny application
├── R/
│   ├── data_utils.R               # Data loading, saving, and manipulation
│   ├── ui_components.R            # UI component functions
│   └── server_logic.R             # Business logic functions
├── tests/
│   ├── testthat.R                 # Test runner
│   └── testthat/
│       ├── test-data_utils.R      # Tests for data utilities
│       ├── test-ui_components.R   # Tests for UI components
│       └── test-server_logic.R    # Tests for server logic
├── www/
│   ├── styles.css                 # Custom CSS styles
│   └── How_To.md                  # User guide (Markdown)
├── data/                          # Data storage directory
└── README.md                      # This file
```

---

## Installation

### Prerequisites

- R (version 4.0 or higher)
- RStudio (recommended)

### Required R Packages

Install the required packages:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "readr",
  "dplyr",
  "DT",
  "lubridate",
  "ggplot2",
  "arrow",
  "plotly",
  "testthat"
))
```

---

## Configuration

Before running the application, update the file paths in `app.R` to match your environment:

```r
entries_file <- "/your/path/to/entries.parquet"
its_personnel_file <- "/your/path/to/its_personnel.csv"
business_partners_file <- "/your/path/to/business_partners.csv"
relationships_file <- "/your/path/to/brm_assignments.csv"
```

Alternatively, use local paths:

```r
entries_file <- "data/entries.parquet"
its_personnel_file <- "data/its_personnel.csv"
business_partners_file <- "data/business_partners.csv"
relationships_file <- "data/brm_assignments.csv"
```

---

## Running the Application

### From RStudio

1. Open `app.R` in RStudio
2. Click the "Run App" button
3. The application will launch in a browser or RStudio viewer

### From Command Line

```bash
cd synergy_hub
R -e "shiny::runApp('app.R')"
```

### Specify Host and Port

```r
shiny::runApp('app.R', host = '0.0.0.0', port = 3838)
```

---

## Running Tests

### Run All Tests

From the project root directory:

```bash
cd synergy_hub
Rscript tests/testthat.R
```

### Run Tests from R Console

```r
library(testthat)
test_dir("tests/testthat")
```

### Run Individual Test Files

```r
test_file("tests/testthat/test-data_utils.R")
test_file("tests/testthat/test-ui_components.R")
test_file("tests/testthat/test-server_logic.R")
```

---

## Data Files

### Entries (Parquet)
Stores all interaction records with fields:
- Date, ITS_Partner, Business_Partner, Department, Division
- Service_Experience_Score, Work_Product_Score
- Completed, Comments, Leadership_Review, Action_Requested, Resolution

### ITS Personnel (CSV)
Lists all ITS personnel:
- ITS_Partner

### Business Partners (CSV)
Lists all business partners with details:
- Business_Partner, Department, Division

### Relationships (CSV)
Maps relationships between ITS and business partners:
- PARTNER (IT), DIRECTORS/MANAGERS, DEPARTMENT (Bus.), DIVISION

---

## Usage Guidelines

### Adding a New Entry

1. Navigate to the **Dashboard** tab
2. Select the date
3. Choose an ITS partner (filters business partners)
4. Select a business partner (filters departments and divisions)
5. Enter service and work product scores (1-10)
6. Add optional comments, leadership reviews, and action requests
7. Click **Submit**

### Updating an Entry

1. Navigate to the **Update** tab
2. Click on a row to select it
3. Edit leadership review, action requested, resolution, or completion status
4. Click **Save Changes**

### Resolving Tickets

1. Navigate to the **Unresolved Tickets** tab
2. Click on a ticket to resolve
3. Add resolution details
4. Mark as completed
5. Click **Save Changes**

### Managing Relationships

1. Navigate to **Manage ITS Personnel** tab
2. Select an ITS personnel member
3. Check/uncheck business partners to assign
4. Click **Save Relationships**

---

## Testing Strategy

### Unit Tests

The application includes comprehensive unit tests for:

1. **Data Utilities** (`test-data_utils.R`)
   - Data initialization
   - Loading and saving (Parquet/CSV)
   - Entry validation
   - Tooltip generation

2. **UI Components** (`test-ui_components.R`)
   - Tab creation
   - Follow-up question generation
   - UI element presence

3. **Server Logic** (`test-server_logic.R`)
   - Data filtering
   - Score analysis calculations
   - Sankey diagram data preparation
   - Relationship management

### Test Coverage

All core functions are tested with:
- Valid inputs
- Invalid/edge case inputs
- Empty data scenarios
- Data transformation accuracy

---

## UX Design Principles

### Color Scheme
- **Primary**: Blues and teals for professional IT branding
- **Success**: Green for positive actions
- **Warning**: Orange for attention items
- **Danger**: Red for unresolved issues

### Responsive Feedback
- Dynamic follow-up questions based on scores
- Modal confirmations for all save operations
- Tooltips for truncated text

### Intuitive Navigation
- Icon-based sidebar menu
- Logical tab organization
- Consistent action buttons

### Data Integrity
- Required field validation
- Score range enforcement (1-10)
- Cascading filters (ITS → Business → Department/Division)

---

## Troubleshooting

### Application Won't Start

**Issue**: Missing packages
**Solution**: Install all required packages (see Installation section)

**Issue**: File path errors
**Solution**: Update file paths in `app.R` or create directories

### Tests Failing

**Issue**: Working directory incorrect
**Solution**: Ensure tests are run from project root

**Issue**: Missing dependencies
**Solution**: Install `testthat` package

### Data Not Saving

**Issue**: Permission errors
**Solution**: Check write permissions for data directory

**Issue**: Invalid file paths
**Solution**: Verify all paths exist and are accessible

---

## Contributing

### Code Style

- Use meaningful variable names
- Comment complex logic
- Follow R best practices
- Keep functions focused and small

### Adding New Features

1. Create functions in appropriate module (`R/`)
2. Write unit tests (`tests/testthat/`)
3. Update documentation
4. Test thoroughly before committing

### Reporting Issues

Please include:
- R version
- Package versions
- Error messages
- Steps to reproduce

---

## License

[Specify your license here]

---

## Support

For questions or issues:
- Review the How-To Guide in the application
- Check this README
- Contact the development team

---

## Version History

### v1.0.0 (2026-01-20)
- Initial release
- Core functionality implemented
- Comprehensive unit tests
- Modular architecture

---

## Authors

Developed by the Taktica team

---

## Acknowledgments

Built with:
- Shiny by RStudio
- Plotly for visualizations
- DT for interactive tables
- Arrow for efficient data storage

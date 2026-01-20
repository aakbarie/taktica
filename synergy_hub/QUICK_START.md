# Synergy Hub - Quick Start Guide

Get Synergy Hub running in 5 minutes!

---

## Prerequisites

You need:
- R (version 4.0+)
- RStudio (recommended)

---

## Installation Steps

### Step 1: Install R Packages

Open R or RStudio and run:

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
  "plotly"
))
```

**Time**: 2-3 minutes

### Step 2: Configure File Paths

Open `app.R` and update the file paths (lines 20-23):

**Option A: Use Local Data Directory (Recommended for Testing)**

```r
entries_file <- "data/entries.parquet"
its_personnel_file <- "data/its_personnel.csv"
business_partners_file <- "data/business_partners.csv"
relationships_file <- "data/brm_assignments.csv"
```

**Option B: Use Custom Directory**

```r
entries_file <- "/your/custom/path/entries.parquet"
its_personnel_file <- "/your/custom/path/its_personnel.csv"
business_partners_file <- "/your/custom/path/business_partners.csv"
relationships_file <- "/your/custom/path/brm_assignments.csv"
```

**Time**: 1 minute

### Step 3: Create Initial Data (Optional)

If you want to start with sample data, create these CSV files:

**data/its_personnel.csv**
```csv
ITS_Partner
John Doe
Jane Smith
Bob Johnson
```

**data/business_partners.csv**
```csv
Business_Partner,Department,Division
Alice Williams,Marketing,Digital
Charlie Brown,Sales,Enterprise
Diana Prince,Operations,Customer Success
```

**data/brm_assignments.csv**
```csv
PARTNER (IT),DIRECTORS/MANAGERS,DEPARTMENT (Bus.),DIVISION
John Doe,Alice Williams,Marketing,Digital
John Doe,Charlie Brown,Sales,Enterprise
Jane Smith,Diana Prince,Operations,Customer Success
```

**Time**: 2 minutes (or skip and add via UI)

### Step 4: Run the Application

**From RStudio:**
1. Open `app.R`
2. Click the "Run App" button in the top-right corner
3. The app will open in a new window

**From R Console:**
```r
setwd("path/to/synergy_hub")
shiny::runApp("app.R")
```

**From Command Line:**
```bash
cd synergy_hub
R -e "shiny::runApp('app.R')"
```

**Time**: Instant!

---

## First Steps in the App

### 1. Add ITS Personnel (If Not Using Sample Data)

1. Navigate to "Manage ITS Personnel" tab
2. Click "Add ITS Personnel"
3. Enter name (e.g., "John Doe")
4. Click "Add"
5. Click "Save ITS Personnel"

### 2. Add Business Partners

1. In the same tab, look at the right panel
2. Click "Add Business Partner"
3. Enter:
   - Name: "Alice Williams"
   - Department: "Marketing"
   - Division: "Digital"
4. Click "Add"
5. Click "Save Business Partners"

### 3. Create Relationships

1. Still in "Manage ITS Personnel" tab
2. Scroll down to "Relationship Management"
3. Select an ITS Personnel from dropdown
4. Check the boxes for Business Partners to assign
5. Click "Save Relationships"

### 4. Record Your First Entry

1. Navigate to "Dashboard" tab
2. Select today's date
3. Choose an ITS Partner (dropdown will populate)
4. Choose a Business Partner (filtered by ITS Partner)
5. Department and Division will auto-populate
6. Enter scores (1-10):
   - Service Experience Score: 8
   - Work Product Score: 9
7. Add a comment: "Great collaboration on the new dashboard project"
8. Click "Submit"

### 5. View Your Entry

1. Navigate to "Entries" tab
2. You'll see your entry in the table
3. Try sorting by clicking column headers
4. Hover over comments to see full text

---

## Running Tests

To verify everything works:

```bash
cd synergy_hub
Rscript run_tests.R
```

Expected output:
```
✓ All tests passed successfully!
```

---

## Troubleshooting

### Problem: Packages Won't Install

**Solution**: Try installing one at a time:
```r
install.packages("shiny")
install.packages("shinydashboard")
# etc.
```

### Problem: App Won't Start

**Error**: "cannot open the connection"

**Solution**:
- Check file paths in `app.R`
- Ensure directories exist
- Check file permissions

### Problem: Empty Dropdowns

**Issue**: No ITS Partners or Business Partners shown

**Solution**:
- Add personnel via "Manage ITS Personnel" tab
- Or create the CSV files manually
- Ensure relationships are saved

### Problem: Plots Not Showing

**Issue**: Analysis tab is blank

**Solution**:
- Need at least one entry to show plots
- Add entries via Dashboard tab
- Wait for data to load

---

## Next Steps

Once you're up and running:

1. **Read the Full Documentation**
   - Check `README.md` for detailed features
   - Read `How_To.md` in the app (How-To Guide tab)

2. **Add More Data**
   - Add all your ITS personnel
   - Add all business partners
   - Map all relationships

3. **Start Recording Interactions**
   - Use Dashboard for new entries
   - Review weekly trends
   - Manage unresolved tickets

4. **Explore Features**
   - Try the Analysis tab for trends
   - View the Sankey diagram in Visualization
   - Update entries as needed

---

## Quick Reference

### Key Shortcuts

| Task | Location | Steps |
|------|----------|-------|
| Add Entry | Dashboard | Fill form → Submit |
| View Entries | Entries | Click tab |
| Edit Entry | Update | Click row → Edit → Save |
| Resolve Ticket | Unresolved Tickets | Click row → Resolve → Save |
| Add Personnel | Manage ITS Personnel | Add button → Fill → Save |
| View Trends | Analysis | Click tab |

### File Locations

| File | Purpose |
|------|---------|
| `app.R` | Main application |
| `R/*.R` | Function modules |
| `www/styles.css` | Custom styling |
| `data/*.parquet` | Entry data |
| `data/*.csv` | Personnel & relationships |

---

## Getting Help

- **Built-in Help**: How-To Guide tab in the app
- **Documentation**: `README.md`
- **Tests**: `TEST_VALIDATION.md`
- **Summary**: `PROJECT_SUMMARY.md`

---

## Production Deployment

For production use:

1. **Test Thoroughly**
   - Run all unit tests
   - Manual testing
   - Load testing with real data

2. **Secure Your Data**
   - Set proper file permissions
   - Use secure file paths
   - Regular backups

3. **Deploy to Server**
   - Shiny Server
   - RStudio Connect
   - ShinyApps.io
   - Docker container

See `README.md` and `PROJECT_SUMMARY.md` for deployment details.

---

## Support

Having issues? Check:
1. This Quick Start guide
2. README.md
3. How-To Guide (in app)
4. TEST_VALIDATION.md
5. Contact development team

---

**You're ready to go! Start building better IT business relationships with Synergy Hub.**

🚀 Happy tracking!

---

**Last Updated**: January 20, 2026

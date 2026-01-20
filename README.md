# Taktica v2.0

**Production-Ready Project & Resource Capacity Management Dashboard**

Taktica is a comprehensive R Shiny application designed for data science teams to manage projects, track capacity, optimize resource allocation, and forecast future utilization with AI-powered insights.

---

## Features

### Core Functionality
- **Project Management**: Full CRUD operations with validation and audit logging
- **Team Capacity Tracking**: Real-time utilization monitoring and alerts
- **Advanced Analytics**: Risk scoring, trend analysis, and anomaly detection
- **Predictive Forecasting**: ARIMA-based capacity forecasting
- **AI Assistant**: Natural language queries powered by Ollama
- **Interactive Visualizations**: Gantt charts, heatmaps, trend analysis
- **Resource Optimization**: Automated workload balancing recommendations
- **Comprehensive Reporting**: CSV exports and custom date range reports

### Technical Highlights
- **Modular Architecture**: Separation of concerns (data, logic, UI, visualization)
- **Comprehensive Testing**: Unit tests with 90%+ coverage
- **Production Logging**: Structured logging with configurable levels
- **Configuration Management**: Environment-specific settings via `config.yml`
- **Data Persistence**: Parquet format with automatic backups
- **GPU Support**: Optimized for Posit Connect with GPU-enabled Ollama
- **Audit Trail**: Complete history of all data modifications

---

## Installation

### Prerequisites

- R >= 4.1.0
- Ollama (for AI features, optional)
- Posit Connect (for production deployment, optional)

### Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd taktica
```

2. **Install dependencies**

**Option A: Using renv (recommended)**
```r
install.packages("renv")
renv::restore()
```

**Option B: Manual installation**
```r
install.packages(c(
  "shiny", "shinydashboard", "plotly", "reactable",
  "dplyr", "arrow", "lubridate", "shinyWidgets",
  "httr", "jsonlite", "logger", "config",
  "DT", "forecast", "ggplot2", "tidyr",
  "scales", "glue", "purrr", "tibble"
))

# Dev dependencies
install.packages(c("testthat", "mockery", "covr"))
```

3. **Configure environment**

Copy and customize the configuration:
```bash
cp config/config.yml.example config/config.yml
cp .Renviron.example .Renviron
```

Edit `config/config.yml` for your environment.

4. **Initialize data directory**
```bash
mkdir -p data logs
```

5. **Run the application**
```r
shiny::runApp("app/app_v2.R")
```

Access at: http://localhost:8000

---

## Configuration

### Environment Variables

Create `.Renviron` file:
```bash
R_CONFIG_ACTIVE=development
TAKTICA_LOG_LEVEL=INFO
OLLAMA_API_KEY=""  # Optional
```

### Configuration File

Edit `config/config.yml`:

```yaml
default:
  data_dir: "data"
  ollama:
    url: "http://localhost:11434"
    model: "phi3"
    timeout: 10
  features:
    enable_ai: true
    enable_forecasting: true

production:
  data_dir: "/data/taktica"
  ollama:
    url: "http://ollama-gpu:11434"
    timeout: 30
  features:
    enable_authentication: true
  posit_connect:
    enabled: true
    use_gpu: true
```

---

## Usage

### Quick Start

1. **Dashboard**: View KPIs, insights, and trends
2. **Projects**: Add/edit/delete projects
3. **Timeline**: Visualize project schedules with Gantt chart
4. **Team**: Monitor team capacity and utilization
5. **Analytics**: Analyze risks and optimize allocation
6. **Forecast**: Predict future capacity needs
7. **Reports**: Export data and generate reports

### AI Assistant

Ask natural language questions:
- "What is our current project load?"
- "Who is overallocated this week?"
- "Which projects are at risk?"
- "What's our team utilization?"

### Adding Projects

1. Navigate to **Projects** tab
2. Click **Add New Project**
3. Fill in required fields:
   - Project Name
   - Owner (select from team)
   - Timeline (start/end dates)
   - Category (ML, GenAI, Evaluation, etc.)
   - Status
4. Click **Add Project**

### Forecasting

1. Navigate to **Forecast** tab
2. Adjust forecast horizon (1-12 weeks)
3. Click **Run Forecast**
4. View predictions with 80% and 95% confidence intervals

---

## Architecture

### Directory Structure

```
taktica/
├── app/
│   ├── app.R               # Legacy application
│   └── app_v2.R            # Production application
├── R/
│   ├── data_access.R       # Data persistence & validation
│   ├── business_logic.R    # KPIs, analytics, forecasting
│   ├── ollama_integration.R # AI assistant
│   ├── visualizations.R    # Charts and graphs
│   └── ui_components.R     # Reusable UI elements
├── tests/
│   └── testthat/           # Unit tests
├── config/
│   └── config.yml          # Configuration
├── data/                   # Data storage (parquet files)
├── logs/                   # Application logs
├── docs/                   # Documentation
├── DESCRIPTION             # Package metadata
└── README.md               # This file
```

### Data Flow

```
User Input → Validation → Business Logic → Data Access → Storage (Parquet)
                                         ↓
                              Visualizations ← Analytics ← AI Assistant
```

### Testing

Run tests:
```r
testthat::test_dir("tests/testthat")
```

Check coverage:
```r
covr::package_coverage()
```

---

## Deployment

### Local Development

```r
shiny::runApp("app/app_v2.R", port = 8000)
```

### Posit Connect

See [docs/deployment_guide.md](docs/deployment_guide.md) for detailed instructions.

Quick deploy:
```r
rsconnect::deployApp(
  appDir = ".",
  appFiles = c("app/app_v2.R", "R/", "config/", "DESCRIPTION"),
  appName = "taktica",
  appTitle = "Taktica - Capacity Management"
)
```

### Docker (Optional)

```bash
docker build -t taktica:latest .
docker run -p 8000:8000 -v $(pwd)/data:/data taktica:latest
```

---

## Ollama Setup

### Installation

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull model
ollama pull phi3
```

### GPU Support

For Posit Connect with GPU:

1. Ensure CUDA drivers are installed
2. Configure Ollama with GPU:
```yaml
posit_connect:
  use_gpu: true
  ollama:
    url: "http://ollama-gpu:11434"
```

### Testing Ollama

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "phi3",
  "prompt": "Hello",
  "stream": false
}'
```

---

## API Reference

### Data Access Functions

- `load_projects()`: Load projects from storage
- `save_projects(projects)`: Save projects to storage
- `add_project(project, team_members, user)`: Add new project
- `update_project(old_name, project, team_members, user)`: Update project
- `delete_project(project_name, user)`: Delete project
- `validate_project(project, team_members)`: Validate project data

### Business Logic Functions

- `calculate_utilization(allocations, team_members, week)`: Calculate utilization
- `calculate_project_risk(projects, allocations, team_members)`: Risk scoring
- `forecast_utilization(allocations, team_members, weeks_ahead)`: Forecast capacity
- `optimize_allocation(allocations, team_members, projects)`: Optimization recommendations
- `generate_insights(projects, allocations, team_members)`: Automated insights

### AI Functions

- `handle_query(query, projects, allocations, team_members)`: Main query handler
- `query_ollama(query, projects, allocations, team_members)`: Ollama API call
- `build_data_context(projects, allocations, team_members)`: Create context string

### Visualization Functions

- `create_gantt_chart(projects)`: Project timeline
- `create_utilization_heatmap(allocations, team_members)`: Utilization heatmap
- `create_forecast_chart(historical, forecast)`: Forecast visualization
- `create_risk_dashboard(projects, allocations, team_members)`: Risk analysis chart

---

## Troubleshooting

### Common Issues

**1. Ollama Connection Errors**
```
Solution: Ensure Ollama is running: `systemctl status ollama`
Check URL in config.yml matches Ollama endpoint
```

**2. Data Not Persisting**
```
Solution: Check write permissions on data/ directory
Verify parquet files are being created: ls -la data/
```

**3. Forecast Fails**
```
Solution: Need at least 4 weeks of historical data
Check allocations data is populated correctly
```

**4. High Memory Usage**
```
Solution: Reduce forecast horizon
Limit historical data loaded
Consider data aggregation
```

### Logging

View logs:
```bash
tail -f logs/taktica.log
```

Adjust log level in `config/config.yml`:
```yaml
logging:
  level: "DEBUG"  # Options: DEBUG, INFO, WARN, ERROR
```

---

## Development

### Adding New Features

1. Create function in appropriate R/ module
2. Write unit tests in tests/testthat/
3. Update documentation
4. Test locally
5. Submit pull request

### Code Style

- Follow tidyverse style guide
- Use roxygen2 for documentation
- Maximum line length: 100 characters
- Use explicit namespacing (package::function)

### Running Tests

```r
# All tests
testthat::test_dir("tests/testthat")

# Specific test file
testthat::test_file("tests/testthat/test-data_access.R")

# With coverage
covr::package_coverage()
```

---

## Performance

### Optimization Tips

1. **Data Loading**: Use `arrow::read_parquet()` for fast I/O
2. **Caching**: Leverage Shiny's reactive caching
3. **GPU**: Enable GPU for Ollama on Posit Connect
4. **Forecasting**: Limit forecast horizon to 4-8 weeks
5. **Visualizations**: Use `plotly` for interactive, efficient charts

### Benchmarks

- Load time: < 2 seconds
- Query response: < 500ms (direct), < 3s (AI)
- Forecast generation: < 5 seconds
- Visualization rendering: < 1 second

---

## Security

### Best Practices

1. **Authentication**: Enable in production (`enable_authentication: true`)
2. **Data Validation**: All inputs are validated before processing
3. **Audit Logging**: All modifications are logged
4. **Input Sanitization**: Protection against injection attacks
5. **HTTPS**: Use TLS in production (Posit Connect handles this)

### Data Privacy

- No external data transmission (except optional Ollama)
- All data stored locally in parquet format
- Audit logs track all data access
- Team member emails visible only to authenticated users

---

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Write tests for new features
4. Ensure all tests pass
5. Submit a pull request

---

## License

MIT License - See LICENSE file for details

---

## Support

- **Issues**: GitHub Issues
- **Documentation**: See docs/ directory
- **Questions**: Create a discussion on GitHub

---

## Roadmap

### Version 2.1 (Planned)
- [ ] Multi-tenancy support
- [ ] Real-time collaboration features
- [ ] Mobile-responsive design
- [ ] Slack/Teams integration
- [ ] Custom dashboard builder

### Version 2.2 (Planned)
- [ ] Machine learning project recommendations
- [ ] Advanced resource optimization algorithms
- [ ] Integration with JIRA/Asana
- [ ] Role-based access control
- [ ] Dark mode

---

## Acknowledgments

- Shiny framework by Posit
- Ollama for local AI inference
- Apache Arrow for efficient data storage
- R community for excellent packages

---

**Version**: 2.0.0
**Last Updated**: 2024-01-20
**Author**: Taktica Team

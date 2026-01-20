# Synergy Hub - Deployment Checklist

Use this checklist to ensure a smooth deployment of Synergy Hub.

---

## Pre-Deployment Checklist

### 1. Environment Setup

- [ ] R version 4.0+ installed
- [ ] All required packages installed (`Rscript install_packages.R`)
- [ ] File paths configured in `app.R` (lines 20-23)
- [ ] Data directory created and accessible
- [ ] Write permissions verified for data directory

### 2. Testing

- [ ] All unit tests pass (`Rscript run_tests.R`)
- [ ] Manual testing completed
  - [ ] Data entry workflow
  - [ ] Update operations
  - [ ] Personnel management
  - [ ] Relationship management
  - [ ] Visualization rendering
  - [ ] File persistence

- [ ] Cross-browser testing
  - [ ] Chrome
  - [ ] Firefox
  - [ ] Safari
  - [ ] Edge

- [ ] Responsive design testing
  - [ ] Desktop (1200px+)
  - [ ] Tablet (768px-1199px)
  - [ ] Mobile (<768px)

### 3. Data Preparation

- [ ] Initial ITS personnel list ready
- [ ] Initial business partners list ready
- [ ] Relationships mapped
- [ ] Sample data files created (optional)
- [ ] Data migration plan (if applicable)

### 4. Documentation

- [ ] README.md reviewed
- [ ] QUICK_START.md reviewed
- [ ] How-To guide accessible in app
- [ ] User training materials prepared
- [ ] Admin documentation prepared

### 5. Security

- [ ] File permissions set correctly
- [ ] Sensitive data paths secured
- [ ] No hardcoded credentials
- [ ] Access control configured (if applicable)
- [ ] Backup strategy defined

---

## Deployment Steps

### Option 1: Local Development Server

1. **Install Packages**
   ```bash
   Rscript install_packages.R
   ```

2. **Configure Paths**
   Edit `app.R` lines 20-23

3. **Run Application**
   ```r
   shiny::runApp('app.R')
   ```

4. **Access Application**
   Open browser to `http://localhost:port`

### Option 2: RStudio Server

1. **Copy Files**
   ```bash
   scp -r synergy_hub user@server:/path/to/apps/
   ```

2. **Install Packages on Server**
   ```bash
   ssh user@server
   cd /path/to/apps/synergy_hub
   Rscript install_packages.R
   ```

3. **Configure Paths**
   Edit `app.R` for server file paths

4. **Run Application**
   ```r
   shiny::runApp('app.R', host='0.0.0.0', port=3838)
   ```

5. **Access Application**
   Open browser to `http://server-ip:3838`

### Option 3: Shiny Server

1. **Install Shiny Server**
   Follow official Shiny Server installation guide

2. **Copy Application**
   ```bash
   sudo cp -r synergy_hub /srv/shiny-server/
   ```

3. **Install Packages Globally**
   ```bash
   sudo su - -c "R -e \"install.packages(c('shiny', 'shinydashboard', 'readr', 'dplyr', 'DT', 'lubridate', 'ggplot2', 'arrow', 'plotly'))\""
   ```

4. **Set Permissions**
   ```bash
   sudo chown -R shiny:shiny /srv/shiny-server/synergy_hub
   sudo chmod -R 755 /srv/shiny-server/synergy_hub
   ```

5. **Configure Data Directory**
   ```bash
   sudo mkdir -p /mnt/data_science/ShinyAppsData/BRM
   sudo chown -R shiny:shiny /mnt/data_science/ShinyAppsData/BRM
   ```

6. **Restart Shiny Server**
   ```bash
   sudo systemctl restart shiny-server
   ```

7. **Access Application**
   Open browser to `http://server-ip:3838/synergy_hub/`

### Option 4: Docker

1. **Create Dockerfile**
   ```dockerfile
   FROM rocker/shiny:latest

   # Install system dependencies
   RUN apt-get update && apt-get install -y \
       libcurl4-gnutls-dev \
       libssl-dev \
       libxml2-dev

   # Install R packages
   RUN R -e "install.packages(c('shinydashboard', 'readr', 'dplyr', 'DT', 'lubridate', 'ggplot2', 'arrow', 'plotly'))"

   # Copy application
   COPY synergy_hub /srv/shiny-server/synergy_hub

   # Set permissions
   RUN chown -R shiny:shiny /srv/shiny-server/synergy_hub

   # Expose port
   EXPOSE 3838

   # Run
   CMD ["/usr/bin/shiny-server"]
   ```

2. **Build Image**
   ```bash
   docker build -t synergy-hub:latest .
   ```

3. **Run Container**
   ```bash
   docker run -d -p 3838:3838 \
     -v /path/to/data:/mnt/data_science/ShinyAppsData/BRM \
     --name synergy-hub \
     synergy-hub:latest
   ```

4. **Access Application**
   Open browser to `http://localhost:3838/synergy_hub/`

### Option 5: ShinyApps.io

1. **Install rsconnect**
   ```r
   install.packages('rsconnect')
   ```

2. **Configure Account**
   ```r
   library(rsconnect)
   rsconnect::setAccountInfo(
     name='your-account',
     token='your-token',
     secret='your-secret'
   )
   ```

3. **Deploy Application**
   ```r
   rsconnect::deployApp('synergy_hub')
   ```

4. **Access Application**
   URL provided by ShinyApps.io

---

## Post-Deployment Checklist

### 1. Verification

- [ ] Application loads without errors
- [ ] All tabs accessible
- [ ] Data entry works
- [ ] Data persists correctly
- [ ] Visualizations render
- [ ] File operations work

### 2. User Setup

- [ ] Add initial ITS personnel
- [ ] Add initial business partners
- [ ] Create relationships
- [ ] Add test entries
- [ ] Verify workflows

### 3. Training

- [ ] Admin training completed
- [ ] User training scheduled
- [ ] Documentation distributed
- [ ] Support channels established

### 4. Monitoring

- [ ] Set up logging
- [ ] Configure monitoring
- [ ] Establish backup schedule
- [ ] Define maintenance windows
- [ ] Create incident response plan

### 5. Documentation

- [ ] Deployment notes documented
- [ ] Configuration documented
- [ ] Known issues documented
- [ ] Troubleshooting guide updated
- [ ] Admin contacts listed

---

## Rollback Plan

If deployment fails:

1. **Stop Application**
   ```bash
   # For Shiny Server
   sudo systemctl stop shiny-server

   # For Docker
   docker stop synergy-hub
   ```

2. **Restore Previous Version**
   ```bash
   sudo cp -r /backup/synergy_hub /srv/shiny-server/
   ```

3. **Restart Service**
   ```bash
   sudo systemctl start shiny-server
   ```

4. **Verify Rollback**
   - Check application loads
   - Verify data integrity
   - Test core functionality

---

## Maintenance Schedule

### Daily

- [ ] Check application logs
- [ ] Monitor disk space
- [ ] Verify data backups

### Weekly

- [ ] Review user feedback
- [ ] Check for errors
- [ ] Review unresolved tickets
- [ ] Backup data files

### Monthly

- [ ] Update R packages
- [ ] Review performance metrics
- [ ] Update documentation
- [ ] User satisfaction survey

### Quarterly

- [ ] Security audit
- [ ] Performance optimization
- [ ] Feature review
- [ ] Disaster recovery test

---

## Troubleshooting

### Application Won't Start

**Check:**
- R is installed and accessible
- All packages are installed
- File paths are correct
- Permissions are set correctly

**Solution:**
```bash
# Check R version
R --version

# Test package loading
R -e "library(shiny)"

# Check file permissions
ls -la /srv/shiny-server/synergy_hub
```

### Data Not Persisting

**Check:**
- Write permissions on data directory
- Disk space available
- File paths are correct

**Solution:**
```bash
# Check disk space
df -h

# Check permissions
ls -la /mnt/data_science/ShinyAppsData/BRM

# Set permissions
sudo chown -R shiny:shiny /mnt/data_science/ShinyAppsData/BRM
```

### Performance Issues

**Check:**
- Number of concurrent users
- Size of data files
- Server resources

**Solution:**
- Increase server resources
- Optimize data queries
- Implement caching
- Add pagination

---

## Support Contacts

| Role | Contact | Purpose |
|------|---------|---------|
| System Admin | [contact] | Server issues |
| App Admin | [contact] | User management |
| Developer | [contact] | Bug fixes, features |
| Help Desk | [contact] | User support |

---

## Success Criteria

Deployment is successful when:

- [x] Application is accessible
- [x] All features work correctly
- [x] Data persists properly
- [x] Users can log in (if auth enabled)
- [x] Performance is acceptable
- [x] Backups are working
- [x] Documentation is available
- [x] Support is in place

---

## Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Developer | | | |
| System Admin | | | |
| Project Manager | | | |
| Business Owner | | | |

---

**Deployment Date**: _______________

**Version**: 1.0.0

**Environment**: _______________

**Notes**:

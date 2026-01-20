# Taktica Deployment Guide

Complete guide for deploying Taktica to Posit Connect with GPU-enabled Ollama support.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Posit Connect Setup](#posit-connect-setup)
3. [Ollama Configuration](#ollama-configuration)
4. [Application Deployment](#application-deployment)
5. [GPU Configuration](#gpu-configuration)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Server Requirements

- **OS**: Ubuntu 20.04+ / RHEL 8+ / Debian 11+
- **RAM**: Minimum 8GB, recommended 16GB+
- **CPU**: 4+ cores recommended
- **GPU**: NVIDIA GPU with CUDA support (optional, for AI features)
- **Storage**: 50GB+ available space
- **Network**: Internet access for package installation

### Software Requirements

- Posit Connect 2023.05.0+
- R 4.1.0+
- Ollama (for AI features)
- NVIDIA drivers + CUDA toolkit (for GPU support)

### Access Requirements

- Posit Connect administrator access
- SSH access to server
- sudo privileges (for initial setup)

---

## Posit Connect Setup

### 1. Install Posit Connect

```bash
# Add Posit repository
curl -O https://cdn.posit.co/connect/setup/scripts/install-connect.sh
sudo bash install-connect.sh

# Start service
sudo systemctl enable rstudio-connect
sudo systemctl start rstudio-connect
```

### 2. Configure Posit Connect

Edit `/etc/rstudio-connect/rstudio-connect.gcfg`:

```ini
[Server]
Address = https://connect.yourcompany.com
DataDir = /var/lib/rstudio-connect

[HTTP]
Listen = :3939

[Authentication]
Provider = ldap  # or oauth2, saml, pam

[Applications]
RunAsCurrentUser = true

[Python]
Enabled = false

[R]
Enabled = true
```

Restart:
```bash
sudo systemctl restart rstudio-connect
```

### 3. Install R Packages System-Wide

```bash
sudo su - -c "R -e \"install.packages(c('shiny', 'shinydashboard', 'plotly', 'reactable', 'dplyr', 'arrow', 'lubridate', 'shinyWidgets', 'httr', 'jsonlite', 'logger', 'config', 'DT', 'forecast', 'ggplot2', 'tidyr', 'scales', 'glue', 'purrr', 'tibble'), repos='https://cran.rstudio.com/')\""
```

---

## Ollama Configuration

### 1. Install Ollama on Server

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Enable as service
sudo systemctl enable ollama
sudo systemctl start ollama

# Verify installation
ollama --version
```

### 2. Pull AI Models

```bash
# Standard model (4GB)
ollama pull phi3

# Or larger model for better accuracy (7GB)
ollama pull mistral

# Verify
ollama list
```

### 3. Configure Ollama Service

Create `/etc/systemd/system/ollama.service.d/override.conf`:

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=http://connect.yourcompany.com"
Environment="OLLAMA_NUM_PARALLEL=4"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
```

With GPU:
```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=http://connect.yourcompany.com"
Environment="CUDA_VISIBLE_DEVICES=0"
Environment="OLLAMA_NUM_GPU=1"
```

Restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### 4. Test Ollama

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "phi3",
  "prompt": "Say hello",
  "stream": false
}'
```

---

## Application Deployment

### Method 1: Using rsconnect Package (Recommended)

#### Step 1: Prepare Application

On your local machine:

```r
# Install rsconnect
install.packages("rsconnect")

# Configure Connect server
rsconnect::addServer(
  url = "https://connect.yourcompany.com",
  name = "company-connect"
)

# Authenticate
rsconnect::connectApiUser(
  account = "your-username",
  server = "company-connect",
  apiKey = "YOUR_API_KEY"
)
```

#### Step 2: Configure for Production

Edit `config/config.yml`:

```yaml
production:
  app_name: "Taktica"
  data_dir: "/data/taktica"
  logging:
    level: "WARN"
    file: "/var/log/taktica/app.log"
  ollama:
    url: "http://localhost:11434"  # Same server
    model: "phi3"
    timeout: 30
  features:
    enable_ai: true
    enable_forecasting: true
    enable_authentication: true
  posit_connect:
    enabled: true
    use_gpu: true
```

#### Step 3: Deploy

```r
# Set environment for production
Sys.setenv(R_CONFIG_ACTIVE = "production")

# Deploy application
rsconnect::deployApp(
  appDir = ".",
  appFiles = c(
    "app/app_v2.R",
    "R/",
    "config/config.yml",
    ".Renviron",
    "DESCRIPTION",
    "data/projects.parquet",
    "data/team_members.parquet",
    "data/allocations.parquet"
  ),
  appName = "taktica",
  appTitle = "Taktica - Capacity Management",
  server = "company-connect",
  account = "your-username",
  launch.browser = FALSE,
  forceUpdate = TRUE
)
```

### Method 2: Git-backed Deployment

#### Step 1: Create Git Repository

```bash
git init
git add .
git commit -m "Initial Taktica deployment"
git remote add origin https://github.com/yourorg/taktica.git
git push -u origin main
```

#### Step 2: Configure in Posit Connect UI

1. Log into Posit Connect
2. Click **Publish** → **Import from Git**
3. Enter repository URL
4. Select branch: `main`
5. Specify primary file: `app/app_v2.R`
6. Set environment variables:
   ```
   R_CONFIG_ACTIVE=production
   TAKTICA_LOG_LEVEL=WARN
   ```

7. Configure runtime settings:
   - Min processes: 1
   - Max processes: 3
   - Max connections: 50
   - Idle timeout: 120 seconds

8. Click **Deploy**

### Method 3: Manual Upload

1. Create deployment bundle:
```bash
tar -czf taktica-deployment.tar.gz app/ R/ config/ data/ DESCRIPTION .Renviron
```

2. Upload via Posit Connect UI:
   - Content → New Content → Upload Archive
   - Select `taktica-deployment.tar.gz`
   - Configure settings as in Method 2

---

## GPU Configuration

### 1. Verify GPU Availability

```bash
# Check NVIDIA driver
nvidia-smi

# Check CUDA
nvcc --version

# Test with Ollama
ollama run phi3 --gpu "Why is the sky blue?"
```

### 2. Configure Posit Connect for GPU

Edit `/etc/rstudio-connect/rstudio-connect.gcfg`:

```ini
[Applications]
AllowGPUAccess = true

[GPUs]
Enabled = true
DeviceIds = 0  # GPU device ID
```

Restart:
```bash
sudo systemctl restart rstudio-connect
```

### 3. Configure Application for GPU

In Posit Connect UI for your app:
1. Settings → Runtime
2. Enable "Allow GPU Access"
3. Set environment variable:
   ```
   CUDA_VISIBLE_DEVICES=0
   ```

### 4. Verify GPU Usage

Monitor GPU utilization:
```bash
watch -n 1 nvidia-smi
```

Check Ollama logs:
```bash
journalctl -u ollama -f
```

---

## Post-Deployment Configuration

### 1. Set Up Data Directory

```bash
# Create persistent data directory
sudo mkdir -p /data/taktica
sudo chown rstudio-connect:rstudio-connect /data/taktica
sudo chmod 755 /data/taktica

# Create log directory
sudo mkdir -p /var/log/taktica
sudo chown rstudio-connect:rstudio-connect /var/log/taktica
```

### 2. Configure Backups

Create backup script `/usr/local/bin/backup-taktica.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/backups/taktica"
DATA_DIR="/data/taktica"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/taktica_data_$DATE.tar.gz $DATA_DIR
find $BACKUP_DIR -name "taktica_data_*.tar.gz" -mtime +30 -delete
```

Add to crontab:
```bash
sudo crontab -e
# Add: Daily backup at 2 AM
0 2 * * * /usr/local/bin/backup-taktica.sh
```

### 3. Configure Access Control

In Posit Connect UI:
1. Navigate to your app → **Access**
2. Set access level:
   - **All users** (anyone logged in)
   - **Specific users/groups** (recommended)
   - **Public** (not recommended)
3. Add users/groups

### 4. Set Up Vanity URL

In Posit Connect UI:
1. Settings → General
2. Set custom URL: `/taktica` or `/capacity`

---

## Monitoring & Maintenance

### 1. Application Monitoring

#### Posit Connect Metrics

Access metrics at: `https://connect.yourcompany.com/__metrics__`

Key metrics to monitor:
- Request count
- Response time (p50, p95, p99)
- Error rate
- Memory usage
- CPU usage

#### Custom Logging

Application logs location: `/var/log/taktica/app.log`

Monitor logs:
```bash
tail -f /var/log/taktica/app.log
```

Set up log rotation in `/etc/logrotate.d/taktica`:
```
/var/log/taktica/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 rstudio-connect rstudio-connect
}
```

### 2. Ollama Monitoring

```bash
# Service status
systemctl status ollama

# Resource usage
journalctl -u ollama --since "1 hour ago"

# API health check
curl http://localhost:11434/api/health
```

### 3. Alerting

Configure alerts in Posit Connect:
1. Settings → Notifications
2. Set up email alerts for:
   - Application errors
   - High CPU/memory usage
   - Process crashes

---

## Troubleshooting

### Issue: Ollama Connection Refused

**Symptoms**: AI queries return "[Ollama offline]"

**Solutions**:
```bash
# Check Ollama service
systemctl status ollama

# Test connectivity from Connect
sudo -u rstudio-connect curl http://localhost:11434/api/health

# Check firewall
sudo firewall-cmd --list-all

# Verify URL in config
cat config/config.yml | grep -A 5 ollama
```

### Issue: GPU Not Being Used

**Symptoms**: Queries slow, `nvidia-smi` shows 0% utilization

**Solutions**:
```bash
# Verify GPU access
sudo -u rstudio-connect nvidia-smi

# Check Ollama GPU settings
cat /etc/systemd/system/ollama.service.d/override.conf

# Verify in Connect config
grep -i gpu /etc/rstudio-connect/rstudio-connect.gcfg

# Restart both services
sudo systemctl restart ollama
sudo systemctl restart rstudio-connect
```

### Issue: Application Crashes

**Symptoms**: 502/503 errors, app doesn't load

**Solutions**:
```bash
# Check Connect logs
tail -100 /var/log/rstudio-connect/rstudio-connect.log

# Check app logs
tail -100 /var/log/taktica/app.log

# Check resource limits
ps aux | grep R

# Increase memory limit in Connect UI:
# Settings → Runtime → Max Memory → 4GB
```

### Issue: Slow Performance

**Solutions**:
1. Enable caching:
```r
# In app_v2.R
shiny::renderCachedPlot(...)
```

2. Increase processes:
   - Connect UI → Settings → Runtime
   - Max processes: 3-5

3. Optimize queries:
   - Reduce forecast horizon
   - Limit historical data loaded

4. Enable GPU for Ollama (see GPU Configuration)

### Issue: Data Not Persisting

**Symptoms**: Changes lost after restart

**Solutions**:
```bash
# Check write permissions
sudo -u rstudio-connect touch /data/taktica/test.txt

# Verify data directory in config
grep data_dir config/config.yml

# Check disk space
df -h /data/taktica
```

---

## Security Hardening

### 1. Enable HTTPS

Posit Connect handles TLS automatically. Ensure certificate is valid:
```bash
sudo openssl x509 -in /etc/rstudio-connect/cert.pem -text -noout
```

### 2. Restrict Ollama Access

Edit `/etc/systemd/system/ollama.service.d/override.conf`:
```ini
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"  # Localhost only
Environment="OLLAMA_ORIGINS=http://127.0.0.1"
```

### 3. Enable Audit Logging

Already implemented in application. View audit log:
```bash
cat /data/taktica/audit_log.parquet
```

### 4. Regular Updates

```bash
# Update Posit Connect
sudo apt update && sudo apt upgrade rstudio-connect

# Update R packages
sudo su - -c "R -e \"update.packages(ask=FALSE, checkBuilt=TRUE)\""

# Update Ollama
curl -fsSL https://ollama.ai/install.sh | sh
```

---

## Performance Tuning

### Recommended Settings for Production

**Posit Connect** (`/etc/rstudio-connect/rstudio-connect.gcfg`):
```ini
[Applications]
RunAsCurrentUser = true
MaxProcesses = 5
MinProcesses = 1
MaxConnsPerProcess = 20
IdleTimeout = 120

[GPUs]
Enabled = true
MemoryFraction = 0.5  # Use 50% of GPU memory
```

**Ollama** (`/etc/systemd/system/ollama.service.d/override.conf`):
```ini
[Service]
Environment="OLLAMA_NUM_PARALLEL=4"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
Environment="OLLAMA_KEEP_ALIVE=5m"
```

**Application** (`config/config.yml`):
```yaml
production:
  ollama:
    timeout: 30
  features:
    enable_forecasting: true
  cache:
    enabled: true
    ttl: 300  # 5 minutes
```

---

## Scaling Considerations

### Horizontal Scaling

For high traffic:

1. **Load Balancer**: Use NGINX or HAProxy
2. **Multiple Connect Servers**: Deploy to cluster
3. **Shared Data Storage**: NFS or S3
4. **Redis Cache**: For session state

### Vertical Scaling

For single server:

1. Increase RAM: 32GB+
2. More CPU cores: 8+
3. Better GPU: RTX 4090 or A100
4. SSD storage for data directory

---

## Backup & Disaster Recovery

### Automated Backups

```bash
# Full backup script
#!/bin/bash
rsync -avz /data/taktica/ backup-server:/backups/taktica/data/
rsync -avz /var/log/taktica/ backup-server:/backups/taktica/logs/
rsync -avz /etc/rstudio-connect/ backup-server:/backups/taktica/config/
```

### Recovery Procedure

```bash
# Restore data
rsync -avz backup-server:/backups/taktica/data/ /data/taktica/

# Restore config
rsync -avz backup-server:/backups/taktica/config/ /etc/rstudio-connect/

# Restart
sudo systemctl restart rstudio-connect
```

---

## Maintenance Windows

### Planned Downtime

1. Announce in app (add banner)
2. Wait for active sessions to complete
3. Stop application gracefully
4. Perform maintenance
5. Test thoroughly
6. Restart application
7. Monitor for issues

### Zero-Downtime Updates

1. Deploy to staging environment
2. Test thoroughly
3. Use rolling deployment in Connect
4. Monitor metrics
5. Rollback if needed

---

## Contact & Support

- **Posit Connect Docs**: https://docs.posit.co/connect/
- **Ollama Docs**: https://github.com/ollama/ollama/tree/main/docs
- **Taktica Issues**: GitHub repository

---

**Last Updated**: 2024-01-20
**Version**: 2.0.0

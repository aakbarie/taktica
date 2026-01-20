# Synergy Hub - Backup & Data Protection Strategy

## 🛡️ Your Data is Protected

Your Synergy Hub data is now protected with a comprehensive backup system. This guide will show you how to backup, restore, and protect your valuable relationship management data.

---

## 📁 Your Data Location

Your production data is stored at:

```
/winset/BAU/Data Science/ShinyAppsData/BRM/
├── entries.parquet                  (All interaction records)
├── its_personnel.csv                (ITS staff list)
├── business_partners.csv            (Business partners list)
└── brm_assignments.csv              (Relationship mappings)
```

**IMPORTANT**: These paths are now configured in `config.R` - never lose them again!

---

## 🔄 Backup Methods

### Method 1: Manual Backup (Recommended for One-Time Backups)

Run this R script whenever you want to create a backup:

```r
# Load the backup utilities
source("R/backup_utils.R")
source("config.R")

# Create a backup
create_backup(
  entries_file,
  its_personnel_file,
  business_partners_file,
  relationships_file,
  backup_directory
)
```

Or use the command-line script:

```bash
Rscript backup_now.R
```

### Method 2: Scheduled Backups (Recommended for Production)

#### On Linux/Mac (using cron)

Add to your crontab (`crontab -e`):

```bash
# Backup Synergy Hub data daily at 2 AM
0 2 * * * cd /path/to/synergy_hub && Rscript backup_now.R

# Backup weekly on Sundays at 3 AM
0 3 * * 0 cd /path/to/synergy_hub && Rscript backup_now.R
```

#### On Windows (using Task Scheduler)

1. Open Task Scheduler
2. Create Basic Task
3. Name: "Synergy Hub Backup"
4. Trigger: Daily at 2:00 AM
5. Action: Start a program
6. Program: `Rscript.exe`
7. Arguments: `backup_now.R`
8. Start in: `C:\path\to\synergy_hub`

---

## 💾 Backup Storage

### Default Backup Location

Backups are stored at:
```
/winset/BAU/Data Science/ShinyAppsData/BRM/backups/
├── 20260120_140532/   (Timestamp: YYYYMMDD_HHMMSS)
│   ├── entries.parquet
│   ├── its_personnel.csv
│   ├── business_partners.csv
│   ├── brm_assignments.csv
│   └── backup_manifest.txt
├── 20260119_140215/
│   └── ...
└── ...
```

### Backup Retention

- **Default**: 30 days
- Older backups are automatically deleted
- Configurable in `config.R`

### Backup Size

Each backup contains:
- All entries (typically 1-10 MB)
- Personnel lists (< 1 MB)
- Relationship mappings (< 1 MB)
- **Total**: Usually 2-15 MB per backup

---

## 🔙 Restoring from Backup

### Step 1: List Available Backups

```r
source("R/backup_utils.R")
source("config.R")

# See all available backups
backups <- list_backups(backup_directory)
print(backups)
```

### Step 2: Choose a Backup

Look at the output:
```
  Timestamp           Date                 Size_MB  Files  Path
  20260120_140532     2026-01-20 14:05:32  3.45     4      /winset/.../backups/20260120_140532
  20260119_140215     2026-01-19 14:02:15  3.21     4      /winset/.../backups/20260119_140215
```

### Step 3: Restore the Backup

```r
# Choose the backup you want to restore
backup_to_restore <- "/winset/BAU/Data Science/ShinyAppsData/BRM/backups/20260120_140532"
target_directory <- "/winset/BAU/Data Science/ShinyAppsData/BRM"

# ⚠️ WARNING: This will overwrite current data!
restore_backup(backup_to_restore, target_directory)
```

Or use the interactive script:

```bash
Rscript restore_backup.R
```

---

## 🧹 Cleaning Old Backups

### Manual Cleanup

```r
source("R/backup_utils.R")
source("config.R")

# Delete backups older than 30 days
clean_old_backups(backup_directory, retention_days = 30)
```

### Automated Cleanup

Add to `config.R`:
```r
backup_retention_days <- 30  # Adjust as needed
```

The cleanup runs automatically during backup creation.

---

## 🚨 Emergency Recovery Procedures

### Scenario 1: Accidentally Deleted Data

1. **Stop the app immediately**
2. **Don't save anything**
3. Restore from latest backup:
   ```r
   source("R/backup_utils.R")
   backups <- list_backups(backup_directory)
   # Choose the most recent backup
   restore_backup(backups$Path[1], target_directory)
   ```
4. Restart the app
5. Verify data integrity

### Scenario 2: Corrupted Data File

1. Identify which file is corrupted
2. Find the last good backup:
   ```r
   backups <- list_backups(backup_directory)
   print(backups)
   ```
3. Manually copy the good file:
   ```bash
   cp /backups/20260120_140532/entries.parquet /winset/BAU/.../BRM/
   ```
4. Restart the app

### Scenario 3: Complete Data Loss

1. Check backups:
   ```r
   backups <- list_backups(backup_directory)
   ```
2. Restore entire backup directory
3. Verify each file
4. Restart app

---

## 📋 Backup Verification Checklist

Run this monthly:

```r
source("R/backup_utils.R")
source("config.R")

# 1. List all backups
backups <- list_backups(backup_directory)
print(backups)

# 2. Check data size
current_size <- get_data_size(
  entries_file,
  its_personnel_file,
  business_partners_file,
  relationships_file
)
cat("Current data size:", round(current_size, 2), "MB\n")

# 3. Verify latest backup
if (nrow(backups) > 0) {
  latest <- backups[1, ]
  cat("\nLatest backup:\n")
  cat("  Date:", latest$Date, "\n")
  cat("  Size:", latest$Size_MB, "MB\n")
  cat("  Files:", latest$Files, "\n")
} else {
  warning("⚠️ NO BACKUPS FOUND! Create a backup now!")
}
```

**Expected Output:**
```
Current data size: 3.45 MB

Latest backup:
  Date: 2026-01-20 14:05:32
  Size: 3.45 MB
  Files: 4

✓ Backups are up to date
```

---

## 🎯 Best Practices

### DO ✅

- **Backup before major changes** (adding many users, bulk updates)
- **Backup weekly** at minimum
- **Test restores quarterly** to ensure backups work
- **Keep backups for 30+ days** for historical recovery
- **Monitor backup sizes** for unusual changes
- **Document any manual changes** to data files

### DON'T ❌

- **Don't rely on a single backup** - keep multiple
- **Don't delete backups manually** - use the cleanup function
- **Don't edit production data files directly** - use the app
- **Don't skip backups** before upgrades or deployments
- **Don't ignore backup failures** - investigate immediately

---

## 🔐 Backup Security

### File Permissions

Ensure backup directory has restricted access:

```bash
chmod 750 /winset/BAU/Data\ Science/ShinyAppsData/BRM/backups
chown youruser:yourgroup /winset/BAU/Data\ Science/ShinyAppsData/BRM/backups
```

### Off-Site Backups (Recommended)

For critical data, consider:

1. **Cloud Storage**:
   ```bash
   # Sync backups to cloud (example with rclone)
   rclone sync /winset/BAU/.../BRM/backups remote:synergy-backups
   ```

2. **Network Drive**:
   ```bash
   # Copy to network location
   cp -r /winset/BAU/.../BRM/backups /network/backups/synergy_hub/
   ```

3. **External Drive**:
   - Weekly manual copy to USB drive
   - Store off-site for disaster recovery

---

## 📊 Monitoring & Alerts

### Check Backup Health

Create a monitoring script (`check_backups.R`):

```r
source("R/backup_utils.R")
source("config.R")

backups <- list_backups(backup_directory)

# Alert if no recent backup
if (nrow(backups) == 0) {
  warning("❌ NO BACKUPS FOUND!")
  quit(status = 1)
}

latest <- backups[1, ]
latest_date <- as.POSIXct(latest$Date)
age_hours <- as.numeric(difftime(Sys.time(), latest_date, units = "hours"))

if (age_hours > 48) {
  warning("⚠️ Latest backup is ", round(age_hours), " hours old!")
  quit(status = 1)
}

message("✓ Backup health check passed")
message("  Latest backup:", latest$Date)
message("  Age:", round(age_hours, 1), "hours")
```

Run via cron to alert if backups are stale.

---

## 🛠️ Troubleshooting

### Problem: Backup fails with "Permission denied"

**Solution**:
```bash
# Check permissions
ls -la /winset/BAU/Data\ Science/ShinyAppsData/BRM/

# Fix permissions
chmod 755 /winset/BAU/Data\ Science/ShinyAppsData/BRM/
```

### Problem: Backup directory not created

**Solution**:
```r
# Manually create directory
dir.create("/winset/BAU/Data Science/ShinyAppsData/BRM/backups",
           recursive = TRUE)
```

### Problem: Restore doesn't work

**Solution**:
```r
# Verify backup contents
list.files("/path/to/backup/20260120_140532")

# Check file integrity
file.info("/path/to/backup/20260120_140532/entries.parquet")
```

### Problem: Out of disk space

**Solution**:
```r
# Clean old backups
clean_old_backups(backup_directory, retention_days = 7)

# Check space
system("df -h /winset/BAU/")
```

---

## 📞 Quick Reference

### Create Backup Now
```bash
Rscript backup_now.R
```

### List Backups
```r
source("R/backup_utils.R")
source("config.R")
list_backups(backup_directory)
```

### Restore Backup
```r
restore_backup("/path/to/backup/timestamp", "/path/to/data/directory")
```

### Clean Old Backups
```r
clean_old_backups(backup_directory, 30)
```

### Check Data Size
```r
get_data_size(entries_file, its_personnel_file,
              business_partners_file, relationships_file)
```

---

## ✅ Setup Checklist

Before going to production, complete this checklist:

- [ ] `config.R` created with correct file paths
- [ ] `app.R` updated to source `config.R`
- [ ] Backup directory exists and is writable
- [ ] First manual backup completed successfully
- [ ] Backup verified by listing backups
- [ ] Test restore performed successfully
- [ ] Scheduled backup configured (cron/Task Scheduler)
- [ ] Backup monitoring script set up
- [ ] Off-site backup strategy decided
- [ ] Team trained on restore procedures
- [ ] Emergency contact list created

---

## 📝 Backup Log Template

Keep a record of backups and restores:

```
Date: 2026-01-20
Action: Manual Backup
Reason: Before major update
Result: Success
Backup Location: /backups/20260120_140532
Size: 3.45 MB
Notes: All files backed up successfully

Date: 2026-01-21
Action: Restore
Reason: Accidental deletion
Restored From: /backups/20260120_140532
Result: Success
Notes: Data verified, app restarted
```

---

## 🎉 Summary

Your Synergy Hub data is now protected with:

- ✅ **Configuration file** (`config.R`) - paths never lost
- ✅ **Backup utilities** - easy backup/restore
- ✅ **Automated backups** - set and forget
- ✅ **Retention policy** - automatic cleanup
- ✅ **Emergency procedures** - quick recovery
- ✅ **Monitoring tools** - stay informed

**Your data is safe!** 🛡️

---

**Last Updated**: January 20, 2026
**Version**: 1.1.0
**Status**: Production Ready

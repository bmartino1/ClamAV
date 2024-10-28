#!/bin/ash
# Dockers run Alpine Linux ash instead of bash...

# autoscan.sh - Script to update ClamAV and then scan a specified folder using clamdscan

# Update ClamAV definitions
echo "Updating ClamAV..."
freshclam || { echo "Failed to update ClamAV"; exit 1; }

# Review ClamAV scan command line options settings:
# https://docs.clamav.net/manual/Usage/Scanning.html
# https://linux.die.net/man/1/clamdscan

# This assumes Docker Compose /mnt/user is set to Docker path /scan

# Define folders to scan (including only the desired Docker folders)
SCAN_FOLDERS="/scan/"
# Example of multiple folders: 
# SCAN_FOLDERS="/scan/%foldername% /scan/FolderName"

# Define folders to exclude from scan (as a regex pattern for clamdscan)
EXCLUDE_DIRS="/scan/system"
# Example of multiple folders: 
# EXCLUDE_DIRS="/scan/%foldername%|/scan/FolderName"

# Clear previous scan summary
> /var/log/clamav/scan_summary.txt  # Make sure the infected file log is in the correct directory

# Perform scan only on specified folders and exclude undesired directories
echo "Starting ClamAV scan on specified folders..."
for folder in $SCAN_FOLDERS; do
    clamdscan "$folder" --recursive --infected --exclude-dir="$EXCLUDE_DIRS" \
        --log=/var/log/clamav/log.log --multiscan
    if grep -q FOUND /var/log/clamav/log.log; then
        echo "Infected file found in $folder. See scan_summary.txt for details."
        grep FOUND /var/log/clamav/log.log >> /var/log/clamav/scan_summary.txt
    fi
done

# Display infected files at the end of the scan
echo "Displaying infected files:"
cat /var/log/clamav/scan_summary.txt

# Run script to log display infected files
cd /var/log/clamav
./find_infected_Files_from_log.sh

# Allow time for script above to review before exiting
sleep 10
exit 0

#!/bin/ash
# autoscan.sh - Script to update ClamAV and scan specified folders

# old saved working of clamscan scan all of /mnt/user...
# echo update clamAV
# freshclam
# echo ClamAV Scaning for infected files "/scan" look at log...
#> /var/log/clamav/log.log  # Clear the log AV is using before scan
#> /var/log/clamav/scan_summary.txt  # Make sure the infected file log is clear for the next scan
#Note It runs but doen't display what its is scanning in docker log window...
# clamscan --recursive /scan -i --log=/var/log/clamav/log.log | grep FOUND >> /var/log/clamav/scan_summary.txt
# sleep 5
# cat /var/log/clamav/scan_summary.txt
# exit 0

# Update ClamAV definitions
echo "Updating ClamAV..."
freshclam || { echo "Failed to update ClamAV"; exit 1; }

# Set up directory for clamd socket
echo "Setting up clamd socket directory..."
mkdir -p /var/run/clamav
chown nobody:users /var/run/clamav
chmod 777 /var/run/clamav

# Ensure clamd daemon is running
if ! pgrep clamd > /dev/null; then
    echo "Starting clamd daemon..."
    clamd &
    sleep 30  # Give enough time for clamd to start and create the socket
fi

# Wait for the clamd socket to be available
SOCKET="/var/run/clamav/clamd.sock"
MAX_RETRIES=18  # Wait up to 3 minutes (18 * 10 seconds) each retry is 10 seconds...
RETRIES=0

while [ ! -S "$SOCKET" ]; do
    if [ $RETRIES -ge $MAX_RETRIES ]; then
        echo "Error: clamd socket not found after waiting. Exiting..."
        exit 1
    fi
    echo "Waiting for clamd socket to be created..."
    sleep 10
    RETRIES=$((RETRIES + 1))
done

# Check if clamd is ready to accept connections
echo "Checking if clamd is ready to accept connections..."
READY_RETRIES=0
MAX_READY_RETRIES=18  # Wait up to 3 minutes (18 * 10 seconds)
while ! clamdscan --version > /dev/null 2>&1; do
    if [ $READY_RETRIES -ge $MAX_READY_RETRIES ]; then
        echo "Error: clamd is not ready after waiting. Exiting..."
        exit 1
    fi
    logger -t clamav-scan "Waiting for clamd to be ready..."
    sleep 10
    READY_RETRIES=$((READY_RETRIES + 1))
done

# Define multiple folders to scan
SCAN_FOLDERS="/scan/Cloud /scan/DLNA /scan/Users /scan/Dockers/Plex /scan/Dockers/PhotoPrism"

#EXCLUDE_DIRS="/scan/system"
#Clamdscan uses /etc/clamd for exclude folder...

# Clear previous scan summary and logs
> /var/log/clamav/log.log  # Clear the log AV is using before scan
> /var/log/clamav/scan_summary.txt  # Make sure the infected file log is clear for the next scan

# Perform ClamDscan only on specified folders
# You could try using the --stdout flag with clamdscan to force it to print more detailed logs directly to standard output, which might make its behavior more similar to clamscan.
echo "Starting ClamAV Scan on Specified Folders..."
for folder in $SCAN_FOLDERS; do
#    clamscan --recursive "$folder" -i --log=/var/log/clamav/log.log --verbose --exclude-dir="$EXCLUDE_DIRS" #Working Clamscan for optinal use... clamdscan better perfromance
    clamdscan "$folder" --infected --verbose --multiscan --log=/var/log/clamav/log.log --stdout
    if grep -q FOUND /var/log/clamav/log.log; then
        echo "Infected file found in $folder..."
        grep FOUND /var/log/clamav/log.log >> /var/log/clamav/scan_summary.txt
    fi
done

# Display infected files at the end of the scan
echo "Displaying any 'Found' infected files:"
cat /var/log/clamav/scan_summary.txt
exit 0

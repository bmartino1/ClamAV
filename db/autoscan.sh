#!/bin/ash
# autoscan.sh - Script to update ClamAV and Scan specified folders

# old saved working of clamscan scan all of /mnt/user...
# echo update clamAV
# freshclam
# echo ClamAV Scan infected files "/scan" look at log...
#> /var/log/clamav/log.log  # Clear the log AV is using before scan
# clamscan --recursive /scan -i --log=/var/log/clamav/log.log | grep FOUND >> /var/log/clamav/infectedfile.txt
# sleep 5
# cat /var/log/clamav/infectedfile.txt
# cd /var/log/clamav
# ./find_infected_Files_from_log.sh
# sleep 10
# exit 0

# ClamdScan
# Update ClamAV definitions
echo "Updating ClamAV..."
freshclam || { echo "Failed to update ClamAV"; exit 1; }

# Set up directory for clamd socket
echo "Setting up clamd socket directory..."
mkdir -p /var/run/clamav
chown nobody:users /var/run/clamav
chmod 777 /var/run/clamav
#Unraid Docker Safe Permissions...

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
    echo "Waiting for clamd to be ready..."
    sleep 10
    READY_RETRIES=$((READY_RETRIES + 1))
done

# Define multiple folders to scan
SCAN_FOLDERS="/scan/"

#To exclude a directy you must edit /etc/clamd see examples at end of file...

# Clear previous scan summary and logs
> /var/log/clamav/log.log  # Clear the log AV is using before scan
> /var/log/clamav/scan_summary.txt  # Make sure the infected file log is clear for the next scan

# Perform ClamDscan only on specified folders
echo "Starting ClamAV Scan on Specified Folders..."
for folder in $SCAN_FOLDERS; do
    clamdscan "$folder" --infected --verbose --multiscan --log=/var/log/clamav/log.log | tee -a /var/log/clamav/log.log | logger -t clamav-scan
    if grep -q FOUND /var/log/clamav/log.log; then
        echo "Infected file found in $folder..." | logger -t clamav-scan
        grep FOUND /var/log/clamav/log.log >> /var/log/clamav/scan_summary.txt
    fi
done

# Display infected files at the end of the scan
echo "Displaying any 'Found' infected files:"
cat /var/log/clamav/scan_summary.txt

exit 0

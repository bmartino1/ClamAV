#!/bin/ash
# autoscan.sh - Script to update ClamAV and scan specified folders

# Update ClamAV definitions
echo "Updating ClamAV..."
freshclam || { echo "Failed to update ClamAV"; exit 1; }

# Updates can Break Clamd daemon...
> /var/log/clamav/clamd.log # Clear the clamd log before beginning
# scanned files are logged in clamd.log as scan progress(This is a clamd.conf setting)

# Set up directory for clamd socket
echo "Setting up clamd socket directory..."
mkdir -p /var/run/clamav
chown nobody:users /var/run/clamav
chmod 777 /var/run/clamav

# Ensure clamd daemon is running
if ! pgrep clamd > /dev/null; then
    echo "Starting clamd daemon..."
    clamd &
    sleep 60  # Increase wait time to give clamd enough time to start and create the socket
fi

# Wait for the clamd socket to be available
SOCKET="/var/run/clamav/clamd.sock"
MAX_RETRIES=6
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
MAX_READY_RETRIES=6
while ! clamdscan --version > /dev/null 2>&1; do
    echo "clamd might still be initializing. Checking again..."
    if [ $READY_RETRIES -ge $MAX_READY_RETRIES ]; then
        echo "Error: clamd is not ready after waiting. Exiting..."
        exit 1
    fi
    echo "Waiting for clamd to be ready..."
    sleep 10
    READY_RETRIES=$((READY_RETRIES + 1))
done

# Display the last 50 lines of clamd log before scanning to confirm clamd and settings
echo "Displaying the last few lines of clamd log:"
tail -n 45 /var/log/clamav/clamd.log

# Start watching the log file in the background to show real-time progress
echo "Starting log monitor..."
tail -f /var/log/clamav/clamd.log &
TAIL_PID=$!
echo "Monitoring log with PID: $TAIL_PID"

# Define multiple folders to scan
#SCAN_FOLDERS=" /scan/appdata /scan/system"
SCAN_FOLDERS="/scan"

# EXCLUDE_DIRS="/scan/system"
# Clamdscan uses /etc/clamd.conf for exclude folder... via regex
# since exclude is set in theory a /scan is all that is needed...

# Clear previous scan summary and logs
> /var/log/clamav/log.log  # Clear the log AV is using before scan
> /var/log/clamav/scan_summary.txt  # Make sure the infected file log is clear for the next scan

# Perform ClamDscan only on specified folders
for folder in $SCAN_FOLDERS; do
    clamdscan "$folder" --infected --verbose --multiscan --log=/var/log/clamav/log.log --stdout

#So log.log is the end of a clamdscan folder that will have a general summary overview... say if something has an infected file. however, clamd.log should now have the Found and file path...
    if grep -q FOUND /var/log/clamav/clamd.log; then
        echo "Infected file found in $folder..."
        # Capture infections...
        echo "Infected file found in $folder..." >> /var/log/clamav/scan_summary.txt
        grep FOUND /var/log/clamav/clamd.log >> /var/log/clamav/scan_summary.txt
    fi
done

# Stop the log monitor
kill $TAIL_PID

# Display infected files at the end of the scan
echo "Displaying any 'Found' infected files:"
cat /var/log/clamav/scan_summary.txt
exit 0

#!/bin/ash
#Dockers run Alpine Linux ash instead of bash...

#Saved, Old working Auto Scan
#old working scan all of /mnt/user 2 days...
#echo update clamAV
#freshclam
#echo ClamAV Scan infected files "/scan" look at log...
#clamscan --recursive /scan -i --log=/var/log/clamav/log.log | grep FOUND >> /var/log/clamav/infectedfile.txt
#sleep 5
#cat /var/log/clamav/infectedfile.txt
#cd /var/log/clamav
#./find_infected_Files_from_log.sh
#sleep 10
#exit 0

#New Auto Scan
# autoscan.sh - Script to update ClamAV and scan specified folders

# Update ClamAV definitions
echo "Updating ClamAV..."
freshclam || { echo "Failed to update ClamAV"; exit 1; }

#This asumes Docker Compose /mnt/user is set to dockcer path /scan
# Define folders to scan (including only the desired Docker folders)
SCAN_FOLDERS="/scan/%foldername% /scan/FolderName"

# Define folders to exclude from scan
EXCLUDE_DIRS="/scan/FolderName"

# Perform scan only on specified folders and exclude undesired directories
echo "Starting ClamAV scan on specified folders..."
> /var/log/clamav/infectedfile.txt  # Make sure the infected file log is in the correct directory
for folder in $SCAN_FOLDERS; do
    clamscan --recursive "$folder" -i --log=/var/log/clamav/log.log --verbose \
        --exclude-dir="$EXCLUDE_DIRS"
    if grep -q FOUND /var/log/clamav/log.log; then
        echo "Infected file found in $folder. See infectedfile.txt for details." >> /var/log/clamav/scan_summary.txt
        grep FOUND /var/log/clamav/log.log >> /var/log/clamav/infectedfile.txt
    fi
done

# Run script to find infected files
cd /var/log/clamav
./find_infected_Files_from_log.sh

# Allow time for review before exiting
sleep 10
exit 0

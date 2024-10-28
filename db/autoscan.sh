#!/bin/ash
#Dockers run Alpine Linux ash instead of bash...

# autoscan.sh - Script to update ClamAV and Then Scan a specified folder

# Update ClamAV definitions
echo "Updating ClamAV..."
freshclam || { echo "Failed to update ClamAV"; exit 1; }

#Review CLamAV scan command line options settings:
#https://docs.clamav.net/manual/Usage/Scanning.html
#https://linux.die.net/man/1/clamscan

#This asumes Docker Compose /mnt/user is set to dockcer path /scan
# Define folders to scan (including only the desired Docker folders)
SCAN_FOLDERS="/scan/"
#Example of mutiple folders... 
#SCAN_FOLDERS="/scan/%foldername%,/scan/FolderName"

# Define folders to exclude from scan
EXCLUDE_DIRS="/scan/system"
#Example of mutiple folders... 
#EXCLUDE_DIRS="/scan/%foldername%,/scan/FolderName"

# Perform scan only on specified folders and exclude undesired directories
echo "Starting ClamAV scan on specified folders..."
#> /var/log/clamav/infectedfile.txt  # Make sure the infected file log is in the correct directory
for folder in $SCAN_FOLDERS; do
    clamscan --recursive "$folder" -i --log=/var/log/clamav/log.log --verbose --exclude-dir="$EXCLUDE_DIRS"
    if grep -q FOUND /var/log/clamav/log.log; then
        echo "Infected file found in $folder. See infectedfile.txt for details."
        grep FOUND /var/log/clamav/log.log >> /var/log/clamav/infectedfile.txt
    fi
done

# Run script to Log Display infected files
cd /var/log/clamav
./find_infected_Files_from_log.sh

# Allow time for script above to review before exiting
sleep 10
exit 0

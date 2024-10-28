# Disclaimer! Many Thanks to TQ!
https://github.com/tquizzle/clamav-alpine/
This Project is a Fork! Mainly shared for others who may need a bit more granular control over the ClamAV in unraid.
THis is not my work, just eddited to work for my needs and shared for the needs of others...

# First-time Install:
1. Install Unraid Docker Compose Plugin.
2. Open Unraid terminal(via putty/Web UI / Console directly) cd to assumed data path to keep files. "cd /mnt/user/appdata" then GIT Clone the repo locally to the Unriad machine:

```
cd /mnt/user/appdata
git clone https://github.com/bmartino1/ClamAV.git
cd ClamAV
```

3. Unraid web UI Add a new stack click advance and change path to /mnt/user/appdata/ClamAV
4. Make edits to docker compoase / autoscan.sh if needed.
5. Unraid webUI update container to download and see clam av in unraid docker web ui...
6. start docker when ready to start a AV scan. In this case I Personaly have a User script Plugin script to start this docker and auto scan and do other things if a virus was detected... including notifying me and stoping other services to prevent a further malware infection...

# Disclaimer! Special Thanks to TQ!
[https://github.com/tquizzle/clamav-alpine/](https://github.com/tquizzle/clamav-alpine/)

This project is a fork, primarily shared for users who need more granular control over ClamAV in Unraid. This is not my original work; it has been modified to meet my requirements and is shared for others who may benefit.
This will use Clamdscan for AV scan and not call clamscan. Why? I had a 48 hour scan become a 6 hour scan by using clamdscan! This is due to how Clamdscann and concurent scans by calling clamscan mutiple times.

See some documentation:
- https://docs.clamav.net/manual/Usage/Scanning.html
- https://linux.die.net/man/1/clamscan

## First-Time Install:
1. Install the Unraid Docker Compose Plugin.
2. Open the Unraid terminal (via PuTTY, Web UI, or Console directly), navigate to the desired data path to store files (e.g., `/mnt/user/appdata`), and clone the repository to your Unraid machine:

    ```bash
    cd /mnt/user/appdata
    git clone https://github.com/bmartino1/ClamAV.git
    cd ClamAV
    ```

3. In the Unraid web UI, add a new stack, click "Advanced," and change the path to `/mnt/user/appdata/ClamAV`.
4. Make edits to `docker-compose.yml` and `autoscan.sh` if needed.
5. In the Unraid web UI, update the container to download and make ClamAV visible in the Docker web UI.
6. Start the Docker container to initiate an antivirus scan. Personally, I use a User Script Plugin to start this Docker container, run an automatic scan, and perform additional actions if a virus is detected. This includes sending notifications and stopping other services to prevent further malware infection.

---

Let me know if you have any questions or need further assistance!

# Still Use TQ Unraid Docker
https://forums.unraid.net/topic/80868-support-clamav/?do=findComment&comment=1480146
WIP as Clients / End Users would need to git clone this repo and add variables for docker...

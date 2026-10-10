# Immich Setup and Backup

Immich setup and backup instructions

## Setup

1. Clone the repo with `git clone https://github.com/TyHil/immich.git ~/immich-app` and `cd ~/immich-app`.

1. Follow instructions at https://docs.immich.app/install/docker-compose.

    a. Reconcile `docker-compose.yml` from Immich and the repo to add the Cloudflared container

    b. Reconcile `.env` from Immich and `.env.example` from the repo.

1. Follow instructions at https://github.com/immich-app/immich/discussions/8299 to set up Cloudflared and update the `.env` file.

4. Run `docker compose up -d`.

## Backup

1. Set up [Tailscale](https://tailscale.com/) and add your local server's ssh keys to your remote server.

1. Install [BorgBackup](https://www.borgbackup.org/) on both your local server and remote server.

1. Update paths in and run `./backup_setup.sh`.

1. Setup `./backup_script.sh`

    a. Run `cp .env.backup.example .env.backup` and set your Uptime Kuma push URL (see https://github.com/TyHil/uptime-kuma) for local and remote backups in `.env.backup`.
    
    a. Run `sudo mkdir -p /mnt/Backup` to create a mount directory. Then Run `lsblk -f`, identify your drives UUID, and fill it in to and run `echo "UUID=<UUID>  /mnt/Backup  ext4  defaults,nofail,x-systemd.automount  0  2" | sudo tee -a /etc/fstab` to create a fstab entry. Finally, run `sudo systemctl daemon-reload`, `sudo umount /mnt/Backup`, and `sudo systemctl start mnt-Backup.automount`. You should see the contents of your drive, automatically mounted, with `ls /mnt/Backup`.
    
    a. Update paths in `./backup_script.sh`.

1. Run `sudo cp immich-backup.example.service /etc/systemd/system/immich-backup.service` and `sudo cp immich-backup.example.timer /etc/systemd/system/immich-backup.timer` and edit the new file to have the correct `User`, `WorkingDirectory`, and `ExecStart` for you. Then run `sudo systemctl daemon-reload`, `sudo systemctl enable immich-backup.timer`, and `sudo systemctl start immich-backup.timer`.

1. Update paths and add the contents of `example.bash_aliases` to your `~/.bash_aliases` or run `cp example.bash_aliases ~/.bash_aliases`. Similarly, you may do the same with `example.remote.bash_aliases` on your remote server.

1. Finally run `source ~/.bash_aliases`, check the next backup time with `immich-backup status`, and backup now with `immich-backup backup`. This will take a long time.

### Manual Copy

Update paths in and run `cd "<MANUAL_BACKUP_PATH>/immich-backup/copy"` and `borg extract "<LOCAL_BACKUP_PATH>/immich-backup/immich-borg"::<NAME>`. `NAME` is the first column in `immich-backup list`. Optionally add `--strip-components 3` to avoid extra directories.

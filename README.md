# Immich Setup and Backup

Immich setup and backup instructions

## Setup

1. Clone the repo with `git clone https://github.com/TyHil/immich.git ~/immich-app` and `cd ~/immich-app`.

2. Follow instructions at https://docs.immich.app/install/docker-compose.

    a. Reconcile `docker-compose.yml` from Immich and the repo to add the Cloudflared container

    b. Reconcile `.env` from Immich and `.env.example` from the repo.

3. Follow instructions at https://github.com/immich-app/immich/discussions/8299 to set up Cloudflared and update the `.env` file.

3. Run `docker compose up -d`.

## Backup

1. Update paths in and run `./backup_setup.sh`.

2. Update paths in and run `./backup_script.sh`.

3. Run `cp immich-backup.example.service /etc/systemd/system/immich-backup.service` and `cp immich-backup.example.timer /etc/systemd/system/immich-backup.timer` and edit the new file to have the correct `User`, `WorkingDirectory`, and `ExecStart` for you. Then run `sudo systemctl daemon-reload`, `sudo systemctl enable immich-backup.timer`, and `sudo systemctl start immich-backup.timer`.

4. Add the contents of `example.bash_aliases` to your `~/.bash_aliases` or run `mv example.bash_aliases ~/.bash_aliases`.

5. Finally run `source ~/.bash_aliases` and `immich-backup start-now` to backup now or `immich-backup` to check the next backup time.


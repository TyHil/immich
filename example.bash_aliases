# Add to ~/.bash_aliases
function immich-backup() {
	if [ "$1" = "start" ]; then
		shift
		sudo systemctl start immich-backup.timer "$@"
	elif [ "$1" = "backup" ]; then
		shift
		sudo systemctl start immich-backup.service "$@"
	elif [ "$1" = "stop" ]; then
		shift
		sudo systemctl stop immich-backup.timer "$@"
	elif [ "$1" = "status" ]; then
		shift
		systemctl status immich-backup.timer "$@"
	elif [ "$1" = "logs" ]; then
		shift
		systemctl status immich-backup.service "$@"
	elif [ "$1" = "list" ]; then
		shift
		borg list /run/media/tyler-hill/Backup/immich-backup/immich-borg "$@"
	else
		systemctl status immich-backup.service "$@"
	fi
}


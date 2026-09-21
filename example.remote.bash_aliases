# Add to remote server's ~/.bash_aliases
function immich-backup() {
	if [ "$1" = "list" ]; then
		shift
		borg list /home/tyler-hill/immich-backup/immich-borg "$@"
	else
		borg list /home/tyler-hill/immich-backup/immich-borg "$@"
	fi
}


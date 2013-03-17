function help_command {
	if [ -n "$HELP" ]; then
		CMD=$(basename $0 | /usr/bin/perl -pe 's/\-/ /g')
		echo "    * $CMD $*"
		exit 1
	fi
}

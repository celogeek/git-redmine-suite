function help_command {
	if [ -n "$HELP" ]; then
		CMD=$(basename $0 | /usr/bin/perl -pe 's/\-/ /g')
		if [ -n "$POSSIBLE_ENV" ]; then
			CMD="$POSSIBLE_ENV $CMD"
		fi
		echo "    * $CMD $*"
		exit 1
	fi
}

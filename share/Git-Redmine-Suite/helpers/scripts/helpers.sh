# guide
function guide_show {
	man $MAN_DIR/$1.man
}

# setup
function setup_with_profile {
	GLOBAL="$1"

	if [ -z "$2" ]; then
		help_setup_with_profile
	fi

	PROFILE="$ROOT_DIR/helpers/setup/$2.conf"
	if [ ! -f "$PROFILE" ]; then
		help_setup_with_profile
	fi

	export AUTH_KEY="$3"
	if [ -z "$AUTH_KEY" ]; then
		echo "Missing AUTH_KEY :"
		echo ""
		HELP=1 $0
	fi

	git config --remove-section redmine.user 2> /dev/null

	cat $PROFILE | perl -pe 's/^(.*?)\s+=\s+(.*)$/git config '$GLOBAL' $1 "$2"/' | /bin/bash

	echo ""
}

function help_setup_with_profile {
	echo "Please select one of the available profiles : "
	echo ""

	for i in "$ROOT_DIR/helpers/setup/"*.conf; do
		P=$(basename "$i")
		echo "    * ${P/.conf}"
	done

	echo ""
	exit 1
}


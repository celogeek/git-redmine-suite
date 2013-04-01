# setup
function setup_with_profile {
	GLOBAL="$1"

	if [ -z "$2" ]; then
		help_setup_with_profile
	fi

	PROFILE=$2
	PROFILE_FILE="$ROOT_DIR/helpers/setup/$2.conf"
	if [ ! -f "$PROFILE_FILE" ]; then
		help_setup_with_profile
	fi

	export AUTH_KEY="$3"
	if [ -z "$AUTH_KEY" ]; then
		echo "Missing AUTH_KEY :"
		echo ""
		HELP=1 exec $0
	fi

	echo "Setup profile${GLOBAL/--/ } $PROFILE with $AUTH_KEY ..."

	git config --remove-section redmine.user 2> /dev/null

	(
		echo "git config $GLOBAL redmine.profile '$PROFILE'"
		cat $PROFILE_FILE | perl -pe 's/^(.*?)\s+=\s+(.*)$/git config '$GLOBAL' $1 "$2"/'
	) | /bin/bash

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

function setup_upgrade {
	
	PROFILE=$(git config --local redmine.profile)
	URL=$(git config --local redmine.url)
	AUTHKEY=$(git config --local redmine.authkey)
	REPO_VERSION=$(git config --local redmine.version)
	GLOBAL=""

	if [ -z "$URL" ] || [ -z "$AUTHKEY" ]; then
		PROFILE=$(git config --global redmine.profile)
		URL=$(git config --global redmine.url)
		AUTHKEY=$(git config --global redmine.authkey)
		REPO_VERSION=$(git config --global redmine.version)
		GLOBAL="--global"
	fi

	CURRENT_VERSION=$(cat "$ROOT_DIR/VERSION")

	if [ "$REPO_VERSION" != "$CURRENT_VERSION" ]; then
		git config $GLOBAL redmine.version "$CURRENT_VERSION"
		if [ -z "$PROFILE" ] && [ -n "$URL" ] && [ -n "$AUTHKEY" ]; then
			PROFILE=""
			for i in "$ROOT_DIR/helpers/setup/"*.conf; do
				grep -q ^"redmine.url.*=.*$URL$" "$i" && PROFILE=$(basename "${i/.conf}") && break
			done
		fi
		if [ -n "$PROFILE" ]; then
			setup_with_profile "$GLOBAL" "$PROFILE" "$AUTHKEY"
		fi
	fi

}
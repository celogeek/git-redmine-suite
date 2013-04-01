# setup
function setup_with_profile {
	GLOBAL="$1"

	if [ -z "$2" ]; then
		help_setup_with_profile
	fi

	PROFILE=$2

	if echo "$PROFILE" | grep -q ^"http"; then
		PROFILE_FILE=$(get_profile --url="$PROFILE" --skip_if_exists)
		PROFILE_MD5=$(get_md5 --file="$PROFILE_FILE")
	else
		PROFILE_FILE="$ROOT_DIR/helpers/setup/$2.conf"
		PROFILE_MD5=""
	fi

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
		echo "git config $GLOBAL redmine.profilemd5 '$PROFILE_MD5'"
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

	declare -a P=($GLOBAL)

	PROFILE_NEED_UPDATE=""
	if [ -n "$PROFILE" ] && echo "$PROFILE" | grep -q ^http; then
		PROFILE_FILE=$(get_profile --url="$PROFILE" --skip_if_exists)
		PROFILE_MD5=$(git config ${P[*]} redmine.profilemd5)
		if [ -z $PROFILE_MD5 ]; then
			PROFILE_NEED_UPDATE=1
		else
			PROFILE_REMOTE_MD5=$(get_md5 --file="$PROFILE_FILE")
			if [ "$PROFILE_MD5" != "$PROFILE_REMOTE_MD5" ]; then
				PROFILE_NEED_UPDATE=1
			fi
		fi
	fi

	CURRENT_VERSION=$(cat "$ROOT_DIR/VERSION")

	if [ "$REPO_VERSION" != "$CURRENT_VERSION" ] || [ -n "$PROFILE_NEED_UPDATE" ]; then
		git config ${P[*]} redmine.version "$CURRENT_VERSION"
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

function setup_export {
	URL=$(git config --local redmine.url)
	AUTHKEY=$(git config --local redmine.authkey)
	GLOBAL=""

	if [ -z "$URL" ] || [ -z "$AUTHKEY" ]; then
		URL=$(git config --global redmine.url)
		AUTHKEY=$(git config --global redmine.authkey)
		GLOBAL="--global"
	fi

	if [ -z "$URL" ] || [ -z "$AUTHKEY" ]; then
		echo "No profile setup yet, nothing to export"
		exit 1
	fi

	declare -a P=($GLOBAL)

	cat <<__EOF__
redmine.url = $URL
redmine.authkey = \$AUTH_KEY
__EOF__

	(
		git config ${P[*]} --get-regexp ^redmine.priocolor$
		git config ${P[*]} --get-regexp ^redmine.statuses
	) | /usr/bin/perl -pe 's/\s+/ = /'
}

function setup_update {
	PROFILE=$(git config --local redmine.profile)
	GLOBAL=""

	if [ -z "$PROFILE" ]; then
		PROFILE=$(git config --global redmine.profile)
		GLOBAL="--global"
	fi

	if [ -z "$PROFILE" ]; then
		echo "No profile setup, nothing to update !"
		exit 1
	fi

	declare -a P=($GLOBAL)

	AUTHKEY=$(git config ${P[*]} redmine.authkey)
	if [ -z "$AUTHKEY" ]; then
		echo "No AUTH_KEY, please setup a profile first !"
		exit 1
	fi

	setup_with_profile "$GLOBAL" "$PROFILE" "$AUTHKEY"

}
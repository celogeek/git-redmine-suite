function hotfix_start {

	TASK=$1
	
	if [ -z "$TASK" ]; then
		echo "Missing TASK_NUMBER : "
		echo ""
		HELP=1 exec $0
	fi
	
	if [ -z "$VERSION" ]; then
		echo "Missing VERSION : "
		echo ""
		HELP=1 exec $0
	fi

	git_refresh_local_repos

	if ! git tag | grep -q ^"v$VERSION"$; then
		echo "'$VERSION' is not a valid version : "
		echo ""
		git tag | grep ^v | /usr/bin/perl -pe 's/^v/    * /'
		echo ""
		HELP=1 exec $0
	fi

	HOTFIX_CURRENT_VERSION=$(git tag | egrep ^"(v|${HOTFIX_PREFIX_TAG}-)$VERSION" |  /usr/bin/perl -pe 's/^(v|'${HOTFIX_PREFIX_TAG}'-)//' | sort -n | tail -n 1)
	HOTFIX_PREFIX_VERSION="${HOTFIX_PREFIX_TAG}-"
	HOTFIX_MERGE_FROM="$HOTFIX_PREFIX_VERSION$HOTFIX_CURRENT_VERSION"

	if [ "$HOTFIX_CURRENT_VERSION" = "$VERSION" ]; then
		HOTFIX_CURRENT_VERSION="${VERSION}_000"
		HOTFIX_PREFIX_VERSION="v"
		HOTFIX_MERGE_FROM="v$VERSION"
	fi

	HOTFIX_VERSION=$(next_version --version="$HOTFIX_CURRENT_VERSION")

	echo -n "Starting the ${HOTFIX_PREFIX_TAG} : "
	if ! redmine-get-task-info --task_id=$TASK --with_status; then
		exit 1
	fi

	if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to start this ${HOTFIX_PREFIX_TAG} ?"; then
		exit 1
	fi

	task=$TASK \
	status=$REDMINE_TASK_IN_PROGRESS \
	assigned_to=$REDMINE_USER_ID \
	cf_id=$REDMINE_GIT_REPOS_ID \
	cf_val=$REDMINE_GIT_REPOS_URL \
	progress=10 \
	task_update || exit 1

	TASK_DEV=$(redmine-get-task-developers --task_id="$TASK" --status_ids="$REDMINE_TASK_IN_PROGRESS")
	TASK_TITLE=$(redmine-get-task-info --task_id=$TASK)
	SLUG_TITLE=$(slug --this "$TASK_TITLE")
	BRNAME="redmine-${HOTFIX_PREFIX_TAG}-$HOTFIX_VERSION-$SLUG_TITLE"
	CHANGELOG=$(get_change_log)

	echo "Creation local branch $BRNAME ..."
	git checkout -b "$BRNAME" "tags/$HOTFIX_MERGE_FROM" || exit 1
	git config "redmine.${HOTFIX_PREFIX_TAG}.current" "$TASK"
	git config "redmine.${HOTFIX_PREFIX_TAG}.version" "$HOTFIX_VERSION"
	git config "redmine.${HOTFIX_PREFIX_TAG}.branch" "$BRNAME"
	git push origin -u "$BRNAME":"$BRNAME" || exit 1

	if [ -e 'dist.ini' ]
	then
	    cat dist.ini | /usr/bin/perl -pe "s/^version(\\s*)=(\\s*)(.*)/version\${1}=\${2}$HOTFIX_VERSION/" > dist.ini.new
	    mv dist.ini.new dist.ini
	    $EDITOR dist.ini
	    git add dist.ini
	    git commit -m 'Update version DistZilla'
	fi

	if [ -e 'VERSION' ]
	then
	    echo "$HOTFIX_VERSION" > VERSION
	    git add VERSION
	    git commit -m 'Update version file'
	fi

	tag_version --version="${HOTFIX_PREFIX_TAG}-$HOTFIX_VERSION" > "$CHANGELOG".new
	echo "    * Hotfix : $TASK_TITLE ($TASK_DEV)" >> "$CHANGELOG".new
	touch "$CHANGELOG"
	if head -n1 "$CHANGELOG" | grep -q ^"[0-9]"; then
		echo >> "$CHANGELOG".new
	fi
	cat "$CHANGELOG" >> "$CHANGELOG".new
	mv "$CHANGELOG".new "$CHANGELOG"
	$EDITOR "$CHANGELOG"
	git add "$CHANGELOG"
	git commit -m "reflect changes" "$CHANGELOG" || true

	cat <<__EOF__
When you have finish your ${HOTFIX_PREFIX_TAG}, run

	* git hotfix finish -T ${HOTFIX_PREFIX_TAG}

This will only tag the current branch and push it.

No merge is automatically done into devel. Generally speaking, this patch should come from devel by cherry-pick.

__EOF__

}

function hotfix_finish {

	CURRENT_TASK=$(git config redmine.${HOTFIX_PREFIX_TAG}.current)
	VERSION=$(git config redmine.${HOTFIX_PREFIX_TAG}.version)
	BRNAME=$(git config redmine.${HOTFIX_PREFIX_TAG}.branch)

	if [ -z "$CURRENT_TASK" ]; then
		echo "No ${HOTFIX_PREFIX_TAG} started !"
		exit 1
	fi

	if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to finish the ${HOTFIX_PREFIX_TAG} $CURRENT_TASK ?"; then
		exit 1
	fi

	PROJECT=$(redmine-get-task-project-identifier --task_id=$CURRENT_TASK)
	while true; do
		reassigned_this "hotfix" "$PROJECT" || true
		if [ -z "$ASSIGNED_TO_ID" ]; then
			echo "You need it for the release !"
		else
			break
		fi
	done


	set -e
	git_refresh_local_repos
	git checkout "$BRNAME" || exit 1
	git tag -m "${HOTFIX_PREFIX_TAG} v$VERSION: $CURRENT_TASK" "${HOTFIX_PREFIX_TAG}-$VERSION"
	git push origin "$BRNAME":"$BRNAME"
	git push origin "tags/${HOTFIX_PREFIX_TAG}-$VERSION"
	git checkout devel
	git branch -D "$BRNAME"
	set +e

  git config --remove-section redmine.${HOTFIX_PREFIX_TAG}

	task=$CURRENT_TASK \
	status=$REDMINE_RELEASE_FINISH \
	assigned_to=$ASSIGNED_TO_ID \
	cf_id=$REDMINE_GIT_RELEASE_ID \
	cf_val="$VERSION" \
	progress=100 \
	task_update || exit 1

}

function hotfix_abort {

	CURRENT_TASK=$(git config redmine.${HOTFIX_PREFIX_TAG}.current)
	BRNAME=$(git config redmine.${HOTFIX_PREFIX_TAG}.branch)

	if [ -z "$CURRENT_TASK" ]; then
		echo "No ${HOTFIX_PREFIX_TAG} started !"
	    exit 1
	fi

	if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to abort the ${HOTFIX_PREFIX_TAG} $BRNAME ?"; then
		exit 1
	fi

	git config --remove-section redmine.${HOTFIX_PREFIX_TAG}

	git_refresh_local_repos
	git checkout devel
	git push origin :"$BRNAME"
	git branch -D "$BRNAME"

}

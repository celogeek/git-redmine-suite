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

	HOTFIX_CURRENT_VERSION=$(git tag | grep ^"v$VERSION" | /usr/bin/perl -pe 's/^v//' | tail -n 1)
	HOTFIX_MERGE_FROM=$HOTFIX_CURRENT_VERSION

	if [ "$HOTFIX_CURRENT_VERSION" = "$VERSION" ]; then
		HOTFIX_CURRENT_VERSION="${VERSION}000"
	fi

	HOTFIX_VERSION=$(next_version --version="$HOTFIX_CURRENT_VERSION")

	echo -n "Starting the hotfix : "
	if ! redmine-get-task-info --task_id=$TASK --with_status; then
		exit 1
	fi

	if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to start this hotfix ?"; then
		exit 1
	fi

	task=$TASK \
	status=$REDMINE_TASK_IN_PROGRESS \
	assigned_to=$REDMINE_USER_ID \
	cf_id=$REDMINE_GIT_REPOS_ID \
	cf_val=$REDMINE_GIT_REPOS_URL \
	progress=10 \
	task_update || exit 1

	PROJECT=$(redmine-get-task-project-identifier --task_id=$TASK)
	TASK_TITLE=$(redmine-get-task-info --task_id=$TASK)
	SLUG_TITLE=$(slug --this "$TASK_TITLE")
	BRNAME="redmine-hotfix-$HOTFIX_VERSION-$SLUG_TITLE"

	echo "Creation local branch $BRNAME ..."
	git checkout -b "$BRNAME" "tags/v$HOTFIX_MERGE_FROM" || exit 1
	git config "redmine.hotfix.current" "$TASK"
	git config "redmine.hotfix.version" "$HOTFIX_VERSION"
	git config "redmine.hotfix.branch" "$BRNAME"
	git config "redmine.hotfix.project" "$PROJECT"
	git push origin -u $BRNAME || exit 1

	cat <<__EOF__
When you have finish your hotfix, run

	* git hotfix finish

This will only tag the current branch and push it.

No merge is automatically done into devel. Generally speaking, this patch should come from devel by cherry-pick.

__EOF__

}

function hotfix_finish {

	CURRENT_TASK=$(git config redmine.hotfix.current)
	VERSION=$(git config redmine.hotfix.version)
	BRNAME=$(git config redmine.hotfix.branch)
	PROJECT=$(git config redmine.hotfix.project)

	if [ -z "$CURRENT_TASK" ]; then
		echo "No hotfix started !"
		exit 1
	fi

	if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to finish the hotfix $CURRENT_TASK ?"; then
		exit 1
	fi


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
	git tag -m "hotfix v$VERSION: $CURRENT_TASK" "v$VERSION"
	git push
	git push origin "tags/v$VERSION"
	git checkout devel
	git branch -D "$BRNAME"
	set +e

	task=$CURRENT_TASK \
	status=$REDMINE_RELEASE_FINISH \
	assigned_to=$ASSIGNED_TO_ID \
	cf_id=$REDMINE_GIT_RELEASE_ID \
	cf_val="$VERSION" \
	progress=100 \
	task_update || exit 1

}

function hotfix_abort {

	CURRENT_TASK=$(git config redmine.hotfix.current)
	BRNAME=$(git config redmine.hotfix.branch)

	if [ -z "$CURRENT_TASK" ]; then
		echo "No hotfix started !"
	    exit 1
	fi

	if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Aborting hotfix $BRNAME ?"; then
		exit 1
	fi

	git config --remove-section redmine.hotfix

	git_refresh_local_repos
	git checkout devel
	git push origin :"$BRNAME"
	git branch -D "$BRNAME"

}
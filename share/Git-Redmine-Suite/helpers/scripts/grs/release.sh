function release_start {
	declare -a TASKS=($@)

	if [ ${#TASKS[@]} -eq 0 ]; then
		git redmine release pending
		if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you want to release these tasks ?"; then
			exit 1
		fi
		TASKS=($(redmine-get-task-list --status_ids="$REDMINE_RELEASE_TODO" --cf_id="$REDMINE_GIT_REPOS_ID" --cf_val="$REDMINE_GIT_REPOS_URL" --ids_only))
		REDMINE_FORCE=1
	fi

	if [ ${#TASKS[@]} -eq 0 ]; then
		echo "Nothing to release !"
	fi

	check_valid_editor

	git_refresh_local_repos

	if [ -z "$VERSION" ]; then
	    VERSION=$(next_version --version=$(((git tag | grep ^v) || echo "v0.00") | /usr/bin/perl -pe 's/^v//' | sort -n | tail -n1))
	fi

	echo "Release V$VERSION with tasks ${TASKS[@]} ..."
	if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Continue ?"; then
		exit 1
	fi

	for TASK in ${TASKS[@]}
	do
	    task=$TASK \
	    status=$REDMINE_RELEASE_TODO \
	    assigned_to=$REDMINE_USER_ID \
	    git_repos_id=$GIT_REPOS_ID \
	    git_repos_url=$GIT_REPOS_URL \
	    task_update || exit 1
	done

	BRNAME="redmine-release-v$VERSION"

	git checkout devel
	git merge origin/devel
	git checkout -b "$BRNAME"
	
	git config "redmine.release.version" "$VERSION"
	git config "redmine.release.tasks" "${TASKS[*]}"
	git config "redmine.release.branch" "$BRNAME"
	
	CHANGELOG=$(get_change_log)
	touch "$CHANGELOG"

	tag_version --version="$VERSION" > "$CHANGELOG".new
	cat "$CHANGELOG" >> "$CHANGELOG".new
	mv "$CHANGELOG".new "$CHANGELOG"
	"$EDITOR" "$CHANGELOG"
	git add "$CHANGELOG"
	git ci -m "Add version in Changes"

	if [ -e 'dist.ini' ]
	then
	    cat dist.ini | /usr/bin/perl -pe "s/version = (.*)/version = $VERSION/" > dist.ini.new
	    mv dist.ini.new dist.ini
	    "$EDITOR" dist.ini
	    git add dist.ini
	    git ci -m 'Update version DistZilla'
	fi

	if [ -e 'VERSION' ]
	then
	    echo "$VERSION" > VERSION
	    git add VERSION
	    git ci -m 'Update version file'
	fi

	git diff --color origin/master | less -R

	cat <<__EOF__
Please edit all the file you need and commit it before finish the release.
Don't forget to run the tests !

You can finish with :

git redmine release finish

or you can abort :

git redmine release abort

__EOF__

	if [ -n "$REDMINE_CHAIN_FINISH" ] ; then
    	exec git redmine release finish
	fi	

}

function release_abort {

	VERSION=$(git config redmine.release.version)
	BRNAME=$(git config redmine.release.branch)

	if [ -z "$VERSION" ]; then
		echo "No release started !"
	    exit 1
	fi

	if [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to abort the release $BRNAME ?"; then
		exit 1
	fi
	git config --remove-section redmine.release
	git checkout devel
	git branch -D $BRNAME

}

function release_finish {
	
	VERSION=$(git config redmine.release.version)
	BRNAME=$(git config redmine.release.branch)
	declare -a TASKS=($(git config redmine.release.tasks))

	if [ -z "$VERSION" ]; then
		echo "No release started !"
	    exit 1
	fi

	if [ -z "$REDMINE_CHAIN_FINISH" ] && [ -z "$REDMINE_FORCE" ] && ! ask_question --question="Do you really want to finish the release of these tasks : ${TASKS[*]} ?"; then
		exit 1
	fi

	echo "Finish the release ${TASKS[@]} ..."

	set -e
	git_refresh_local_repos
	git checkout devel
	git merge origin/devel
	git merge --no-ff "$BRNAME" -m "Merge $BRNAME"
	git push origin devel
	git checkout master
	git merge origin/master
	git merge --no-ff devel -m "Merge $BRNAME"
	git tag -m "release v$V: ${TASKS[*]}" "v$VERSION"
	git push origin master
	git push origin "tags/v$VERSION"
	git checkout devel
	git branch -d "$BRNAME"
	git config --remove-section redmine.release
	set +e

	echo ""
	echo "Update redmine"
	for TASK in ${TASKS[@]}; do
		echo ""
		echo "Task # $TASK : "

		redmine-get-task-info --task_id="$TASK" --with_status
		echo ""
		PROJECT=$(redmine-get-task-project-identifier --task_id=$TASK)
		

		while true; do
			reassigned_this "release" "$PROJECT" || true
			if [ -z "$ASSIGNED_TO_ID" ]; then
				echo "You need it for the release !"
			else
				break
			fi
		done

	    task=$TASK \
	    status=$REDMINE_RELEASE_FINISH \
	    assigned_to=$ASSIGNED_TO_ID \
	    cf_id=$REDMINE_GIT_RELEASE_ID \
	    cf_val="$VERSION" \
	    task_update
	done

	
}
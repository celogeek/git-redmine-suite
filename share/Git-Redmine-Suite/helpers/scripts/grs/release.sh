function release_start {
	declare -a TASKS=($@)

	if [ ${#TASKS[@]} -eq 0 ]; then
		git redmine release pending
		if ! ask_question --question="Do you want to release these task ?"; then
			exit 1
		fi
		TASKS=($(redmine-get-task-list --status_ids="$REDMINE_RELEASE_TODO" --cf_id="$REDMINE_GIT_REPOS_ID" --cf_val="$REDMINE_GIT_REPOS_URL" --ids_only))
		REDMINE_CHAIN=1
	fi

	if [ ${#TASKS[@]} -eq 0 ]; then
		echo "Nothing to release !"
	fi

	git_refresh_local_repos

	if [ -z "$VERSION" ]; then
	    VERSION=$(next_version --version=$(((git tag | grep ^v) || echo "v0.00") | /usr/bin/perl -pe 's/^v//' | sort -n | tail -n1))
	fi

	echo "Release V$VERSION with tasks ${TASKS[@]} ..."
	if [ -z "$REDMINE_CHAIN" ]; then
		if ! ask_question --question="Continue ?"; then
			exit 1
		fi
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
	git config "redmine.release.tasks" "$(echo ${TASKS[@]})"
	git config "redmine.release.branch" "$BRNAME"
	
	CHANGELOG=$(get_change_log)
	touch "$CHANGELOG"

	tag_version --version="$VERSION" > "$CHANGELOG".new
	cat "$CHANGELOG" >> "$CHANGELOG".new
	mv "$CHANGELOG".new "$CHANGELOG"
	vim "$CHANGELOG"
	git add "$CHANGELOG"
	git ci -m "Add version in Changes"

	if [ -e 'dist.ini' ]
	then
	    cat dist.ini | /usr/bin/perl -pe "s/version = (.*)/version = $VERSION/" > dist.ini.new
	    mv dist.ini.new dist.ini
	    vim dist.ini
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

	if ask_question --question="Do you want to finish the release now ?"; then
    	REDMINE_CHAIN=1 exec git redmine release finish
	fi	

}
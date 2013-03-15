# tasks
function task_update
{
	declare -a PARAMS

	PARAMS+=(--task_id "$task")
	PARAMS+=(--status_ids "$status")
	PARAMS+=(--assigned_to_id "$assigned_to")

	declare -a ADD_PARAMS
	if [ "$status" = "$REDMINE_REVIEW_TODO" ]
		then
		ADD_PARAMS+=(--progress "100")
	elif [ -n "$progress" ]
		then
		ADD_PARAMS+=(--progress "$progress")
	fi

	if [ -n "$notes" ]
		then
		ADD_PARAMS+=(--notes "$notes")
	fi

	if [ -n "$cf_id" ] && [ -n "$cf_val" ]
		then
		ADD_PARAMS+=(--cf_id "$cf_id")
		ADD_PARAMS+=(--cf_val "$cf_val")
	fi

    redmine-update-task "${PARAMS[@]}" "${ADD_PARAMS[@]}"
    redmine-check-task "${PARAMS[@]}"
}

function task_start {
	TASK=$1
	if [ -z "$TASK" ]; then
		echo "Missing TASK_NUMBER : "
		echo ""
		HELP=1 $0
	fi

	if git config redmine.task.$TASK.branch > /dev/null; then
		task_continue "$1"
	else
		task_create "$1"
	fi

}

function task_continue {
	TASK=$1
	BRNAME=$(git config redmine.task.$TASK.branch)
    echo "Continue the task $TASK ..."
    echo ""
    echo "Updating redmine ..."
	task=$TASK \
	status=$REDMINE_TASK_IN_PROGRESS \
	assigned_to=$REDMINE_USER_ID \
	cf_id=$REDMINE_GIT_REPOS_ID \
	cf_val=$REDMINE_GIT_REPOS_URL \
	progress=10 \
	task_update || exit 1
    echo ""
    echo "Checkout local branch $BRNAME ..."
    git_refresh_local_repos
    git checkout "$BRNAME"
    git config "redmine.task.current" "$TASK"
    git rebase origin/"$BRNAME" || cat <<__EOF__
Fix the conflict, and finish the rebase or remote branch

__EOF__

    cat <<__EOF__

To update your branch :
    git rebase origin/devel
    #fix conflict, then
    git push origin -f $BRNAME

__EOF__

}

function task_create {
	TASK=$1

	echo "Starting the task : "
	if ! redmine-get-task-info --task_id=$TASK --with-extended-status; then
		exit 1
	fi
	if ! ask_question --question="Do you really want to start this task ?"; then
		exit 1
	fi

	echo "Updating redmine status ..."

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
	BRNAME="redmine-$SLUG_TITLE"

	echo "Creation local branch $BRNAME ..."
	git_refresh_local_repos
	git checkout -b "$BRNAME" origin/devel || git checkout "$BRNAME" || exit 1
	git config "redmine.task.current" "$TASK"
	git config "redmine.task.$TASK.title" "$TASK_TITLE"
	git config "redmine.task.$TASK.branch" "$BRNAME"
	git config "redmine.task.$TASK.project" "$PROJECT"
	git push origin -u $BRNAME || cat <<__EOF__
The remote branch $BRNAME already exist !
You have 2 choice. 

Or you take control of this branch :

    git push -fu origin "$BRNAME"

Or you get that branch and continue the devel :

    git reset --hard "origin/$BRNAME"
    git push -u origin "$BRNAME"

__EOF__


}

function task_status {
	echo "Status of your tasks : "
	echo ""
	CURRENT_TASK=$(git config redmine.task.current)
	for TASK in $(git config --get-regexp ^'redmine\.task\..*\.' | cut -d "." -f 3 | sort -u); do
		if [ "$TASK" == "$CURRENT_TASK" ]; then
			continue
		fi
    	T=$(redmine-get-task-info --task_id=$TASK --with-status)
		echo "    $T"
    	if echo "$T" | grep -q ", Released with v"
    	then
    		if ask_question --question="This task (# $TASK) has been released, clear it ?"
    		then
    			git redmine task clear $TASK
    		fi
    	fi
   	    echo ""
	done
	echo ""
}

function task_clear {
	TASK=$1
	if [ -z "$TASK" ]; then
		echo "Missing TASK_NUMBER : "
		echo ""
		HELP=1 $0
	fi

	BRNAME=$(git config "redmine.task.${TASK}.branch")
	
	if [ -z "$BRNAME" ]; then
		echo "Invalid task !"
		exit 1
	fi

	echo "Cleaning local and remote dev for task $TASK..."

	git_refresh_local_repos	
	git checkout devel
	git merge origin/devel
	git branch -D "$BRNAME"
	git push origin :"$BRNAME"
	git config --remove-section "redmine.task.$TASK"

	CURRENT_TASK=$(git config redmine.task.current)
	if [ "$TASK" == "$CURRENT_TASK" ]; then
		git config --unset redmine.task.current
	else
		git checkout $(git config redmine.task.$CURRENT_TASK.branch)
	fi

}

function task_depends {
	CURRENT_TASK=$(git config redmine.task.current)

	if [ -z "$CURRENT_TASK" ]; then
		echo "No task started !"
		exit 1
	fi

	DEPS="$@"

	if [ -z "$DEPS" ]; then
		if ask_question --question "Do you want to clear the deps of this task ?"; then
			git config --unset redmine.task.$CURRENT_TASK.depends
		fi
	else
		if ask_question --question "Do you want to set the deps of this task to '$DEPS' ?"; then
			git config redmine.task.$CURRENT_TASK.depends "$DEPS"
		fi
	fi
}
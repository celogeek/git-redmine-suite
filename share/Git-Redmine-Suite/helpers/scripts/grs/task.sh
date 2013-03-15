# tasks
function task_update
{
	declare -a PARAMS

	PARAMS+=(--id "$task")
	PARAMS+=(--status_id "$status")
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

	
}
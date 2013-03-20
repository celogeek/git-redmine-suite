function reassigned_this {
	TYPE=$1
	PROJECT=$2

	redmine-get-project-users-id --project="$PROJECT"
	echo ""

	PREVIOUS_ASSIGNED_TO_ID=$(git config redmine.project.$PROJECT.$TYPE)

	declare -a PARAMS=(--question "Which one do you want to assigned the $TYPE to ?" --answer_mode "id")
	if [ -n "$PREVIOUS_ASSIGNED_TO_ID" ]; then
		PARAMS+=(--default_answer "$PREVIOUS_ASSIGNED_TO_ID")
	fi

	if [ -n "$REDMINE_AUTO_REASSIGN" ] && [ -z "$REDMINE_NO_AUTO_REASSIGN" ] && [ -n "$PREVIOUS_ASSIGNED_TO_ID" ]; then
		echo "${PARAMS[1]} $PREVIOUS_ASSIGNED_TO_ID"
		echo ""
		ASSIGNED_TO_ID="$PREVIOUS_ASSIGNED_TO_ID"
	else
		REDMINE_NO_AUTO_REASSIGN=""
		ASSIGNED_TO_ID=$(ask_question "${PARAMS[@]}")
	fi

	if ! redmine-check-project-users-id --project="$PROJECT" --assigned_to_id="$ASSIGNED_TO_ID"; then
		ASSIGNED_TO_ID=""
		echo "This user is not a member of this project !"
		if [ -n "$REDMINE_AUTO_REASSIGN" ]; then
			echo ""
			REDMINE_NO_AUTO_REASSIGN="1"
			reassigned_this $TYPE $PROJECT
		else
			if [ "$TYPE" != "release" ]; then
				exit 1
			fi
		fi
	else
		git config redmine.project.$PROJECT.$TYPE $ASSIGNED_TO_ID
	fi
}
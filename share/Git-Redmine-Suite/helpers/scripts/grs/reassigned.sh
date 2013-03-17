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

	ASSIGNED_TO_ID=$(ask_question "${PARAMS[@]}")

	if ! redmine-check-project-users-id --project="$PROJECT" --assigned_to_id="$ASSIGNED_TO_ID"; then
		echo "This user is not a member of this project !"
		exit 1
	fi

	git config redmine.project.$PROJECT.$TYPE $ASSIGNED_TO_ID
}
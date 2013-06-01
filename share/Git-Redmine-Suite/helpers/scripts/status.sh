function check_status_tasks {
	GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
	if [ -n "$GIT_DIR" ]; then
		LAST_CHECK=$(git config redmine.task.lastcheck)
		if [ -z "$LAST_CHECK" ] || delta_date_check --date "$LAST_CHECK" --days "7"
		then
			git config redmine.task.lastcheck $(date +%Y%m%d)
			echo "You have not check the status of your tasks since more than a week !"
			if ask_question --question="Check Now ?"
			then
				git redmine task status -f
			else
				echo "Please run a check from time to time to clear the remote repository and yours."
				echo "    * git task status -f"
				echo ""
			fi
		fi
	fi
}
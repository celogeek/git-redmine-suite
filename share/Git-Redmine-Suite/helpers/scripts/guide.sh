# guide
function guide_show {
	case $1 in
		setup)
			cat <<__EOF__
You can consult the wiki :

    * Installation of Grs on Desktop : https://tasks.celogeek.com/projects/git-redmine-suite/wiki/InstallationGrsOnDesktop
    * Setup Grs : https://tasks.celogeek.com/projects/git-redmine-suite/wiki/SetupGRS

__EOF__
		;;
		developers)
			cat <<__EOF__
You can consult the wiki :

	* The developers' guide : https://tasks.celogeek.com/projects/git-redmine-suite/wiki/GuideOfDevelopers

__EOF__
		;;

		reviewers)
			cat <<__EOF__
You can consult the wiki :

	* The reviewer's guide : https://tasks.celogeek.com/projects/git-redmine-suite/wiki/GuideOfReviewers

__EOF__
		;;
		*)
			man $MAN_DIR/$1.man
		;;
	esac

}

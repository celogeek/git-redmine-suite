# guide
function guide_show {
  echo "You can consult the wiki :"
  echo ""

  case $1 in
    setup)
      echo "    * Installation of Grs on Desktop : https://tasks.celogeek.com/projects/git-redmine-suite/wiki/InstallationGrsOnDesktop"
        echo "    * Setup Grs : https://tasks.celogeek.com/projects/git-redmine-suite/wiki/SetupGRS"
    ;;
    developers)
      echo "    * The developers' guide : https://tasks.celogeek.com/projects/git-redmine-suite/wiki/GuideOfDevelopers"
    ;;

    reviewers)
      echo "    * The reviewers' guide : https://tasks.celogeek.com/projects/git-redmine-suite/wiki/GuideOfReviewers"
    ;;
    releasers)
      echo "    * The releasers' guide : https://tasks.celogeek.com/projects/git-redmine-suite/wiki/GuideOfReleasers"
    ;;
  esac

  echo ""

}

#!/bin/bash
cd "$(dirname "$0")"
cpanm -nv http://search.cpan.org/CPAN/authors/id/F/FR/FRANCKC/Net-HTTP-Spore-0.05.tar.gz http://cpan.metacpan.org/authors/id/C/CE/CELOGEEK/Redmine-API-0.03.tar.gz
sudo mkdir -p /usr/local/share/Weborama-Git-Review/helpers/
sudo cp -av helpers/* /usr/local/share/Weborama-Git-Review/helpers/
sudo cp -av bin/* /usr/local/bin/
sudo chmod +x /usr/local/share/Weborama-Git-Review/helpers/* /usr/local/bin/git-review /usr/local/bin/git-review-*

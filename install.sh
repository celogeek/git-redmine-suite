#!/bin/bash
cd "$(dirname "$0")"
[ "x$SKIP_CPANM" == "x" ] && sudo HOME=/tmp PERL_CPANM_OPT="" ./cpanm -nv Redmine::API Moo MooX::Options LWP::Protocol::https Version::Next Encode DateTime Term::ReadLine
sudo rm -rf /usr/local/share/Git-Redmine-Suite usr/local/bin/git-redmine /usr/local/bin/git-redmine-*

sudo mkdir -p /usr/local/share/Git-Redmine-Suite/helpers/
sudo cp -av helpers/* /usr/local/share/Git-Redmine-Suite/helpers/
sudo cp -av bin/* /usr/local/bin/
sudo cp -av VERSION /usr/local/share/Git-Redmine-Suite/

POD2MAN=$(/usr/bin/perl -E 'say "/usr/bin/pod2man", sprintf("%d.%d",split(/\./, sprintf("%vd",$^V)))')
[ -x $POD2MAN ] || POD2MAN=/usr/bin/pod2man
for F in /usr/local/share/Git-Redmine-Suite/helpers/pod/guide/*.pod
do
    echo "Pod2Man : $F ..."
    sudo $POD2MAN "$F" "${F/.pod/.man}"
done

sudo chown -R 0:0 /usr/local/share/Git-Redmine-Suite/ /usr/local/bin/git-redmine /usr/local/bin/git-redmine-*
sudo chmod -R 755 /usr/local/share/Git-Redmine-Suite/ /usr/local/bin/git-redmine /usr/local/bin/git-redmine-*
sudo chmod u+s,g+s /usr/local/bin/git-redmine-self-upgrade*

if [ "x$CURPWD" != "x" ] && [ "x$1" != "x" ]
then
	echo ""
	echo "Move to $CURPWD"
	cd "$CURPWD"
	echo ""
	echo "Run : $*"
	echo ""
	exec $*
fi

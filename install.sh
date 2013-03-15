#!/bin/bash
cd "$(dirname "$0")"
[ -z "$SKIP_CPANM" ] && sudo HOME=/tmp PERL_CPANM_OPT="" ./cpanm -nv Redmine::API Moo MooX::Options LWP::Protocol::https Version::Next DateTime Term::ReadLine Date::Parse LWP::Curl List::MoreUtils List::Util List::Util::XS autodie utf8::all Term::Size

sudo rm -rf /usr/local/share/Git-Redmine-Suite /usr/local/bin/git-redmine /usr/local/bin/git-redmine-*

sudo cp -rv share/* /usr/local/share/
sudo cp -av bin/* /usr/local/bin/

POD2MAN=$(/usr/bin/perl -E 'say "/usr/bin/pod2man", sprintf("%d.%d",split(/\./, sprintf("%vd",$^V)))')
[ -x $POD2MAN ] || POD2MAN=/usr/bin/pod2man
for F in /usr/local/share/Git-Redmine-Suite/helpers/pod/guide/*.pod
do
    echo "Pod2Man : $F ..."
    sudo $POD2MAN "$F" "${F/.pod/.man}"
done

sudo chown -R 0:0 /usr/local/share/Git-Redmine-Suite/ /usr/local/bin/git-redmine /usr/local/bin/git-redmine-*
sudo chmod -R 755 /usr/local/share/Git-Redmine-Suite/ /usr/local/bin/git-redmine /usr/local/bin/git-redmine-*

if [ -n "$CURPWD" ] && [ -n "$1" ]
then
	echo ""
	echo "Move to $CURPWD"
	cd "$CURPWD"
	echo ""
	echo "Run : $*"
	echo ""
	exec $*
fi

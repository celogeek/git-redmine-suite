ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../"; pwd)
SCRIPT_DIR=$ROOT_DIR/helpers/scripts
PERL_DIR=$ROOT_DIR/helpers/perls
MAN_DIR=$ROOT_DIR/helpers/pod/guide

source $ROOT_DIR/../../../perl5/bin/localenv-bashrc

export PATH=$PERL_DIR/bin:$PATH
export PERL5LIB=$PERL_DIR/lib:$PERL5LIB

source "$SCRIPT_DIR"/check_update.sh

source "$SCRIPT_DIR"/setup.sh
setup_upgrade

source "$SCRIPT_DIR"/guide.sh

source "$SCRIPT_DIR"/status.sh
check_status_tasks

if [ -z "$SETUP" ]; then
	source "$SCRIPT_DIR"/set_env.sh
	for P in "$SCRIPT_DIR"/grs/*.sh; do
		source "$P"
	done
	piwik_call
fi

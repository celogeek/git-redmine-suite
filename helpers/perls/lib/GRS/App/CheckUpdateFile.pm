package GRS::App::CheckUpdateFile;

# ABSTRACT: Return the update file check

=head1 DESCRIPTION

One check per day

=cut

# VERSION

use Moo::Role;
use DateTime;

sub app {

    return "/tmp/redmine.check_update." . DateTime->now->ymd('');

}
1;

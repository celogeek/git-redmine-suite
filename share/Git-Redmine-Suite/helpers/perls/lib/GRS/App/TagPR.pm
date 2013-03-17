package GRS::App::TagPR;

# ABSTRACT: return a tag pr for the review

=head1 DESCRIPTION

return a tag pr for the review

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use DateTime;

with 'GRS::Role::Name';

sub required_options {'name'}

sub app {
    my ($self) = @_;

    my $d = DateTime->now( time_zone => 'UTC' );
    return "pr-", $d->ymd(''), $d->hms(''), "-", $self->name;
}
1;

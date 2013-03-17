package GRS::App::TagVersion;

# ABSTRACT: return a tag version for the changelog

=head1 DESCRIPTION

return a tag version for the changelog

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use DateTime;

with 'GRS::Role::Version';

sub required_options {'version'}

sub app {
    my ($self) = @_;

    my $d = DateTime->now( time_zone => 'UTC' );
    return $self->version, "  ", $d->ymd('-'), " ", $d->hms(':'), " GMT";
}
1;

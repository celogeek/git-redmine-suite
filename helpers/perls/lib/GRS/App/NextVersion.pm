package GRS::App::NextVersion;

# ABSTRACT: Return Next Version

=head1 DESCRIPTION

Take a version and return the next version

Handle Date Version format

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use Version::Next;
use DateTime;

with 'GRS::Role::Version';

sub required_options {'version'}

sub app {
    my ($self) = @_;
    my $version = $self->version;
    if ( my ($date) = ( $version =~ /^(\d{8})_\d+$/ ) ) {
        my $dt = DateTime->now;
        if ( $date < $dt->ymd('') ) {
            $version = $dt->ymd('') . '_00';
        }
    }
    return Version::Next::next_version($version);
}
1;

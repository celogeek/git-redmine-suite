package GRS::Role::PrioColor;
# ABSTRACT: Prio Color role
=head1 DESCRIPTION

Prio Color role

=cut

# VERSION

use Moo::Role;
use MooX::Options;

has prio_color => (
    is => 'ro',
    coerce => sub {
        my ($color_settings) = @_;
        return $color_settings if ref $color_settings eq 'HASH';
        my %settings = map { split /=/ } split /:/, lc($color_settings);
        return \%settings;
    },
    default => sub { $ENV{REDMINE_PRIO_COLOR} // {} },
);

1;
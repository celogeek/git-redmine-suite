package GRS::Role::PrioColor;
# ABSTRACT: Prio Color role
=head1 DESCRIPTION

Prio Color role

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use IO::Interactive qw/is_interactive/;

has prio_color => (
    is => 'ro',
    coerce => sub {
        my ($color_settings) = @_;
        return $color_settings if ref $color_settings eq 'HASH';
        return {} if ! is_interactive;
        my %settings = map { split /=/ } split /:/, lc($color_settings);
        return \%settings;
    },
    default => sub { $ENV{REDMINE_PRIO_COLOR} // {} },
);

sub in_color {
	my ($self, $name, $str) = @_;
	return $str if ! is_interactive;
	my $color = $self->prio_color->{lc($name)} // 0;
	return "\033[".$color."m" . $str . "\033[0m";
}

1;
package GRS::App::DeltaDateCheck;
# ABSTRACT: Check if a date is greater than a number of days

# VERSION

use Moo::Role;
use MooX::Options;
use DateTime;
use Carp;
use feature 'say';

option 'date' => (
	is => 'ro',
	required => 1,
	doc => 'Date to test',
	format => 'i',
);

option 'days' => (
	is => 'ro',
	required => 1,
	doc => 'Number of days to add to your date before comparing to now',
	format => 'i',
);

sub app {
    my ($self) = @_;
    my ($y, $m, $d) = $self->date =~ /^(\d{4})(\d{2})(\d{2})$/;
    croak "Bad date" unless defined $y && defined $m && defined $d;

    my $from = DateTime->new(year => $y, month => $m, day => $d)->add(days => $self->days);
    my $to   = DateTime->now->truncate(to => 'day');
    return $to->compare($from) >= 0;
}

1;
package GRS::App::isValidHours;
# ABSTRACT: Check hours
=head1 DESCRIPTION

Check hours

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'hours' => (
	is => 'ro',
	required => 1,
	doc => 'hours to check',
	format => 's',
);

sub app {
  	my ($self) = @_;  
    return $self->hours =~ /^\d+(\.\d+)?$/

}
1;
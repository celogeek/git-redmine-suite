package GRS::Role::Notes;
# ABSTRACT: Notes for the task
=head1 DESCRIPTION

Notes

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'notes' => (
		is => 'ro',
		doc => 'notes of a task',
		format => 's',
);
1;
package GRS::Role::Progress;
# ABSTRACT: Progress of a task
=head1 DESCRIPTION

Progress

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use Carp;

option 'progress' => (
    is => 'ro',
    doc => 'progress of a task',
    format => 'i',
    isa => sub {
      croak "progress is a pourcentage between 0 to 100" unless $_[0] >= 0 && $_[0] <= 100; 
    }
);
1;
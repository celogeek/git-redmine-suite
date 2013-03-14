package GRS::Role::TaskID;

# ABSTRACT: Task ID

=head1 DESCRIPTION

The ID of the task

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'task_id' => (
    is     => 'ro',
    doc    => 'ID of the task',
    format => 'i',
);
1;

package GRS::Role::Project;

# ABSTRACT: Project slug or ID

=head1 DESCRIPTION

The ID of the project

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'project' => (
    is     => 'ro',
    doc    => 'ID or slug of the project',
    format => 's',
);
1;

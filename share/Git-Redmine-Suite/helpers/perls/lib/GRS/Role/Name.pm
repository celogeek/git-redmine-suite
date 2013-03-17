package GRS::Role::Name;

# ABSTRACT: Name paramater

=head1 DESCRIPTION

Name parameter

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option "name" => (
    is     => 'ro',
    format => 's',
    doc    => 'Name'
);

1;

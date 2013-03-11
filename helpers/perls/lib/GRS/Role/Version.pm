package GRS::Role::Version;

# ABSTRACT: Version paramater

=head1 DESCRIPTION

Version parameter

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option "version" => (
    is     => 'ro',
    format => 's',
    doc    => 'Version number'
);

1;

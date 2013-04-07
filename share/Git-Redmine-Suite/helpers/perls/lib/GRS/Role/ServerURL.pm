package GRS::Role::ServerURL;
# ABSTRACT: Server URL params

# VERSION

use Moo::Role;
use MooX::Options;


option 'server_url' => (
    is      => 'ro',
    format  => 's',
    default => sub { $ENV{REDMINE_URL} },
    doc     => 'the redmine url of the server',
);

1;
package GRS::App::Statuses;
# ABSTRACT: Return the list of statuses
=head1 DESCRIPTION

Return the list of statuses

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API';

sub required_options {qw/server_url auth_key/}

sub app {
    my ( $self, $progress ) = @_;

    return
        map { [ @$_{qw/id name/} ] }
        $self->API_fetchAll( 'issue_statuses');
}

1;
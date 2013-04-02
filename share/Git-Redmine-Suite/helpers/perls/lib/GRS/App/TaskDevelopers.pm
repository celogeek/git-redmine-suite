package GRS::App::TaskDevelopers;

# ABSTRACT: Return the list of developers who has participate to the dev

=head1 DESCRIPTION

Return the list of developers who has participate to the dev

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::TaskID', 'GRS::Role::StatusIDS',
    'GRS::Role::IDSOnly', 'GRS::Role::Developers';

sub required_options {
    qw/server_url auth_key task_id status_ids/;
}

sub app {
    my ($self) = @_;

    my $id = $self->task_id;
    my $resp = $self->API->issues->issue->get( $id, include => 'journals' );

    my $sep        = $self->ids_only ? ' ' : ', ';

    my @res = $self->get_developers($resp->content->{issue}->{journals}, $self->status_ids, $self->ids_only);

    return join( $sep, @res );
}
1;

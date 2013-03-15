package GRS::App::CheckTask;

# ABSTRACT: Check Task app

=head1 DESCRIPTION

Verify the status of a task

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use utf8::all;
use feature 'say';

with 'GRS::Role::API', 'GRS::Role::TaskID', 'GRS::Role::AssignedToID',
    'GRS::Role::StatusIDS';

option 'message' => (
    is      => 'ro',
    format  => 's',
    default => sub {'DEFAULT'},
    doc     => 'message if fail',
);

sub required_options {
    qw/server_url auth_key assigned_to_id status_ids/;
}

sub app {
    my ($self) = @_;

    my $id         = $self->task_id;
    my @status_ids = @{ $self->status_ids };
    my $resp       = $self->API->issues->issue->get($id);
    my $issue      = $resp->content->{issue};
    my $is_valid   = $issue->{assigned_to}
        && $issue->{assigned_to}->{id} eq $self->assigned_to_id;

    my $is_status_valid = 0;

    if ($is_valid) {
        for my $status_id (@status_ids) {
            $is_status_valid = 1 if ( $status_id eq $issue->{status}->{id} );
        }
    }

    $is_valid = 0 if !$is_status_valid;

    if ( !$is_valid ) {
        if ( $self->message eq 'DEFAULT' ) {
            my $assigned_to
                = $issue->{assigned_to}
                ? $issue->{assigned_to}->{name}
                : 'nobody';

            my $status = $issue->{status}->{name};

            return $self->default_message( $assigned_to, $status );
        }
        else {
            return $self->message;
        }
    }

    return;
}

sub default_message {
    my ( $self, $assigned_to, $status ) = @_;

    return <<__EOF__

I can't update this task. It is assigned to "$assigned_to" and as the status "$status".

Please ask your manager or an administrator to change the status in redmine.

__EOF__
}

1;

package GRS::App::TaskSub;

# ABSTRACT: Return or create a subtask

=head1 DESCRIPTION

Return or create a subtask

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use DateTime;
use Date::Parse;

with 'GRS::Role::API', 'GRS::Role::TaskID', 'GRS::Role::CFFilter', 'GRS::Role::CFSet', 'GRS::Role::StatusIDS', 'GRS::Role::AssignedToID';

sub required_options {qw/server_url auth_key task_id status_ids cf_id cf_val assigned_to_id/}

sub app {
    my ($self) = @_;

    my $issue = $self->API->issues->issue->get( $self->task_id,
        include => 'custom_fields,children' )->content->{issue};

    my @issues = $self->cf_filter(@{$issue->{children}});

    my $task_id;
    if (@issues) {
        $task_id = $issues[0]->{id};
    } else {
        $task_id = $self->_create_subtask($issue);
    }

    return $self, $task_id;
}

sub _create_subtask {
    my ($self, $issue) = @_;

    my ($server, $path) = split(/:/, $self->cf_val, 2);
    $path =~ s/\.git$//;

    my %create = (
        project_id => $issue->{project}->{id},
        tracker_id => $issue->{tracker}->{id},
        priority_id => $issue->{priority}->{id},
        status_id => $self->status_ids->[0],
        assigned_to_id => $self->assigned_to_id,
        subject => "[$path] " . $issue->{subject},
        description => 'subtask for the repos : ' . $self->cf_val,
        parent_issue_id => $self->task_id,
        custom_fields => [
            {"value" => $self->cf_val, "id" => $self->cf_id},
        ],
    );

    my $subissue = $self->API->issues->issue->create(%create);
    return unless defined $subissue;

    return $subissue->content->{issue}->{id};
}

1;

package GRS::App::TaskUpdate;

# ABSTRACT: Update a task

=head1 DESCRIPTION

Update a task

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::StatusIDS', 'GRS::Role::TaskID',
    'GRS::Role::Notes', 'GRS::Role::Progress', 'GRS::Role::CFSet',
    'GRS::Role::AssignedToID';

sub required_options { qw/server_url auth_key task_id/}

sub app {
    my ($self) = @_;

    my %update;
    $update{status_id} = $self->status_ids->[0] if $self->status_ids;
    $update{assigned_to_id} = $self->assigned_to_id if $self->assigned_to_id;
    $update{notes} = $self->notes if $self->notes;
    $update{done_ratio} = $self->progress if $self->progress;
    if (defined $self->cf_id && defined $self->cf_val) {
      $update{custom_fields} = [{id => $self->cf_id, value => $self->cf_val}];
  }
  return $self->API->issues->issue->update($self->task_id, %update);
}

1;

package GRS::App::TaskTime;
# ABSTRACT: Save a time entry
=head1 DESCRIPTION

Save a time entry

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::TaskID', 'GRS::Role::Notes';

sub required_options { qw/server_url auth_key task_id/ }

option 'hours' => (
	is => 'ro',
	required => 1,
	doc => 'number of hours spent on the task',
	format => 'f',
);

sub app {
	my ($self) = @_;
	my %create = (
		issue_id => $self->task_id,
		hours => $self->hours,
	);

	$create{comments} = $self->notes if $self->notes;

	$self->API->time_entries->time_entry->create(%create);
}
1;
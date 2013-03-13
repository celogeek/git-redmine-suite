package GRS::App::TaskList;

# ABSTRACT: List tasks

=head1 DESCRIPTION

List tasks

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use feature 'say';
use Term::Size 'chars';
use DateTime;
use Date::Parse;

with 'GRS::Role::API', 'GRS::Role::Project', 'GRS::Role::StatusIDS',
    'GRS::Role::AssignedToID', 'GRS::Role::IDSOnly', 'GRS::Role::CFSet';

sub required_options {qw/server_url auth_key/}

sub app {
    my ($self) = @_;

    my $progress = "." unless $self->ids_only;

    my %search;
    $search{status_id}      = $self->status_ids->[0] if $self->status_ids;
    $search{project_id}     = $self->project         if $self->project;
    $search{assigned_to_id} = $self->assigned_to_id  if $self->assigned_to_id;
    if ( $self->cf_id && $self->cf_val ) {
        $search{ 'cf_' . $self->cf_id } = $self->cf_val;
    }

    my ($columns) = chars;
    $columns ||= 80;

    print "List of tasks " unless $self->ids_only;

    my @issues = $self->API_fetchAll( 'issues', \%search, $progress );

    if ( $self->ids_only ) {
        say for sort { $a <=> $b } map { $_->{id} } @issues;
    }

    $self->_issue_add($_) for @issues;

    $self->_fetch_missing_tasks;

    $self->_compute_oldest_updated_on;

    for my $identifier ( sort { $a cmp $b } keys %{ $self->_projects } ) {
        say "[$identifier]";
        my $prj = $self->_projects->{$identifier};
        my $tasks = $prj->{tasks};
        my $parent = $prj->{parent};
        my %flip_parent;
        for my $task_id(keys %$parent) {
        	my $parent_id = $parent->{$task_id};
        	$flip_parent{$parent_id} //= [];
        	push @{$flip_parent{$parent_id}}, $task_id;
        }
        $self->_display_tree(
        	level => 0,
        	parent_id => 0,
        	flip_parent => \%flip_parent,
        	tasks => $tasks,
        	columns => $columns,
        );
        say "";
    }
}

has '_projects' => (
    is      => 'ro',
    default => sub { {} }
);

sub _issue_add {
    my ( $self, $issue ) = @_;

    my $task_id    = $issue->{id};
    my $parent_id  = $issue->{parent}->{id} // 0;
    my $identifier = $issue->{project}->{identifier};
    my $updated_on = str2time( $issue->{updated_on} );
    my $title      = join( "",
        $issue->{tracker}->{name},
        " # ", $task_id, " : ", $issue->{subject} );
    my $assigned_to = $issue->{assigned_to}->{name} // 'nobody';

    my $prj = (
        $self->_projects->{$identifier} //= {
            tasks  => {},
            parent => {},
        }
    );

    $prj->{tasks}->{$task_id} = {
        title       => $title,
        assigned_to => $assigned_to,
        updated_on  => $updated_on
    };
    $prj->{parent}->{$task_id} = $parent_id;

    return;
}

sub _fetch_missing_tasks {
    my ($self) = @_;
    for my $prj ( values %{ $self->_projects } ) {
        my ( $tasks, $parent ) = @$prj{qw/tasks parent/};
        foreach my $task_id ( keys %$parent ) {
            my $parent_id = $task_id;
            while ($parent_id) {
                $parent_id = $parent->{$parent_id};
                if ( $parent_id && !$tasks->{$parent_id} ) {
                    $self->_issue_add(
                        $self->API->issues->issue->get($parent_id)
                            ->content->{issue} );
                }
            }
        }
    }
}

sub _compute_oldest_updated_on {
    my ($self) = @_;
    for my $prj ( values %{ $self->_projects } ) {
        my ( $tasks, $parent ) = @$prj{qw/tasks parent/};
        foreach my $task_id ( keys %$parent ) {
            my $parent_id  = $task_id;
            my $updated_on = $tasks->{$task_id}->{updated_on};
            while ($parent_id) {
                $tasks->{$parent_id}->{oldest_updated_on} //=
                    $tasks->{$parent_id}->{updated_on};
                if ( $tasks->{$parent_id}->{oldest_updated_on} > $updated_on )
                {
                    $tasks->{$parent_id}->{oldest_updated_on} = $updated_on;
                }
                else {
                    $updated_on = $tasks->{$parent_id}->{oldest_updated_on};
                }
                $parent_id = $parent->{$parent_id};
            }
        }
    }
}

sub _display_tree {
	my ($self, %p) = @_;

    my $TRIANGLE = "\x{25B8}";
    my $tab = "  " x ( $p{level} );

	for my $task_id(sort { $p{tasks}{$a}{oldest_updated_on} <=> $p{tasks}{$b}{oldest_updated_on} } @{$p{flip_parent}{$p{parent_id}}}) {
        say $self->_format_str($p{columns}, "  " . $tab . $TRIANGLE . " ", $p{tasks}{$task_id}{title}, $p{tasks}{$task_id}{assigned_to}, $p{tasks}{$task_id}{oldest_updated_on});
		if ($p{flip_parent}{$task_id}) {
			$self->_display_tree(
				%p,
				level => $p{level} + 1,
				parent_id => $task_id,
			);
		}
	}

}

sub _trunc_str {
    my ($self, $str, $max) = @_;
    if (length($str) > $max) {
        return substr($str, 0, $max - 4) . ' ...';
    } else {
        return $str;
    }
}
sub _format_str {
    my ($self, $columns, $pad, $title, $assigned_to, $updated_on) = @_;
    $assigned_to //= 'nobody';
    my $date_str = DateTime->from_epoch(epoch => $updated_on)->strftime('%Y/%m/%d %H:%M');
    my $mtitle = $columns - 41;
    $mtitle = length($pad) + 20 if $mtitle < length($pad) + 20;
    my $format_str = "%-" . ($mtitle) . "s [ %15s ] [ %s ]";

    return sprintf($format_str, $self->_trunc_str($pad . $title, $mtitle), $self->_trunc_str($assigned_to, 15), $date_str);
}


1;

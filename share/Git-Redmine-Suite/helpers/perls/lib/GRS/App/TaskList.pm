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
    'GRS::Role::AssignedToID', 'GRS::Role::IDSOnly', 'GRS::Role::CFSet',
    'GRS::Role::CFFilter',
    'GRS::Role::ProjectFullName', 'GRS::Role::PrioColor', 'GRS::Role::TaskID';

has '_max_assigned_to' => (
    is      => 'rw',
    default => sub {0},
);

has '_max_priority' => (
    is      => 'rw',
    default => sub {0},
);

has '_max_tracker' => (
    is      => 'rw',
    default => sub {0},
);

has '_projects' => (
    is      => 'ro',
    default => sub { {} }
);

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

    my @issues = $self->API_fetchAll( 'issues', \%search, $progress,
        $self->can('cf_filter') );

    if ( $self->ids_only ) {
        say for sort { $a <=> $b } map { $_->{id} } @issues;
        return;
    }

    $self->_issue_add($_) for @issues;

    $self->_fetch_missing_tasks;

    $self->_compute_oldest_updated_on;

    for my $identifier ( sort { $a cmp $b } keys %{ $self->_projects } ) {
        my $prj = $self->_projects->{$identifier};

        my $tasks  = $prj->{tasks};
        my $parent = $prj->{parent};
        my %flip_parent;
        for my $task_id ( keys %$parent ) {
            my $parent_id = $parent->{$task_id};
            $flip_parent{$parent_id} //= [];
            push @{ $flip_parent{$parent_id} }, $task_id;
        }

        if ( exists $flip_parent{ $self->task_id // 0 } ) {
            say "[", $self->project_fullname( $prj->{id} ), "]";

            $self->_display_tree(
                level       => 0,
                parent_id   => $self->task_id // 0,
                flip_parent => \%flip_parent,
                tasks       => $tasks,
                columns     => $columns,
            );
            say "";
        }
    }
}

sub _issue_add {
    my ( $self, $issue, %options ) = @_;

    my $task_id      = $issue->{id};
    my $tracker_name = $issue->{tracker}->{name};
    $self->_max_tracker( length($tracker_name) )
        if length($tracker_name) > $self->_max_tracker;

    my $parent_id = $issue->{parent}->{id} // 0;
    my $identifier
        = $options{missing}
        ? $options{missing}
        : $issue->{project}->{identifier};
    my $updated_on = str2time( $issue->{updated_on} );

    my $priority = $issue->{priority}->{name} // "Regular";
    $self->_max_priority( length($priority) )
        if length($priority) > $self->_max_priority;

    my $title;
    if ( $options{missing} ) {
        $title = $issue->{subject};
    }
    else {
        $title = join( "", "# ", $task_id, " : ", $issue->{subject} );
    }
    my $assigned_to = $issue->{assigned_to}->{name} // 'nobody';
    $self->_max_assigned_to( length($assigned_to) )
        if length($assigned_to) > $self->_max_assigned_to;

    my $prj = (
        $self->_projects->{$identifier} //= {
            tasks  => {},
            parent => {},
            id     => $issue->{project}->{id},
        }
    );

    $prj->{tasks}->{$task_id} = {
        id          => $task_id,
        tracker     => $tracker_name,
        title       => $title,
        assigned_to => $assigned_to,
        updated_on  => $updated_on,
        priority    => $priority,
    };
    $prj->{parent}->{$task_id} = $parent_id;

    return;
}

sub _fetch_missing_tasks {
    my ($self) = @_;
    for my $identifier ( keys %{ $self->_projects } ) {
        my $prj = $self->_projects->{$identifier};
        my ( $tasks, $parent ) = @$prj{qw/tasks parent/};
        foreach my $task_id ( keys %$parent ) {
            my $parent_id = my $prev_parent_id = $task_id;
            while ($parent_id) {
                $prev_parent_id = $parent_id;
                $parent_id = $parent->{$parent_id};
                if ( $parent_id && !$tasks->{$parent_id} ) {
                    my $issue;
                    if (eval {
                        $issue = $self->API->issues->issue->get($parent_id)
                            ->content->{issue}; 1
                    }) {
                        $self->_issue_add(
                            $issue,
                            missing => $identifier,
                        );
                    } else { 
                        $parent_id = $parent->{$prev_parent_id} = 0;
                    };
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
    my ( $self, %p ) = @_;

    my $TRIANGLE = "\x{25B8}";
    my $tab = "  " x ( $p{level} );

    if ( !$p{level} && $p{parent_id} ) {
        $self->_display_task(
            $p{columns},
            "  " . $tab . $TRIANGLE . " ",
            $p{tasks}{$p{parent_id}}
        );

        $p{level} += 1;
        $tab = "  " x ( $p{level} );
    }

    for my $task_id (
        sort {
            $p{tasks}{$a}{oldest_updated_on}
                <=> $p{tasks}{$b}{oldest_updated_on}
        } @{ $p{flip_parent}{ $p{parent_id} } }
        )
    {

        $self->_display_task(
            $p{columns},
            "  " . $tab . $TRIANGLE . " ",
            $p{tasks}{$task_id}
        );

        if ( $p{flip_parent}{$task_id} ) {
            $self->_display_tree(
                %p,
                level     => $p{level} + 1,
                parent_id => $task_id,
            );
        }
    }

}

sub _trunc_str {
    my ( $self, $str, $max ) = @_;
    if ( length($str) > $max ) {
        return substr( $str, 0, $max - 4 ) . ' ...';
    }
    else {
        return $str;
    }
}

sub _center_str {
    my ( $self, $str, $size ) = @_;
    return $str if length($str) >= $size;
    my $left = int( ( $size - length($str) ) / 2 );
    return " " x $left . $str;
}

sub _format_str {
    my ( $self, $columns, $pad, $tracker, $title, $priority, $assigned_to,
        $updated_on )
        = @_;
    $assigned_to //= 'nobody';
    my $date_str = DateTime->from_epoch( epoch => $updated_on )
        ->strftime('%Y/%m/%d %H:%M');
    my $mtitle
        = $columns
        - length($date_str)
        - $self->_max_priority
        - $self->_max_assigned_to - 9;
    $mtitle = length($pad) + 20 if $mtitle < length($pad) + 20;
    my $format_str
        = "%-"
        . ($mtitle) . "s [%-"
        . $self->_max_priority
        . "s] [%-"
        . $self->_max_assigned_to
        . "s] [%16s]";
    return sprintf(
        $format_str,
        $self->_trunc_str(
            $pad
                . sprintf( "%-" . $self->_max_tracker . "s ", $tracker )
                . $title,
            $mtitle
        ),
        $self->_center_str( $priority,    $self->_max_priority ),
        $self->_center_str( $assigned_to, $self->_max_assigned_to ),
        $date_str
    );
}

sub _display_task {
    my ( $self, $columns, $prefix, $task ) = @_;

    say $self->in_color(
        $task->{priority},
        $self->_format_str(
            $columns,          $prefix,
            $task->{tracker},  $task->{title},
            $task->{priority}, $task->{assigned_to},
            $task->{oldest_updated_on},
        )
    );
}

1;

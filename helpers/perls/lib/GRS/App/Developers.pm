package GRS::App::Developers;

# ABSTRACT: Return the list of developers who has participate to the dev

=head1 DESCRIPTION

Return the list of developers who has participate to the dev

=cut

# VERSION

use Moo::Role;
use MooX::Options;

with 'GRS::Role::API', 'GRS::Role::TaskID', 'GRS::Role::StatusIDS',
    'GRS::Role::IDSOnly';

sub required_options {
    qw/task_id status_ids/;
}

sub app {
    my ($self) = @_;

    my $id = $self->task_id;
    my $resp = $self->API->issues->issue->get( $id, include => 'journals' );
    my @res;
    my $sep        = $self->ids_only ? ' ' : ', ';
    my @status_ids = @{ $self->status_ids };
    my $ids_only   = $self->ids_only;

    my @journals = sort { $b->{created_on} cmp $a->{created_on} }
        @{ $resp->content->{issue}->{journals} };

    my %uniq;
    for my $journal (@journals) {
        my $keep = 0;
        for my $details ( @{ $journal->{details} } ) {
            if (   $details->{name} eq 'status_id'
                && grep { $details->{new_value} eq $_ } @status_ids )
            {
                $keep = 1;
                last;
            }
        }
        next unless $keep;

        my $id   = $journal->{user}->{id};
        my $name = $journal->{user}->{name};
        push @res, $ids_only ? $id : $name if !$uniq{$id};
        $uniq{$id} = 1;
    }

    return join( $sep, @res );
}
1;

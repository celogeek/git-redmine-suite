package GRS::Role::Developers;

# ABSTRACT: Return the list of developer from a journal

# VERSION

use Moo::Role;

sub get_developers {
    my ( $self, $issue_journals, $issue_status_ids, $ids_only ) = @_;
    
    my @status_ids = @{$issue_status_ids // []};

    my @journals = sort { $b->{created_on} cmp $a->{created_on} }
      @{ $issue_journals // []};

    my @res;
    my %uniq;
    for my $journal (@journals) {
        my $keep = 0;
        for my $details ( @{ $journal->{details} } ) {
            if ( $details->{name} eq 'status_id'
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

    return @res;
}
1;

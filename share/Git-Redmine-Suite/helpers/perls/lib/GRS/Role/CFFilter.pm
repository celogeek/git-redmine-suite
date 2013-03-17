package GRS::Role::CFFilter;

# ABSTRACT: Filter all project / issue without the necessary CF

=head1 DESCRIPTION

Filter all project / issue without the necessary CF

=cut

# VERSION

use Moo::Role;
use List::MoreUtils qw/all/;

sub cf_filter {
    my ( $self, @data ) = @_;
    my @data_valid;

    for my $d (@data) {
        if ( $self->can('cf_id') && defined $self->cf_val ) {
            my %cf = map { ( $_->{id} => $_->{value} ) }
                @{ $d->{custom_fields} };

            push @data_valid, $d if 
            	defined $cf{$self->cf_id}
            	&& $cf{$self->cf_id} eq $self->cf_val;

        }
        else {
            my %cf
                = map { ( $_->{name} => $_->{id} ) } @{ $d->{custom_fields} };

            push @data_valid, $d
                if all {defined} @cf{qw/GIT_REPOS GIT_PR GIT_RELEASE/};
        }

    }

    return @data_valid;
}
1;

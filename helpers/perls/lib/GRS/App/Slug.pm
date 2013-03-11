package GRS::App::Slug;

# ABSTRACT: Slug a string

=head1 DESCRIPTION

Slug a string

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'this' =>
    ( is => 'ro', format => 's', required => 1, doc => 'String to slug' );

sub app {
	my ($self) = @_;

    my $slug = $self->this;
    $slug =~ s/[^a-zA-Z0-9]+/-/g;
    $slug = lc($slug);

    return $slug;
}
1;

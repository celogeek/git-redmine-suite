package GRS::App::MD5;

# ABSTRACT: abstract

=head1 DESCRIPTION

description

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use Digest::MD5;

option 'file' => (
	is => 'ro',
	required => 1,
	doc => 'file to check md5',
	format => 's',
);

sub app {
    my ($self) = @_;
    return "" if ! -e $self->file;

    my $ctx = Digest::MD5->new;
    open my $fh, "<", $self->file or return "";
    $ctx->addfile($fh);
    close $fh;

    return $ctx->hexdigest;
}
1;

package GRS::App::Profile;

# ABSTRACT: abstract

=head1 DESCRIPTION

description

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use LWP::UserAgent;
use DateTime;

option 'url' => (
  is => 'ro',
  required => 1,
  doc => 'url of the profile',
  format => 's',  
);

option 'skip_if_exists' => (
    is => 'ro',
    doc => 'if file exists, skip fetch',
);

sub app {
    my ($self) = @_;

    my $file = '/tmp/redmine.profile.' . DateTime->now->ymd('');
    return $file if -e $file && $self->skip_if_exists;

    open my $fh, ">", $file or die "fail to open $file for writing.";

    my $content
        = LWP::UserAgent->new->get(
          $self->url
        )->content;

    for my $c (split /[\r\n]/, $content) {
      $c =~ /^(.*?)\s+=\s+(.*)$/ or next;
      print $fh $c,"\n";
    }
    close $fh;

    return $file;
}
1;

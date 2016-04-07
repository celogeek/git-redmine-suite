package GRS::App::DiffURL;
# ABSTRACT: Return the diff url
=head1 DESCRIPTION

Return the diff url

=cut

# VERSION

use Moo::Role;
use MooX::Options;

option 'diff_url' => (
  is => 'ro',
  format => 's',
);

option 'git_remote_url' => (
  is => 'ro',
  format => 's',
  required => 1,
);

option 'ref_from' => (
  is => 'ro',
  format => 's',
  required => 1,
);

option 'ref_to' => (
  is => 'ro',
  format => 's',
  required => 1,
);

sub app {
  my ($self) = @_;
  return "" if !defined $self->diff_url;

  #extract path
  my ($user_and_server, $path) = split(/:/, $self->git_remote_url, 2);
  $path =~ s/\.git$//;

  my $proto = "";

  #check if proto
  if (substr($path, 0, 2) eq '//') {
    $proto = $user_and_server;
    ($user_and_server, $path) = $path =~ /^\/\/(.*?)(\/.*)$/;
  }

  #split user and server
  my ($user, $server) = split(/\@/, $user_and_server, 2);
  if (!defined $server) {
    $server = $user;
    $user = "";
  }


  my %token = (
    'PROTO' => $proto,
    'SERVER' => $server,
    'USER' => $user,
    'PATH' => $path,
    'REF_FROM' => $self->ref_from,
    'REF_TO' => $self->ref_to,
  );

  my $url = $self->diff_url;

  for my $key (keys %token) {
    my $val = $token{$key};

    $url =~ s/~$key~/$val/gix;
  }

  return $url;
}

1;
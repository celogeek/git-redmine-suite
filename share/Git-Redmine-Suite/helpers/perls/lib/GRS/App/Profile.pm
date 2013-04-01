package GRS::App::Profile;

# ABSTRACT: abstract

=head1 DESCRIPTION

description

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use LWP::Curl;
use File::MkTemp;

option 'url' => (
	is => 'ro',
	required => 1,
	doc => 'url of the profile',
	format => 's',	
);

sub app {
    my ($self) = @_;

    my ($fh, $file) = mkstempt('redmine_profile.XXXXXX', '/tmp');

    my $content
        = LWP::Curl->new->get(
        	$self->url
        );

    for my $c (split /[\r\n]/, $content) {
    	$c =~ /^(.*?)\s+=\s+(.*)$/ or next;
	    print $fh $c;
    }
    close $fh;

    return "/tmp/$file";
}
1;

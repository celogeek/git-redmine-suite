package GRS::App::Question;

# ABSTRACT: Question Role

=head1 DESCRIPTION

Ask question

=cut

# VERSION

use Moo::Role;
use MooX::Options;
use feature 'say';
use Term::ReadLine;

option 'question' => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'The question to ask'
);

sub app {
    my ($self)   = @_;
    my $question = $self->question;
    my $term     = Term::ReadLine->new('Question');
    my $prompt   = $question . " (y/N) ";
    my $answer;
    say "";
    while ( defined( $answer = $term->readline($prompt) ) ) {
        $answer = lc($answer);
        next if $answer && $answer !~ /^[yn]$/;
        $answer = undef if ( $answer eq 'n' );
        last;
    }
    say "";
    return !!$answer;
}

1;

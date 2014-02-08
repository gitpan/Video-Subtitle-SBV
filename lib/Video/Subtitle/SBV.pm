=head1 Video::Subtitle::SBV

=head2 NAME

Video::Subtitle::SBV - read and write SBV format (YouTube) subtitle files

=head2 SYNOPSIS

     my $subtitles = Video::Subtitle::SBV->new ();
     $subtitles->parse_file ('subtitles.txt');
     $subtitles->add ({start => '00:00:22.010',
                       end => '00:00:26.020',
                       text => 'Bad city, bad bad city, fat city bad'});
     $subtitles->write_file ('subtitles.sbv');

=over

=item UTF-8

Input subtitle text files must be either ASCII or text encoded using
UTF-8. Output is in UTF-8.

=back

=cut

package Video::Subtitle::SBV;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/validate_time validate_subtitle time_to_milliseconds/;
use warnings;
use strict;
use Carp;
use autodie;
our $VERSION = 0.04;

=head1 FUNCTIONS

=head2 validate_time

    use Video::Subtitle::SBV 'validate_time';
    if (validate_time ('00:00:01.010')) {
        print "Time is valid.\n";
    }

Check whether a subtitle contains a valid time string or not.

=cut

# This regular expression is for parsing times

my $time_re = qr/(\d{1,2}):(\d{2}):(\d{2})\.(\d{0,3})/;

sub validate_time
{
    my ($time) = @_;
    my $status;
    if ($time =~ $time_re) {
        my ($minutes, $seconds) = ($2, $3);
        if ($minutes < 60 && $seconds < 60) {
            $status = 1;
        }
    }
    return $status;
}

=head2 time_to_milliseconds

     use Video::Subtitles::SBV 'time_to_milliseconds';
     my $ms_time = time_to_milliseconds ('00:00:01.010');
     # $ms_time = 1010

If the input is not a valid time, it returns the undefined value.

=cut

sub time_to_milliseconds
{
    my ($time) = @_;
    my $ms;
    if ($time =~ $time_re) {
        my ($hours, $minutes, $seconds, $milliseconds) = ($1, $2, $3, $4);
        if (! defined $milliseconds) {
            $milliseconds = 0;
        }
        $minutes += $hours * 60;
        $seconds += $minutes * 60;
        $milliseconds += $seconds * 1000;
        $ms = $milliseconds;
    }
    return $ms;
}

=head2 validate_subtitle

    use Video::Subtitle::SBV 'validate_subtitle';
    if (validate_subtitle ($my_title)) {
        print "Subtitle is valid.\n";
    }

This routine checks whether the hash reference stored in C<$my_title>
is a valid entry which can be given to the L<add> method. The L<add>
method uses this to validate its input, and it is also available as a
standalone routine exported on request.

You can also use a second argument to make it print out the reason why
the subtitle is invalid:

    validate_subtitle ($my_title, 1);

Any "true" value will make it print out the reason.

=cut

sub validate_subtitle
{
    my ($subtitle, $verbose) = @_;
    my $validity;
    my $location;
    if ($verbose) {
        if ($subtitle->{file} && $subtitle->{line}) {
            $location = "$subtitle->{file}:$subtitle->{line}: ";
        }
        else {
            $location = '';
        }
    }
    if (ref $subtitle ne 'HASH') {
        if ($verbose) {
            carp "$location\$subtitle is not a hash reference";
        }
        goto invalid;
    }
    for my $key (qw/start end text/) {
        if (! $subtitle->{$key}) {
            if ($verbose) {
                carp "$location\$subtitle does not have required information '$key'";
            }
            goto invalid;
        }
    }
    for my $key (qw/start end/) {
        my $time = $subtitle->{$key};
        if ($time !~ $time_re) {
            if ($verbose) {
                carp "$location\$subtitle $key time '$time' is not a valid time";
            }
            goto invalid;
        }
    }
    $validity = 1;

invalid:
    return $validity;
}

=head1 METHODS

=head2 new

    my $subtitles = Video::Subtitle::SBV->new ();

Create an object which will contain the subtitles you create.

=cut

sub new
{
    my $subtitles = {};

    # "list" is the list of subtitles. This is accessed by using
    # "parse_file" or "add".

    $subtitles->{list} = [];

    # "verbosity" controls whether to print error messages on
    # encountering errors. This is accessed by using "set_verbosity".

    $subtitles->{verbosity} = undef;
    bless $subtitles;
    return $subtitles;
}

=head2 set_verbosity

    $subtitles->set_verbosity ('yes');

Give this function any true value to make it print error messages. Set
to any false value to stop printing the error messages.

If this is not switched on, the routine will silently ignore
ill-formated inputs.

=cut

sub set_verbosity
{
    my ($subtitles, $verbosity) = @_;
    $subtitles->{verbosity} = $verbosity;
}

# Add a new subtitle to the list of subtitles. This is a private
# method.

sub add_subtitle
{
    my ($subtitles) = @_;
    my $subtitle = {};
    push @{$subtitles->{list}}, $subtitle;
    return $subtitle;
}

=head2 parse_file

    $subtitles->parse_file ('subtitles.txt');

Read in a file of subtitles in the SBV format.

=cut

sub parse_file
{
    my ($subtitles, $file_name) = @_;
    open my $input, "<:encoding(utf8)", $file_name;
    my $subtitle;
    my $text = '';
    while (<$input>) {
        if (/^($time_re),($time_re)\s*$/) {
            $subtitle = add_subtitle ($subtitles);
            $subtitle->{start} = $1;
            $subtitle->{end} = $6;
            $subtitle->{file} = $file_name;
            $subtitle->{line} = $.;
        }
        elsif (/\S/) {
            if ($subtitle->{finished}) {
                if ($subtitles->{verbosity}) {
                    carp "$file_name:$.: subtitle text without a valid start/end time\n";
                }
            }
            else {
                $subtitle->{text} .= $_;
            }
        }
        # Otherwise it is a blank line, which means the end of the subtitle.
        else {
            $subtitle->{finished} = 1;
        }
    }
    close $input;
}

=head2 add

    $subtitles->add ({start => '00:00:22.010',
                      end => '00:00:26.020',
                      text => 'Bad city, bad bad city, fat city bad'});

Add a subtitle to the file. You can have more than one subtitle in the
list.

=cut

sub add
{
    my ($subtitles, @title_list) = @_;
    for my $subtitle (@title_list) {
        if (validate_subtitle ($subtitle, $subtitles->{verbosity})) {
            push @{$subtitles->{list}}, $subtitle;
        }
    }
}

=head2 write_file

    $subtitles->write_file ('subtitles.sbv');

Write the stored subtitles in C<$subtitles> to the specified file.

If this method is called without an argument, it prints the subtitles
to standard output:

    $subtitles->write_file ();

=cut

sub write_file
{
    my ($subtitles, $file_name) = @_;
    my $output;
    my $old_fh;
    if (! $file_name) {
        binmode STDOUT, ":utf8";
    }
    else {
        open $output, ">:encoding(utf8)", $file_name;
        $old_fh = select $output;
    }
    for my $subtitle (@{$subtitles->{list}}) {
        print <<EOF;
$subtitle->{start},$subtitle->{end}
$subtitle->{text}
EOF
        # Sometimes $subtitle->{text} may not have an ending newline
        # if it is added via the "add" method, so we need to print
        # another one to get the required blank line.
        if ($subtitle->{text} !~ /\n\h*$/) {
            print "\n";
        }
    }
    if ($file_name) {
        close $output;
        select $old_fh;
    }
}

1;

=head1 BUGS

=over

=item SBV format specification

I'm not too sure where the SBV format is actually specified, so the
methods in this module are based on looking at examples of the format.
That means that some details, such as whether it is compulsory to have
a milliseconds field in the times, or whether it is necessary to have
a blank line at the end of each subtitle, are just guesses.

=item Speaker field

SBV allows for a "speaker" field, specified by ">>", but this module
doesn't do anything special with that field.

=item Video::Subtitle

I named this "Video::Subtitle::SBV" because there is an existing
module called L<Video::Subtitle::SRT>, just to be consistent. However,
"Video::SubtitleB<s>" with an S would be a better name.

=back

=head1 AUTHOR

Ben Bullock, bkb@cpan.org

=head1 LICENCE

You can use, modify and redistribute this software library under the
standard Perl licences (Gnu General Public Licence or Artistic
licence).


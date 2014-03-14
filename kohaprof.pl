#!/usr/bin/perl 

# Copyright 2014 Magnus Enger Libriotech

=head1 NAME

run_tests.pl - Go back in Git-time, then walk towards the present and run 
performance tests for each new commit.

=head1 SYNOPSIS

    perl run_tests.pl -c myconfig.yaml -v > /tmp/kohaprof.html

=head1 DESCRIPTION

This script uses a git repo and a Koha instance running off that Git repo. It 
will step x commits back in time, run some tests/benchmarks against the 
insallation, step one commit forward in time, run the tests again, step forward, 
run the tests an so on, until it reaches the most recent commit. 

Several iterations of the tests can be done per commit, and the times measured
for each iteration will be averaged. 

Output is done as an HTML file, which shows a table of the average times for 
each commit and test. The oldest commit is shown at the top and the newest 
commit is at the bottom. 

=head1 CONFIGURATION

The configuration is stored in a YAML file, see that default-config.yaml that
accompanies this script for an example. 

=cut

use Getopt::Long;
use Data::Dumper;
use Pod::Usage;
use YAML::Syck;
use DateTime;
use FindBin;
use Git::Wrapper;
use WWW::Mechanize::Timed;
use Math::NumberCruncher;
use Template;
use Modern::Perl;

# Get options
my ( $config_file, $verbose, $debug ) = get_options();

# Read the config
if ( $config_file eq '' ) {
    $config_file = $FindBin::Bin . '/default-config.yaml';
}

my $config = LoadFile( $config_file );
say STDERR Dumper $config if $debug;

# Define URLs to test - more should be added
my %urls = (
    'opac' => $config->{ 'opac' }, 
    'opac_detail' => $config->{ 'opac' } . 'cgi-bin/koha/opac-detail.pl?biblionumber=' . $config->{ 'opac_biblionumber' },
    'intra' => $config->{ 'intranet' },
);

# Set up the timer
# FIXME Login to the intranet
my $timer = WWW::Mechanize::Timed->new();

# Connect to the repo
my $git = Git::Wrapper->new( $config->{'repo'} );
$git->checkout( $config->{'branch'} );

# Get the commits we want and walk through them
my @shas = $git->rev_list( { max_count => $config->{'max_count'} }, 'HEAD' );
my @results;
while ( @shas ) {

    # Get the SHA of the current 
    my $sha = pop @shas;
    say STDERR $sha if $verbose;
    # Check ut this SHA
    $git->checkout( $sha );

    # Run the timers
    my %iter_results;
    for ( 1..$config->{ 'iterations' } ) {

        # Loop over the URLs we want to test
        foreach my $key ( sort keys %urls ) {
            my $url = $urls{ $key };
            say STDERR "Looking at $key : $url" if $debug;
            # Access the URL
            $timer->get( $url );
            # FIXME IS it possible to set the method here based on the config?
            my $time = $timer->client_response_receive_time;
            say STDERR $time if $debug;
            # Save the time
            push @{ $iter_results{ $key } }, $time;
        }
        
    }
    
    # Summarize the results for all the runs on this SHA
    my %summary = ( 'sha' => $sha );
    foreach my $test ( sort keys %iter_results ) {
        my $average = Math::NumberCruncher::Mean( \@{ $iter_results{ $test } } );
        say STDERR "$test: $average" if $verbose;
        $summary{ $test } = $average;
    }
    push @results, \%summary;
    
}

# Configure and create Template Toolkit 
my $ttconfig = {
    INCLUDE_PATH => '',
    ENCODING => 'utf8' # ensure correct encoding
};
my $tt2 = Template->new( $ttconfig ) || die Template->error(), "\n";
$tt2->process( 'kohaprof.tt', { 'tests' => \@results, 'config' => $config } ) || die $tt2->error();

say STDERR Dumper \@results if $debug;

# Clean up
$git->checkout( 'master' );

=head1 OPTIONS

=over 4

=item B<-c --config>

Path to config file, if you want to use another config file than the defaul one.

=item B<-v --verbose>

More verbose output.

=item B<-d --debug>

Even more verbose output.

=item B<-h, -?, --help>

Prints this help message and exits.

=back
                                                               
=cut

sub get_options {

    # Options
    my $config_file = '';
    my $verbose     = '';
    my $debug       = '';
    my $help        = '';

    GetOptions (
        'c|config=s' => \$config_file,
        'v|verbose'  => \$verbose,
        'd|debug'    => \$debug,
        'h|?|help'   => \$help
    );

    pod2usage( -exitval => 0 ) if $help;

    return ( $config_file, $verbose, $debug );

}

=head1 AUTHOR

Magnus Enger

=head1 REPOSITORY

https://github.com/MagnusEnger/kohaprofile

Patches and pull requests are most welcome! 

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This file is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this file; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut

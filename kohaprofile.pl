#!/usr/bin/perl 

# Copyright 2014, Oslo Public Library

=head1 NAME

kohaprofile.pl - Go back in Git-time, then walk towards the present and run 
performance tests for each new commit.

=head1 SYNOPSIS

    perl kohaprofile.pl -c myconfig.yaml -v > /tmp/kohaprof.html

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
$tt2->process( 'kohaprofile.tt', { 'tests' => \@results, 'config' => $config } ) || die $tt2->error();

say STDERR Dumper \@results if $debug;

# Clean up
$git->checkout( 'master' );

=head1 OPTIONS

=over 4

=item B<-c --config>

Path to config file, if you want to use another config file than the default one.

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

=head1 LICENSE

This is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This script is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this script; if not, see <http://www.gnu.org/licenses>.

=cut

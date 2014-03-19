#!/usr/bin/perl 

# Copyright 2014, Oslo Public Library

=head1 NAME

kohaprofile.pl - Go back in Git-time, then walk towards the present and run 
performance tests for each new commit.

=head1 SYNOPSIS

    perl kohaprofile.pl -c myconfig.yaml -v > /tmp/kohaprof.html

=cut

use Dancer2;
use Dancer2::Plugin::DBIC;
use lib 'lib';

use Getopt::Long;
use Data::Dumper;
use Pod::Usage;
use YAML::Syck;
use DateTime;
use FindBin;
use Git::Wrapper;
use WWW::Mechanize::Timed;
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

# Record the run in the database
my $run = resultset('Run')->create({
    branch => $config->{'branch'},
});

# Get the commits we want and walk through them
my @shas = $git->rev_list( { max_count => $config->{'max_count'} }, 'HEAD' );
while ( @shas ) {

    # Get the SHA of the current commit
    my $sha = pop @shas;
    say STDERR $sha if $verbose;
    # Check ut this SHA
    $git->checkout( $sha );
    # Record the SHA in the database
    my $db_sha = resultset('Commit')->update_or_new({
        sha => $sha,
    });
    if (!$db_sha->in_storage) {
        # FIXME Get the title for the commit
        $db_sha->set_column( 'title', 'FIXME' );
        $db_sha->insert;
    }

    # Run the timers
    for ( 1..$config->{ 'iterations' } ) {

        # Loop over the URLs we want to test
        foreach my $test_name ( sort keys %urls ) {
            my $url = $urls{ $test_name };
            say STDERR "Looking at $test_name : $url" if $debug;
            # Access the URL
            $timer->get( $url );
            # Record each of the datapoints in the database
            foreach my $method ( qw( client_request_connect_time client_request_transmit_time client_response_server_time client_response_receive_time client_total_time client_elapsed_time ) ) {
                my $datapoint = resultset('Datapoint')->create({
                    run_id => $run->id,
                    sha    => $sha,
                    name   => $test_name,
                    method => $method,
                    value  => $timer->$method,
                });
                say STDERR "$method: " . $timer->$method if $debug;
            }
        }
        
    }
    
}

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

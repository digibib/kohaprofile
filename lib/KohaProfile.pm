package KohaProfile;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Serializer::JSON;
use Data::Dumper;

our $VERSION = '0.1';

get '/' => sub {
    my @runs = resultset('Run')->all;
    template 'index', { 'runs' => \@runs };
};

get '/run/:id/:method' => sub {
    
    my $run_id = param 'id';
    my $method = param 'method';
    
    my $run = resultset('Run')->find( $run_id );
    
    my @datapoints = _get_datapoints_for_run( $run_id, $method );
    my %prepared_datapoints;
    foreach my $dp ( @datapoints ) {
        $prepared_datapoints{ $dp->sha->sha }{ $dp->name } = $dp->get_column('avg_time');
    }
    
    template 'run', { 'run' => $run, 'datapoints' => \@datapoints, 'prepared_datapoints' => \%prepared_datapoints };
    
};

get '/api/run/:id/:method' => sub {
    
    my $run_id = param 'id';
    my $method = param 'method';
    
    # Get the data from the database
    my @datapoints = _get_datapoints_for_run( $run_id, $method );
    # Create a map from test names to an array of values
    my %names_and_values;
    foreach my $dp ( @datapoints ) {
        push @{ $names_and_values{ $dp->name } }, $dp->get_column('avg_time');
    }
    # Turn the previous data structure into an array of hashes, that Flot can consume
    my @array_of_hashes;
    foreach my $name ( sort keys %names_and_values ) {
        my %data;
        $data{ 'label' } = $name;
        my $counter = 0;
        foreach my $value ( @{ $names_and_values{ $name } } ) {
            my @point = ( $counter, $value );
            push @{ $data{ 'data' } }, \@point;
            $counter++;
        }
        push @array_of_hashes, \%data;
    }
    return to_json( \@array_of_hashes );
    
};

sub _get_datapoints_for_run {

    my ( $run_id, $method ) = @_;
    
    my @datapoints = resultset('Datapoint')->search({
        'run_id' => $run_id,
        'method' => $method,
    },{
        select   => [
            'sha',
            'name',
            { avg => 'value', -as => 'avg_time' }
        ],
        group_by => [qw/ sha name /],
    });
    
    return @datapoints;

}

true;

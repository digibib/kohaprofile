package KohaProfile;
use Dancer2;
use Dancer2::Plugin::DBIC;

our $VERSION = '0.1';

get '/' => sub {
    my @runs = resultset('Run')->all;
    template 'index', { 'runs' => \@runs };
};

get '/run/:id/:method' => sub {
    
    my $run_id = param 'id';
    my $method = param 'method';
    
    my $run = resultset('Run')->find( $run_id );
    
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
    my %prepared_datapoints;
    foreach my $dp ( @datapoints ) {
        $prepared_datapoints{ $dp->sha->sha }{ $dp->name } = $dp->get_column('avg_time');
    }
    
    template 'run', { 'run' => $run, 'datapoints' => \@datapoints, 'prepared_datapoints' => \%prepared_datapoints };
    
};

true;

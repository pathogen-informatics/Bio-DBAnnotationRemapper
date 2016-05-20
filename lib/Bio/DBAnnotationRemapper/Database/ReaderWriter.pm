package Bio::ChadoAnnotationRemapper::Chado::ReaderWriter;

# ABSTRACT: Extract features from a chado psql database with locations for a given organism

=head1 SYNOPSIS

Extract features with locations for a given organism
Each line of the form:

srcfeature.uniquename feature.uniquename feature.feature_id cvterm.name featureloc.fmin featureloc.fmax featureloc.strand featureloc.featureloc_id
=cut

use Moose;
use DBI;

has 'database_url'                  => ( is => 'ro', isa => 'Str',      default => 'path-live-db:5432/pathogens' );
has 'database_username'             => ( is => 'ro', isa => 'Str',      required => 1);
has 'database_password'             => ( is => 'ro', isa => 'Str',      required => 1);
has 'organism'                      => ( is => 'ro', isa => 'Str',      required => 1);
has 'parent_feature_types'           => ( is => 'ro', isa => 'Str',      default => 'chromosome, mitochondrial_chromosome, apicoplast_chromosome' ); 
has 'output_file'                   => ( is => 'ro', isa => 'Str', default => 'chado.features.tsv' );
has '_db_handle' => ( is => 'ro', lazy => 1, builder => '_build__db_handle' );


sub _build__db_handle {
    my ($self) = @_; 
    my ($db_host, $db_port, $db_name) = $self->database_url =~ m/(\S+):(\S+)\/(\S+)/g ;
    return DBI->connect("dbi:Pg:dbname=$db_name;host=$db_host;port=$db_port", $self->database_username, $self->database_password);
}


sub _disconnect_db_handle {
    my ($self) = @_;
    $self->_db_handle->disconnect;
}


sub extract_features {

    my ($self) = @_;
    open (my $outfh, ">", $self->output_file) or die "Could not open $self->output_file";  
    my %all_features;

    my @types =  map { s/\s+$|^\s+//g; qq/'$_'/ } split(/\,/, $self->parent_feature_types);

    my $sql = "select srcfeature.uniquename, feature.uniquename, feature.feature_id, cvterm.name, featureloc.fmin, featureloc.fmax, featureloc.strand, featureloc.featureloc_id
from feature
join featureloc on featureloc.feature_id = feature.feature_id
join feature srcfeature on srcfeature.feature_id = featureloc.srcfeature_id
join cvterm srcfeaturecvterm on srcfeaturecvterm.cvterm_id = srcfeature.type_id
join cvterm on feature.type_id = cvterm.cvterm_id
join organism on organism.organism_id = feature.organism_id
where organism.common_name = '".$self->organism."' and srcfeaturecvterm.name in (".join (",", @types).");";

    my $results = $self->_db_handle->selectall_arrayref($sql);

    foreach my $row (@$results) {
        print {$outfh} join("\t", "@$row"), "\n";
        $all_features{${$row}[1]} = $row;
    }

    close ($outfh);
    $self->_disconnect_db_handle();
    return \%all_features;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;



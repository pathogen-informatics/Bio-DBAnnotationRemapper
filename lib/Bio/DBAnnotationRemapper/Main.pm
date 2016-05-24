package Bio::DBAnnotationRemapper::Main;

# ABSTRACT: Takes in embl/gff files & a db url, relocates the features and generates the sql needed to update the database

=head1 SYNOPSIS



=cut

use Moose;

use Bio::DBAnnotationRemapper::Database::ReaderWriter;
use Bio::DBAnnotationRemapper::Database::SQLGenerator;
use Bio::DBAnnotationRemapper::FlatFile::ReaderWriter;
use Bio::DBAnnotationRemapper::Remapper;
use Data::Dumper;

has 'input_directory'               => ( is => 'ro', isa => 'Str', required => 1 ); # directory of files
has 'input_format'                  => ( is => 'ro', isa => 'Str', default => 'EMBL'); # only embl files supported at the moment TODO: support gff files
has 'database_url'                  => ( is => 'ro', isa => 'Str',      default => 'path-live-db:5432/pathogens' );
has 'database_username'             => ( is => 'ro', isa => 'Str',      required => 1);
has 'database_password'             => ( is => 'ro', isa => 'Str',      required => 1);
has 'organism'                      => ( is => 'ro', isa => 'Str',      required => 1);
has 'parent_feature_types'          => ( is => 'ro', isa => 'Str',      default => 'chromosome, mitochondrial_chromosome, apicoplast_chromosome' );
has 'srcfeature_suffix'             => ( is => 'ro', isa => 'Str', default => '_new'); # useful where database cannot have features with the same name as is the case with our flavour of chado

sub run {

    my ($self) = @_;

    # 1. Extract the features from flat files
    my $file_obj = Bio::DBAnnotationRemapper::FlatFile::ReaderWriter->new(
                        input_directory   => $self->input_directory,
                        input_format => $self->input_format,
    );

    my $file_features = $file_obj->extract_features;
    print Dumper($file_features);


    # 2. Extract features from the database
    my $db_obj = Bio::DBAnnotationRemapper::Database::ReaderWriter->new(
                         organism   => $self->organism,
                         parent_feature_types => $self->parent_feature_types,
                         database_url => $self->database_url,
                         database_username => $self->database_username,
                         database_password => $self->database_password,
                    );
    my $db_features = $db_obj->extract_features;


    # 3. Remap the features in database based on flat files
    my $remapper_obj = Bio::DBAnnotationRemapper::Remapper->new(
                         db_features   => $db_features,
                         file_features => $file_features,  
    );
    $remapper_obj->relocate_features();


    # 4. Generate the SQL needed to update the database
    if(-e $remapper_obj->new_locations and -e $remapper_obj->new_names) {

        my $sql_generator = Bio::DBAnnotationRemapper::Database::SQLGenerator->new(
                            new_locations => $remapper_obj->new_locations,
                            new_names => $remapper_obj->new_names,
        );
        $sql_generator->run();
    } else {
        
        die "Relocating features did not produce expected output files \n";
    
    }

}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
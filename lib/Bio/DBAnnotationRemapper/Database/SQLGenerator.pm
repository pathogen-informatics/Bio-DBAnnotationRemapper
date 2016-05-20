package Bio::ChadoAnnotationRemapper::Chado::SQLGenerator;

# ABSTRACT: Generate SQL specific to version of chado to update featureloc and add previous systematic IDs

=head1 SYNOPSIS

Generate SQL statements. 

=cut

use Moose;

has 'new_locations'                 => ( is => 'ro', isa => 'Str');
has 'new_names'                     => ( is => 'ro', isa => 'Str');
has 'srcfeature_suffix'             => ( is => 'ro', isa => 'Str', default => '_new'); # useful where database cannot have features with the same name as is the case with our flavour of chado
has 'sql_file'                      => ( is => 'ro', isa => 'Str', default => 'commands.sql' );

sub run {

   my ($self) = @_;

   open (my $sql_fh, ">", $self->sql_file) or die "Could not open $self->sql_file";  

   print {$sql_fh} "BEGIN;";

   open (my $new_locs_fh, "<",$self->new_locations) or die "Could not open $self->new_locations";
   for (<$new_locs_fh>) {
        my @values = split(/\t/, $_);
        print {$sql_fh} $self->_generate_sql_floc_update_stmt($values[0], $values[4], $values[5], $values[6], $values[1]);
   }
   close ($new_locs_fh);

   open (my $new_names_fh, "<",$self->new_names) or die "Could not open $self->new_names";
   for (<$new_names_fh>) {
        my ($old, $new) = split(/\t/, $_);
        print {$sql_fh} $self->_generate_sql_feature_update_stmt( $new, $old ), "\n";
        print {$sql_fh} $self->_generate_sql_add_synonym_stmt( $old ), "\n";
        print {$sql_fh} $self->_generate_sql_previous_sys_id_stmt( $old, $new ), "\n";
   }
   close ($new_names_fh);

   print {$sql_fh} "END;";
   close ($sql_fh);
 
}

# update featureloc
sub _generate_sql_floc_update_stmt {

    my ($self, $floc_id, $fmin, $fmax, $strand, $srcfeature) = @_;
    return "update featureloc set 
                   fmin=$fmin,
                   fmax=$fmax,
                   strand=$strand,
                   srcfeature_id=(select feature_id from feature where uniquename=\'".$srcfeature.$self->srcfeature_suffix."\') where featureloc_id=".$floc_id.";";

}

# update name of feature
sub _generate_sql_feature_update_stmt {

    my ($self, $new, $old) = @_;
    return "update feature set uniquename=\'$new\' where uniquename=\'$old\';";

}

# add a synonym
sub _generate_sql_add_synonym_stmt {

    my ($self, $name) = @_;
    return "insert into synonym (name, synonym_sgml, type_id) values (\'$name\', \'$name\', (
select cvterm_id
from cvterm
join dbxref on dbxref.dbxref_id = cvterm.dbxref_id
join db on db.db_id = dbxref.db_id
where db.name = 'genedb_misc'
and dbxref.accession = 'Unique, permanent, accession name for feature'
and cvterm.name = 'previous_systematic_id'  
)    );";

}

# add a previous systematic id
sub _generate_sql_previous_sys_id_stmt {

    my ($self, $synonym, $feature_name) = @_;
    
    return "insert into feature_synonym (feature_id, synonym_id, pub_id) values (
(select feature_id from feature where uniquename = \'$feature_name\'),
(select synonym_id from synonym where name=\'$synonym\' and type_id = (select cvterm_id
                                                                        from cvterm
                                                                        join dbxref on dbxref.dbxref_id = cvterm.dbxref_id
                                                                        join db on db.db_id = dbxref.db_id
                                                                        where db.name = 'genedb_misc'
                                                                        and dbxref.accession = 'Unique, permanent, accession name for feature'
                                                                        and cvterm.name = 'previous_systematic_id')),
1);";


}

no Moose;
__PACKAGE__->meta->make_immutable;
1;


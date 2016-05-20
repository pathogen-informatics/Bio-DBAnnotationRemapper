package Bio::DBAnnotationRemapper::Remapper;

# ABSTRACT: Takes in new annotation in flat files and shifts the locations of existing annotation in a database. 

=head1 SYNOPSIS


=cut

use Moose;
use Bio::DBAnnotationRemapper::Database::ReaderWriter;
use Bio::DBAnnotationRemapper::Database::SQLGenerator;
use Bio::DBAnnotationRemapper::FlatFile::ReaderWriter;


has 'db_features'                  => ( is => 'rw', isa => 'HashRef[ArrayRef[Str]]' );
has 'file_features'                => ( is => 'rw', isa => 'HashRef[ArrayRef[Str]]' );

has 'matched'                       => ( is => 'ro', isa => 'Str', default => 'features.matched.tsv' ); # intersection of features in database and flatfile (i.e. correctly relocated)
has 'file_not_matched'              => ( is => 'ro', isa => 'Str', default => 'file.features.not.matched.tsv' ); # features in flat file not found in database
has 'db_not_matched'                => ( is => 'ro', isa => 'Str', default => 'db.features.not.matched.tsv' ); # features in database not found in flat file
has 'new_locations'                 => ( is => 'ro', isa => 'Str', default => 'new.locations.tsv' ); 
has 'new_names'                     => ( is => 'ro', isa => 'Str', default => 'new.names.tsv' );

has '_previous_sys_ids'             => ( is => 'rw', isa => 'HashRef[Str]', lazy => 1, builder => '_build_previous_sys_ids' );


sub _build_previous_sys_ids {

    my ($self) = @_;

    my %prev_sys_ids;
    foreach my $feature (keys $self->_file_features){
        if ($self->_file_features->{$feature}->[6]) { # if prev sys id exists
            $prev_sys_ids{$self->_file_features->{$feature}->[6]} = $feature;
        }
    }
    return \%prev_sys_ids;
}


sub relocate_features {

    my ($self) = @_;

    open (my $matched_fh, ">", $self->matched) or die "Could not open $self->matched";  
    open (my $file_not_matched_fh, ">", $self->file_not_matched) or die "Could not open $self->file_not_matched";
    open (my $db_not_matched_fh, ">", $self->chado_not_matched) or die "Could not open $self->db_not_matched";
    open (my $locations_fh, ">", $self->new_locations) or die "Could not open $self->new_locations"; 
    open (my $names_fh, ">", $self->new_names) or die "Could not open $self->new_names"; 

   # For every feature from the database, check if it needs to be relocated and/or renamed
    my %features_seen;
    foreach my $feature (keys $self->db_features){

        my ($match, $rename) = $self->_find_name_match($feature);

        if ($match){ 
      #      print {$location_fh} $self->_chado_sql_generator->generate_sql_floc_update_stmt( $self->_chado_features->{$feature}->[7], $self->_file_features->{$match} ), "\n";
            print {$locations_fh} $self->db_features->{$feature}->[7], join("\t", @$self->file_features->{$match}),"\n";
            print {$matched_fh} "$feature\t$match\n"; 
            $features_seen{$match} = 'seen';
            my $feature_type = $self->_chado_features->{$feature}->[3];

            # add previous systematic ids (but only to genes)
            if($rename and ( $feature_type eq 'gene' or $feature_type eq 'pseudogene' )){
                print {$names_fh} "$rename $feature\n";
#                 print {$sql_fh} $self->_chado_sql_generator->generate_sql_feature_update_stmt( $rename, $feature ), "\n";
#                 print {$sql_fh} $self->_chado_sql_generator->generate_sql_add_synonym_stmt( $feature ), "\n";
#                 print {$sql_fh} $self->_chado_sql_generator->generate_sql_previous_sys_id_stmt( $feature, $rename ), "\n";
            }

        }else{
            print {$db_not_matched_fh} join("\t", $feature), "\n";
        }
    }

    # write out anything from the flat file that was not matched as these are likely to be new genes
    foreach my $feature_still_not_matched (keys $self->_file_features){
        if (! exists $features_seen{$feature_still_not_matched} ) {
            print {$file_not_matched_fh} "$feature_still_not_matched\n";
        }
    }


    # sort files and close file handles
    foreach ( $self->matched, $self->file_not_matched, $self->db_not_matched, $self->new_locations, $self->new_names ) {
        system("sort $_ -o $_");
    }

    foreach ($matched_fh, $file_not_matched_fh, $db_not_matched_fh, $locations_fh, $names_fh ) {
        close $_;
    }
}


sub _find_name_match {

    my ($self, $name) = @_;

    # We first look for the feature in the list of features in the flat file(s). If not found, we try 
    # removing any .1 (transcripts) or .1:pep (peptides) from the end of its name and try again.
    # If still not found, we repeat this search but using the previous systematic ID instead.
    # return name match and a flag to indicate if feature should be renamed
  
    my $rename = 0;

    if (exists $self->_file_features->{$name}) {
        return ($name, $rename);
    }

    my $stripped_name = $self->_strip_transcript_and_peptide_names($name);   
    if (exists $self->_file_features->{$stripped_name}) {
        return ($stripped_name, $rename);
    }
    
    my $new_id = $self->_previous_sys_ids->{$stripped_name};

    if ($new_id and (exists $self->_file_features->{$new_id}) and (not exists $self->_chado_features->{$new_id} )) { 
        # We check if the new ID is already in chado because sometimes gene models are merged and can have the same name as one that already exists
        $rename = $self->_place_transcript_and_peptide_names($new_id, $name);
        return ($new_id, $rename);
    }
    
    return (0, $rename);

}


sub _strip_transcript_and_peptide_names {
    
    my ($self, $name) = @_;
    if($name =~ /(\S+)\.1$/ || $name =~ /(\S+)\.1:pep$/){
        return $1;
    }
    return $name;    
}


sub _place_transcript_and_peptide_names {
    
    my ($self, $name, $looklike) = @_;

    if($looklike =~ /\S+(\.1)$/ || $looklike =~ /\S+(\.1:pep)$/){
        return "$name$1";
    }
    return $name;    # gene or exon names won't have changed, so return as they are
}

 



no Moose;
__PACKAGE__->meta->make_immutable;
1;
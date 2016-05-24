package Bio::DBAnnotationRemapper::FlatFile::ReaderWriter;

# ABSTRACT: Read an EMBL/GFF file and out a list of features with coordinates

=head1 SYNOPSIS

Read an EMBL/GFF file and output a list of features with coordinates
Each line of the form:

parent_ID feature_name feature_type start end strand previous_feature_name


=cut

use Moose;
use Bio::SeqIO;
use Bio::Location::SplitLocationI;
use Data::Dumper;


has 'input_directory'             => ( is => 'ro', isa => 'Str', required => 1 );
has 'input_format'                => ( is => 'ro', isa => 'Str', default => 'EMBL');
has 'output_file'                 => ( is => 'ro', isa => 'Str', default => 'file.features.tsv' );
has 'help'                        => ( is => 'rw', isa => 'Bool',     default  => 0 );


sub _get_input_file_parser {
    my ($self, $file) = @_;
    return Bio::SeqIO->new(
        -format   => $self->input_format,
        -file     => $file,
    );
}


sub extract_features {

    my ($self) = @_;
 
    open (my $outfh, ">", $self->output_file) or die "Could not open $self->output_file"; 
    my %all_features;

    opendir my $dir, $self->input_directory or die "Cannot open directory: $self->input_directory";
    my @input_files = readdir $dir;
    closedir $dir;
 
    foreach my $file (@input_files){
  
        my $parser = $self->_get_input_file_parser($self->input_directory."/".$file);

        while ( my $seq = $parser->next_seq() ) {
            my @features = $seq->get_SeqFeatures();
            foreach my $feat ( @features ) {

                    my @tags = $feat->get_all_tags();
                    my $feature_name = $feat->primary_tag; # be default will use primary tag e.g. repeat regions aren't usually given a name so will just output repeat_region
                    my $previous_systematic_id = "";
                    my $pseudogene = 0;

                    # chado stores the CDS as a gene
                    my $type = $feat->primary_tag;
                    if ($feat->primary_tag eq 'CDS') {
                        $type = 'gene';
                    }

                    foreach my $tag (@tags){
                            if($tag eq 'locus_tag' or $tag eq 'ID'){ # using this method because not all embl files will have ID which methods like display_name() rely on
                                    my @values = $feat->get_tag_values($tag);
                                    $feature_name = $values[0] if (@values);
                            }
                            if($tag eq 'previous_systematic_id'){
                                    my @values = $feat->get_tag_values($tag);
                                    $previous_systematic_id = $values[0] if (@values);
                            }
                            if($tag eq 'pseudo'){ #lookout for pseudogenes
                                $type = 'pseudogene';
                                $pseudogene = 1;
                            }
                    }
                    # main feature (gene/repeat_region etc)
                    $all_features{$feature_name} = [$seq->id, $feature_name, $type, $feat->start, $feat->end, $feat->strand, $previous_systematic_id];
                    print {$outfh} join("\t", ($seq->id, $feature_name, $type, $feat->start, $feat->end, $feat->strand, $previous_systematic_id)), "\n";

                    # If CDS/rRNA/ncRNA/tRNA, extract the exons individually TODO: Deal with other tags
                    if ($feat->primary_tag ~~ ['CDS', 'rRNA', 'ncRNA', 'tRNA']){

                        my $n = 1;
                        my $exon_name = $self->_generate_exon_name($feature_name, $n);
                        my $previous_exon_name = $self->_generate_exon_name($previous_systematic_id, $n);
                        my $exon_type = $self->_generate_exon_type($pseudogene);


                        if ($feat->location->isa('Bio::Location::SplitLocationI')) {  # Multiple exons         
                           
                            foreach my $loc ( $feat->location->sub_Location ) {

                                $exon_name = $self->_generate_exon_name($feature_name, $n);
                                $previous_exon_name = $self->_generate_exon_name($previous_systematic_id, $n);
                      
                                $all_features{$exon_name} = [$seq->id, $exon_name, $exon_type, $loc->start, $loc->end, $feat->strand, $previous_exon_name];
                                print {$outfh} join("\t", ($seq->id, $exon_name, $exon_type, $loc->start, $loc->end, $feat->strand, $previous_exon_name)), "\n";
                                $n++;
                            }

                        }else{ # Just one exon
                              $all_features{$exon_name} = [$seq->id, $exon_name, $exon_type, $feat->start, $feat->end, $feat->strand, $previous_exon_name];
                              print {$outfh} join("\t", ($seq->id, $exon_name, $exon_type, $feat->start, $feat->end, $feat->strand, $previous_exon_name)), "\n";

                        }
                            
                    
                    }   
                

            }
       }
    }


    close ($outfh);
    return \%all_features;
}

sub _generate_exon_type {
    my ($self, $pseudogene ) = @_;
    if ($pseudogene) {
        return "pseudogenic_exon";
    }
    return "exon";
}

sub _generate_exon_name {
    my ($self, $gene_name, $num) = @_;
    if (defined $gene_name and $gene_name ne ""){
        return $gene_name.".1:exon:"."$num";
    }
    return "";
}





no Moose;
__PACKAGE__->meta->make_immutable;
1;


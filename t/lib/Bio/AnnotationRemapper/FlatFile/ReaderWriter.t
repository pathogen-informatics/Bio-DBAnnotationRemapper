#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::File::Contents;
    use_ok('Bio::ChadoAnnotationRemapper::FlatFile::ReaderWriter');
}

my $obj;
my $cwd = getcwd();
 

ok($obj = Bio::ChadoAnnotationRemapper::FlatFile::ReaderWriter->new(
  input_directory   => $cwd.'/t/data/test_dir/',
),'Initialise object');

ok($obj->extract_features, 'extract features from test embl file');
files_eq ($obj->output_file, $cwd.'/t/data/test.embl.features.tsv', 'test output file contents');


unlink($obj->output_file);
done_testing();
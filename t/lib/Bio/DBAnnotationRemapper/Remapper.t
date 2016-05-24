#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use Data::Dumper;


BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::File::Contents;
    use_ok('Bio::DBAnnotationRemapper::Remapper');
}

my $obj;
my $cwd = getcwd();

# Test data from database
my %test_db_data = (
          "PY17X_0100005" => [
                            'Py17X_05_v3',
                            'PY17X_0100005',
                            32240497,
                            'gene',
                            40565,
                            40675,
                            1,
                            120031616
                            ],
          "PY17X_0100005.1:exon:1" => [                            
                            'Py17X_05_v3',
                            'PY17X_0100005.1:exon:1',
                            32240498,
                            'exon',
                            40565,
                            40675,
                            1,
                            120031617
                            ],
          "PY17X_01000Y6" => [
                            'Py17X_05_v3',
                            'PY17X_0100006',
                            32240499,
                            'gene',
                            405,
                            500,
                            1,
                            120031618
                            ],
);

# test data from a flat file
my %test_file_data = (
     "PY17X_0100005" => [
                               'Py17X_01_v3',
                               'PY17X_0100005',
                               'gene',
                               '2412',
                               '3487',
                                1,
                               ''
                             ],
     "PY17X_0100006" => [
                               'Py17X_01_v3',
                               'PY17X_0100006',
                               'gene',
                               '2000',
                               '2100',
                                1,
                               'PY17X_01000Y6'
                             ],
);
 
ok($obj = Bio::DBAnnotationRemapper::Remapper->new(
    db_features => \%test_db_data,
    file_features => \%test_file_data,
),'Initialise object');

ok($obj->relocate_features, 'relocate features OK');

foreach ($obj->matched, $obj->file_not_matched, $obj->db_not_matched, $obj->new_locations, $obj->new_names) {

    files_eq ($cwd."/$_", $cwd."/t/data/remap/$_", "contents of $_ OK");
    unlink($cwd."/$_");

}



done_testing();


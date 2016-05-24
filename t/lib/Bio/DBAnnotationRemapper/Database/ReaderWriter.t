#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use Data::Dumper;


BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::File::Contents;
    use_ok('Bio::DBAnnotationRemapper::Database::ReaderWriter');
}

my $obj;
my $cwd = getcwd();
 

ok($obj = Bio::DBAnnotationRemapper::Database::ReaderWriter->new(
  organism   => 'Pyoelii',
  database_username => 'pathdb',
  database_password => 'LongJ!@n',
),'Initialise object');

ok($obj->extract_features, 'extract features from a chado database');
# Add test here to check for content (mock database)

unlink($obj->output_file);
done_testing();
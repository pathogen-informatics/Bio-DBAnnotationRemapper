#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;


BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::File::Contents;
    use_ok('Bio::DBAnnotationRemapper::Database::SQLGenerator');
}

my $obj;
my $cwd = getcwd();
my $sql_file = $cwd.'/commands.sql';
 

ok($obj = Bio::DBAnnotationRemapper::Database::SQLGenerator->new(
  new_locations   => $cwd.'/t/data/test_new_locations.tsv',
  new_names      => $cwd.'/t/data/test_new_names.tsv',
),'Initialise object');

ok($obj->run(), 'generate SQL OK');
files_eq ($sql_file, $cwd.'/t/data/test_commands.sql', 'test sql file contents');


unlink($sql_file);
done_testing();
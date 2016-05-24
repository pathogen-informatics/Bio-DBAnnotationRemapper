#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;


BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::File::Contents;
    use_ok('Bio::DBAnnotationRemapper::Main');
}

my $obj;
my $cwd = getcwd();
 

ok($obj = Bio::DBAnnotationRemapper::Main->new(
  input_directory   => $cwd.'/t/data/modified',
  organism   => 'Pyoelii',
  database_username => 'pathdb',
  database_password => 'LongJ!@n',
),'Initialise object');

ok($obj->run(), 'relocate features and generate sql');

done_testing();

#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;


BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::File::Contents;
    use_ok('Bio::ChadoAnnotationRemapper::Remapper');
}

my $obj;
my $cwd = getcwd();
 

ok($obj = Bio::ChadoAnnotationRemapper::Remapper->new(
  input_directory   => $cwd.'/t/data/modified',
  organism   => 'Pyoelii',
  database_username => 'pathdb',
  database_password => 'LongJ!@n',
),'Initialise object');

ok($obj->relocate_features, 'relocate features');

done_testing();


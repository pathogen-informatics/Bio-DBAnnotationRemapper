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
  database_password => '', # change to read password from env var
),'Initialise object');

ok($obj->run(), 'relocate features and generate sql');

my @output_files = ( 'file.features.tsv',
                     'db.features.tsv',
                     'file.features.not.matched.tsv',
                     'db.features.not.matched.tsv',
                     'features.matched.tsv',
                     'new.names.tsv',
                     'new.locations.tsv',
                     'commands.sql'
                    );

foreach (@output_files){
    unlink($_);

}

done_testing();
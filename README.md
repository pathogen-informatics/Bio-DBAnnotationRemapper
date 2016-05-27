Bio-DBAnnotationRemapper
========================

Takes in a directory of embl files and database connection details, and generates the SQL needed to update the annotation and names in the database to reflect the 
annotation in the embl files. Useful for heavily/manually annotated genomes in a database where reloading the entire dataset would involve some data loss or
 manual work to redo/check the annotation. Currently written to work with the pathogens chado database, but other databases can be accommodated by 
editing/replacing the Database/SQLGenerator.pm and Database/ReaderWriter.pm modules.


Summary
-----------

Required input:

1. Directory with embl files
2. Connection details to a database
3. Organism name

Output:

1. Files with features that did not match 
2. Commands.sql (SQL commands to update the database and add previous systematic IDs, to be piped in separately after loading in to the fastas for the updated sequences)


Installation
------------
(fill in)


Usage (for developers)
----------------------

Sample usage:

my $obj = Bio::DBAnnotationRemapper::Main->new(
  input_directory   => $mydir',
  organism   => 'organismname',
  database_username => 'username',
  database_password => 'password',
);

$obj->run();


Arguments:
----------------------

*Required*

**input_directory**: Directory of embl files
**organism**: Organism common name
**database_url**: URL of database in the form of host:port/database, default bigtest4
**database_username**: Database username
**database_password**: Database password

*Optional*

**input_format**: Format of embl files (default embl)
**parent_feature_types**: The type of parent features that the annotation is on (default, chromosomes (mitochondrial and apicoplast chromosomes too)
**srcfeature_suffix**: In the chado pathogens database features should have unique names. This suffix is added to parent feature names so that they can be uniquely identified. 


Output files:
----------------------

**commands.sql**: The SQL commands to be piped into the database (after the new sequences have been loaded)

The files below are useful if you want to track what features have/have not mapped over. 

**file.features.tsv**: All features extracted from flat files
**db.features.tsv**: All features extracted from database
**file.features.not.matched.tsv**: Features in flat files that did not match anything in the database
**db.features.not.matched.tsv**: Features in database that did not match anything in the flat files
**features.matched.tsv**: Features that matched
**new.names.tsv**: New gene names (old gene names will get put in as previous systematic IDs)
**new.locations.tsv**: New locations for features in the database

Commandline script:
----------------------

db_remap

To do:
----------------------

1. Make this work with GFF files
2. Accept a file with naming conventions between old and new annotations
3. Make tests run on an SQLite instance or some such without connecting to database
4. Add more tests


Contact
-------

Author: Nishadi De Silva
Affiliation: Wellcome Trust Sanger Institute, Hinxton, UK
Email: path-help@sanger.ac.uk
      

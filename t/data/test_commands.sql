BEGIN;
update featureloc set 
                   fmin=6006,
                   fmax=7085,
                   strand=-1,
                   srcfeature_id=(select feature_id from feature where uniquename='Py17X_01_v3_new') where featureloc_id=123;
update featureloc set 
                   fmin=6006,
                   fmax=6092,
                   strand=-1,
                   srcfeature_id=(select feature_id from feature where uniquename='Py17X_01_v3_new') where featureloc_id=456;
update featureloc set 
                   fmin=6181,
                   fmax=6963,
                   strand=-1,
                   srcfeature_id=(select feature_id from feature where uniquename='Py17X_01_v3_new') where featureloc_id=789;
update featureloc set 
                   fmin=7071,
                   fmax=7085,
                   strand=-1,
                   srcfeature_id=(select feature_id from feature where uniquename='Py17X_01_v3_new') where featureloc_id=1011;
update feature set uniquename='PY17X_0100009' where uniquename='PY17X_0058700';
insert into synonym (name, synonym_sgml, type_id) values ('PY17X_0058700', 'PY17X_0058700', (
select cvterm_id
from cvterm
join dbxref on dbxref.dbxref_id = cvterm.dbxref_id
join db on db.db_id = dbxref.db_id
where db.name = 'genedb_misc'
and dbxref.accession = 'Unique, permanent, accession name for feature'
and cvterm.name = 'previous_systematic_id'  
)    );
insert into feature_synonym (feature_id, synonym_id, pub_id) values (
(select feature_id from feature where uniquename = 'PY17X_0100009'),
(select synonym_id from synonym where name='PY17X_0058700' and type_id = (select cvterm_id
                                                                        from cvterm
                                                                        join dbxref on dbxref.dbxref_id = cvterm.dbxref_id
                                                                        join db on db.db_id = dbxref.db_id
                                                                        where db.name = 'genedb_misc'
                                                                        and dbxref.accession = 'Unique, permanent, accession name for feature'
                                                                        and cvterm.name = 'previous_systematic_id')),
1);
END;
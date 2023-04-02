#!/bin/sh

cp ../convert-zip-to-db/translation_words.db ./tw.db
ls -al tw.db
sqlite3 tw.db <<EoF
CREATE TABLE tw (
  name text primary key,
  keyterm text,
  keyword text,
  data text
);
INSERT INTO tw 
SELECT name, keyterm, keyword, data 
FROM translation_words;
DROP TABLE translation_words;
.schema
select zstd_enable_transparent('{"table": "tw", "column": "data", "compression_level": 19, "dict_chooser": "''a''"}');
select zstd_incremental_maintenance(null, 1);
.tables
select count(*) from tw;
select keyword,keyterm from tw where keyword = 'winepress';
.quit
EoF
ls -al tw.db
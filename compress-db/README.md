# compress-db

This folder experiments with compression using the 
https://github.com/phiresky/sqlite-zstd/releases/tag/v0.3.2
extension.

## Steps

1. download and install the extension
    - from the release above, I selected the x86 linux tar.gz file
    - then extracted the library:
```
$ tar xfv sqlite_zstd-v0.3.2-x86_64-unknown-linux-gnu.tar.gz 
sqlite_zstd-v0.3.2-x86_64-unknown-linux-gnu/LICENSE
sqlite_zstd-v0.3.2-x86_64-unknown-linux-gnu/README.md
sqlite_zstd-v0.3.2-x86_64-unknown-linux-gnu/libsqlite_zstd.so
$ cd *gnu
$ ls
libsqlite_zstd.so  LICENSE  README.md
$ 
```
2. copied library:
```
$ ls
libsqlite_zstd.so  LICENSE  README.md
$ sudo mv libsqlite_zstd.so /usr/lib/sqlite3/
$ ls /usr/lib/sqlite3/
crypto.so  fuzzy.so   libsqlite_zstd.so  regexp.so  unicode.so
define.so  ipaddr.so  math.so            stats.so   uuid.so
fileio.so  json1.so   pcre.so            text.so    vsv.so
$ 
```
3. edited `~/.sqliterc`:
```
$ cat ~/.sqliterc
.load /usr/lib/sqlite3/pcre.so
.load /usr/lib/sqlite3/regexp.so
.load /usr/lib/sqlite3/text.so
.load /usr/lib/sqlite3/libsqlite_zstd.so
$ 
```
4. Using the info in the library's readme with a copy of the db in this folder from the convert folder, 
```sql
select zstd_enable_transparent('{"table": "translation_words", "column": "data", "compression_level": 19, "dict_chooser": "''a''"}');
```
5. Didn't work:
```
sqlite> select zstd_enable_transparent('{"table": "translation_words", "column": "data", "compression_level": 19, "dict_chooser": "''a''"}');
[2023-04-01T23:57:40Z WARN  sqlite_zstd::transparent] Warning: It is recommended to set `pragma journal_mode=WAL;`
[2023-04-01T23:57:40Z WARN  sqlite_zstd::transparent] Warning: It is recommended to set `pragma auto_vacuum=full;`
[2023-04-01T23:57:40Z WARN  sqlite_zstd::transparent] Warning: It is recommended to set `pragma busy_timeout=2000;` or higher
Error: Table translation_words does not have a primary key, sqlite-zstd only works on tables with primary keys, since rowids can change on VACUUM.
sqlite> 
```
6. Add the name column as pk since it is contains the full path:
```
alter table translation_words add primary key (name);
```
7. Didn't work. Cannot add a pk to an sqlite db after it has been created.
8. Thus:
```
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

sqlite> .schema
CREATE TABLE tw (
  name text primary key,
  keyterm text,
  keyword text,
  data text
);
```
9. Now run the compression step above again with new table name:
```
select zstd_enable_transparent('{"table": "tw", "column": "data", "compression_level": 19, "dict_chooser": "''a''"}');
[2023-04-02T00:12:24Z WARN  sqlite_zstd::transparent] Warning: It is recommended to set `pragma journal_mode=WAL;`
[2023-04-02T00:12:24Z WARN  sqlite_zstd::transparent] Warning: It is recommended to set `pragma auto_vacuum=full;`
[2023-04-02T00:12:24Z WARN  sqlite_zstd::transparent] Warning: It is recommended to set `pragma busy_timeout=2000;` or higher
Done!
sqlite>
```
10. Now do the maintenance step and exit.
```
select zstd_incremental_maintenance(null, 1)
[2023-04-02T00:15:03Z WARN  sqlite_zstd::transparent] Warning: It is recommended to set `pragma journal_mode=WAL;`
[2023-04-02T00:15:03Z WARN  sqlite_zstd::transparent] Warning: It is recommended to set `pragma auto_vacuum=full;`
[2023-04-02T00:15:03Z WARN  sqlite_zstd::transparent] Warning: It is recommended to set `pragma busy_timeout=2000;` or higher
[2023-04-02T00:15:03Z INFO  sqlite_zstd::transparent] tw.data: Total 935 rows (1.46MB) to potentially compress (split in 1 groups).
[2023-04-02T00:15:04Z INFO  sqlite_zstd::transparent] Compressed 935 rows with dict_choice=a (dict_id=1). Total size of entries before: 1.46MB, afterwards: 434.39kB, (average: before=1.56kB, after=464B)
[2023-04-02T00:15:04Z INFO  sqlite_zstd::transparent] Handled 935 / 935 rows  (1.46MB / 1.46MB)
[2023-04-02T00:15:04Z INFO  sqlite_zstd::transparent] All maintenance work completed!
0
sqlite>
```
11. Review the changes:
```
sqlite> .tables
_tw_zstd       _zstd_configs  _zstd_dicts    tw           
sqlite> select name, keyterm, keyword from tw where keyword = 'paul';
en_tw/bible/names/paul.md|names|paul
sqlite> 
```
12. Size of original vs compressed: 1,921,024 vs 3,878,912


Well! this didn't turn out well. 
Filed an issue: https://github.com/phiresky/sqlite-zstd/issues/28

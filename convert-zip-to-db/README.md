# Converting a Zip file to an SQLite3 Database file

*Note! the description below is tailored to a specific zip file
that comes from a release of a git repository. YMMV!*

First I have an zip file named `en_tw.zip`.

Now I can run queries against it. For example:

```
sqlite> .mode table
sqlite> select name, sz from zipfile('en_tw.zip') limit 5;
+---------------------------------+-----+
|              name               | sz  |
+---------------------------------+-----+
| en_tw/                          | 0   |
| en_tw/.gitattributes            | 39  |
| en_tw/.github/                  | 0   |
| en_tw/.github/ISSUE_TEMPLATE.md | 733 |
| en_tw/.gitignore                | 38  |
+---------------------------------+-----+
sqlite> 
```

Here are all the columns:
```
sqlite> select * from zipfile('en_tw.zip') limit 1;
+--------+------+------------+----+---------+------+--------+
|  name  | mode |   mtime    | sz | rawdata | data | method |
+--------+------+------------+----+---------+------+--------+
| en_tw/ | 0    | 1676070998 | 0  |         |      | 0      |
+--------+------+------------+----+---------+------+--------+
sqlite> 
```

So only three columns of interest:
```
sqlite> select name,sz,substr(data,0,13) from zipfile('en_tw.zip') where name like '%paul.md';
+---------------------------+------+-------------------+
|           name            |  sz  | substr(data,0,13) |
+---------------------------+------+-------------------+
| en_tw/bible/names/paul.md | 3022 | # Paul, Saul      |
+---------------------------+------+-------------------+
sqlite> 
```

In appendix A, I develop a way using some extensions. The string functions in sqlite3 are 
pretty minimal and do what I needed to do would have been very tedious.


Here is the final SQL needed to create the database from the zip file. Do note that any zip will have different things of interest.

```
sqlite> create table translation_words as select name, 
regexp_capture(name, '^\w+/\w+/(\w+)/(\w+)\.md$', 1) as keyterm,
regexp_capture(name, '^\w+/\w+/(\w+)/(\w+)\.md$', 2) as keyword,
data
from zipfile('en_tw.zip') 
where name regexp '^en_tw/bible/.*\.md$';
sqlite> .schema
CREATE TABLE translation_words(
  name,
  keyterm,
  keyword,
  data
);
sqlite> .save translation_words.db
```

Example without the markdown column (data):
```
sqlite> select name, keyterm, keyword from translation_words where keyword = 'paul';
+---------------------------+---------+---------+
|           name            | keyterm | keyword |
+---------------------------+---------+---------+
| en_tw/bible/names/paul.md | names   | paul    |
+---------------------------+---------+---------+
sqlite> 
```

# Appendix A - extensions

I discovered a nice set of extenstions called "sqlean". Can be found at:
https://github.com/nalgeon/sqlean/releases/

Steps:
1. Download for OS
2. Unzip the file
3. For Linux, I already had one extension installed. So I copied the new ones into the same folder.
4. See transcript below.
5. Next I edited `.sqliterc` in my home folder to auto-load the ones I was interested right now.
6. The new content was:
```
$ cat .sqliterc
.load /usr/lib/sqlite3/pcre.so
.load /usr/lib/sqlite3/regexp.so
.load /usr/lib/sqlite3/text.so
$ 
```

This release (19.3 - released 3 weeks ago (today is 2023-04-01)) has these additions:
```
New functions:

regexp_capture(source, pattern [, n]) extracts a captured group from the source string (regexp extension).
sqlean_version() returns the current version (all extensions).
```

The regexp capture is one I can use to work with the paths in the zip file.

```
# pattern: en_tw/bible/kt/adoption.md 

select name, 
regexp_capture(name, '^\w+/\w+/(\w+)/(\w+)\.md$', 1) as keyterm,
regexp_capture(name, '^\w+/\w+/(\w+)/(\w+)\.md$', 2) as keyword
from zipfile('en_tw.zip') 
where name regexp '^en_tw/bible/.*\.md$' limit 5;
```

Results:
```
sqlite> select name, 
regexp_capture(name, '^\w+/\w+/(\w+)/(\w+)\.md$', 1) as keyterm,
regexp_capture(name, '^\w+/\w+/(\w+)/(\w+)\.md$', 2) as keyword
from zipfile('en_tw.zip') 
where name regexp '^en_tw/bible/.*\.md$' limit 5;
+-------------------------------+---------+-------------+
|             name              | keyterm |   keyword   |
+-------------------------------+---------+-------------+
| en_tw/bible/kt/abomination.md | kt      | abomination |
| en_tw/bible/kt/adoption.md    | kt      | adoption    |
| en_tw/bible/kt/adultery.md    | kt      | adultery    |
| en_tw/bible/kt/almighty.md    | kt      | almighty    |
| en_tw/bible/kt/altar.md       | kt      | altar       |
+-------------------------------+---------+-------------+
sqlite> 
```



**Transcript**:
```
$ pwd
/home/cecil
$ ls /usr/lib/sqlite3/
pcre.so
$ pwd
/home/cecil
$ cd ~/Downloads/
$ unzip sqlean-linux-x86.zip 
Archive:  sqlean-linux-x86.zip
  inflating: crypto.so               
  inflating: define.so               
  inflating: fileio.so               
  inflating: fuzzy.so                
  inflating: ipaddr.so               
  inflating: json1.so                
  inflating: math.so                 
  inflating: regexp.so               
  inflating: stats.so                
  inflating: text.so                 
  inflating: unicode.so              
  inflating: uuid.so                 
  inflating: vsv.so                  
$ ls
crypto.so      fuzzy.so   obsidian-cli                           stats.so    vsv.so
define.so      ipaddr.so  obsidian-cli_0.1.1_linux_amd64.tar.gz  text.so
en_ta-v36.zip  json1.so   regexp.so                              unicode.so
fileio.so      math.so    sqlean-linux-x86.zip                   uuid.so
$ sudo mv *.so /usr/lib/sqlite3/
$ ls /usr/lib/sqlite3/
crypto.so  fileio.so  ipaddr.so  math.so  regexp.so  text.so     uuid.so
define.so  fuzzy.so   json1.so   pcre.so  stats.so   unicode.so  vsv.so
$ 
```

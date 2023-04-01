# Converting a Zip file to an SQLite3 Database file

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

with pass1(name,folder1) as (
    select name,
    substr(name, instr(name,'/')+1) folder1
    from zipfile('en_tw.zip') where name like '%paul.md'
)
,pass2(name,folder2) as (
    select name, substr(folder1, instr(folder1,'/')+1)
    from pass1
)
,pass3(name, folder3) as (
    select name, substr(folder2, instr(folder2,'/')+1)
    from pass2
)
select * from pass3;



To limit results to actual files of interest:
```
sqlite> select name from zipfile('en_tw.zip') where name regexp '\.md$' limit 5;
+---------------------------------+
|              name               |
+---------------------------------+
| en_tw/.github/ISSUE_TEMPLATE.md |
| en_tw/LICENSE.md                |
| en_tw/README.md                 |
| en_tw/bible/kt/abomination.md   |
| en_tw/bible/kt/adoption.md      |
+---------------------------------+
sqlite> 
```
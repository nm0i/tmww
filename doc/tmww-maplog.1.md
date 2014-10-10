Name
----
maplog.plugin - awk wrapper for parsing map log

Usage
-----

    maplog arguments: [ opts ] query [ log ]*
    Time interval options:
        -f "YYYY-MM-DD[ HH:MM:SS]" -- from; HH:MM:SS is optional
        [ -t "YYYY-MM-DD [ HH:MM:SS]" ] -- to; HH:MM:SS is optional
    PCIDs query generation:
        { -p PLAYER }* -- add chars by PLAYER
        { -a ACCID }* -- add chars by ACCID
        { -c CHAR }* -- add char
        { -C CHAR }* -- add chars by CHAR (same account)
        { -x CHAR }* -- remove CHAR from query
        { -X CHAR }* -- remove chars by CHAR from query
        { -w PCID }* -- add PCID
        { -d PCID }* -- remove PCID
    Other options:
        [ -e FILE ] -- external file with pcids
        [ -i INT ] -- grep generated pcids on field number INT
        [ -r ] -- prefix pcids with "PC"
        [ -b EXPR ] -- BEGIN awk expressions
        [ -z ] -- logs are complessed with gzip
        [ -n ] -- nondefault maplog name format (default has timestamp)
        [ -o OPERATION ] -- shortcut to query filter '$5=="OPERATION"'
    Filter:
        query -- awk expression with few predefined arrays
        item_rares - array of rare item ids
    Logs:
        logs -- gzipped logs; default filename mask is "map.log.*.gz"

Config
------

MAPLOGPATH  
    location of map logs

Example
-------

    $ tmww maplog -C 'Roaming Merchant' -f 2014-08-01 -t 2014-09-01
        -o '^trade' '($9 > 100000 || $11 > 300 )' -- map.log.*.gz

See tmwa distribution for map log format.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-server(1)


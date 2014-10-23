Name
----
maplog.plugin - awk wrapper for parsing map log

Usage
-----

    maplog arguments: OPTIONS [ LOG ]*
    Time interval options:
        [ -f "YYYY-MM-DD[ HH:MM:SS]" ] -- from; HH:MM:SS is optional
        [ -t "YYYY-MM-DD[ HH:MM:SS]" ] -- to; HH:MM:SS is optional
        [ -d N ] -- last N days
        [ -m N ] -- last N months
    PCIDs query generation:
        [ -p PLAYER ]* -- include chars by PLAYER
        [ -a ACCID ]* -- include chars by ACCID
        [ -c CHAR ]* -- include char
        [ -C CHAR ]* -- include chars by CHAR (same account)
        [ -x CHAR ]* -- exclude CHAR
        [ -X CHAR ]* -- exclude chars on account by CHAR
        [ -w PCID ]* -- include PCID
        [ -W PCID ]* -- exclude PCID
    Item query:
        [ -i NAME ] -- include item name
        [ -y ID ] -- include item by id
        [ -I GLOB ] -- include itemsets by glob
    Configured query:
        [ -u SECTION ] -- use expression from section SECTION in config
            shipped filters are: sell, buy, frisk
        [ -q EXPR ] -- additional condition to match log record
        [ -Q EXPR ] -- expression executed after PCIDs and all other criterias matched
    Custom search:
        [ -n INT ] -- grep generated PCIDs on field number INT
        [ -N INT ] -- grep generated item IDs on field number INT
        [ -z ] -- all PCIDs conversion (terribly slow)
        [ -Z ] -- all item IDs conversion (slow)
        [ -r ] -- prefix pcids with "PC"
        [ -R ] -- no readable PCIDs/item IDs conversion
        [ -o OPERATION ] -- shortcut to query filter '$5=="OPERATION"'
        [ -b EXPR ] -- BEGIN awk expressions
        [ -q EXPR ] -- additional condition to match log record
        [ -Q EXPR ] -- expression executed after PCIDs and all other criterias matched
    Logs:
        logs -- custom location gzipped logs; default filename mask is "map.log.*.gz"
            with default location as $SERVERPATH/world/map/log

Config
------

MAPLOGPATH : string -> $SERVERPATH/world/map/log 
    location of map logs
MAPLOGSHIFT : int -> 1024
    shift of timestamp in maplog name. Default name format is: map.log.TIMESTAMP.gz

Example
-------

    $ tmww maplog -zZ -c 'Roaming Merchant' -u sell -q 'gp >= 10000' -f 2014-08 -t 2014-08
    $ tmww maplog -zZ -p ginaria -u frisk -I 'rares*'

Map log format for tmwa as of 2014-10 distributed with tmww doc.

Notes
-----

Sections may define readable field names for use in -q option, e.g. with
default "sell" filter field FIXME available as "gp".

In case -z or -Z option used, cached PCIDs and item IDs are stored in $PRIVTMP.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-server(1), tmww-db(1)


Name
----
crime - operations on public GM logs

Synopsis
--------

crime [-umrfbB]

Options
-------

-u          mirror GM logs folder
-m          cut readable messages
-r          parse logs for ban/block records
-f          fill up player records with ban/block results
-b          GM stats for bans (cumulative with -B)
-B          GM stats for blocks (cumulative with -b)
-c          clean database marks (e.g. to refill upgraded players DB)
-p PLAYER   search marks for PLAYER chars

Config
------

CRIMEPATH : string : $HOME/log/gm/$servername
    path to GM logs and parsed files

Example
-------

Example cron record for updating players records:

    * 5 * * * tmww crime -urcf >/dev/null 2>&1

Option -f sets field "crime" to value "true" if some of known player alts got
ban/block over time. For reverse search use -p operation

    $ tmww crime -p bbb

Example block stats:

    $ wc -l $CRIMEPATH/records/blocks* | sed '$d' | bars

Notes
-----

Delete $CRIMEPATH/dbupdate/* files with -c option to make fresh upgrade to
player db.

Files
-----

CRIMEPATH/gm.log.YYYY-MM  
    downloaded public GM log
CRIMEPATH/messages/messages.YYYY-MM  
    parsed messages for each log
CRIMEPATH/records/allbanned  
    all banned nicks, sorted, unique
CRIMEPATH/records/allblocked  
    all blocked nicks, sorted, unique
CRIMPATH/records/bans.YYYY-MM  
    relevant log lines, excluding +5mn bans (caretaker's wife)
CRIMEPATH/records/blocks.YYYY-MM  
    relevant log lines

Bugs
----

-m , -r and -f options perform update using GNU make.

-p option is quite noizy but much better than simple grep or alts/server grep
operation.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-alts(1), tmww-server(1)


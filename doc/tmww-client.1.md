Name
----
client.plugin - client versions log queries

Usage
-----

    subcommand: timeline -- tail detected clients log in order of records
        options: ndmftacCp
    subcommand: pattern -- chars top list on time interval with client names matching pattern
        options: nusdmft
    subcommand: summary -- top list of most frequent detected versions for char/player
        options: ndmftacCp
    subcommand: similar -- chars top list detected to use most frequent client version
        of target player on given time interval
        options: nidmftaAcp
    Option description:
        [ -n N ] - limit output by N lines; default to 2 for all commands
        [ -u PATTERN ] -- client version ("useragent") search pattern, e.g. "Linux.*1.4.1.18"
        [ -i ] -- include target player chars (only for "similar" subcommand) 
        [ -s ] -- case sensitivity
    - time options:
        [ { -d | -m } N ] -- during N last days/month
        [ -f yyyy-mm[-dd] ] -- start interval
        [ -t yyyy-mm[-dd] ] -- end interval. defaults to current day if omitted
    - target options:
        [ -a ACCID ] -- account ID
        [ -c CHARNAME ] -- character
        [ -C CHARNAME ] -- all chars on account (account by char)
        [ -p PLAYER ] -- all chars on player

Description
-----------

Use cases:

-   determining time when client was updated to compare to other suspected
    alts. Workflow includes calling _timeline_ on given interval with -p
    option to include results for all known associated alts and then comparing
    them to suspected char by -c option (or -C/-a).
-   compare clients on given time interval by summary statistics. Workflow
    include call of _similar_ subcommand (optionally with -i key to include
    target player chars into top rate) and then _summary_ for chars from
    result.

NOTE: _pattern_ search can be used to match charname since both charname and
      useragent are on same line

Examples
--------

    tmww -a client tmw.org timeline -C Ginaria -n 10 -f 2014-02
    tmww -a client tmw.org summary -p chaosava -m 2
    tmww -a client tmw.org similar -d 7 -n 5 -ip chay
    tmww -a client tmw.org pattern -f 2014-04-10 -t 2014-04-13 -su 'linux.*1.4.1.18' -n 5

Config
------

VERSIONREPORT : string -> ~/log/tmww  
    log path to read client versions reports from version{log|table} plugin

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-alts(1), tmww-activity(1),
tmww-versionlog(1), tmww-versiontable(1)


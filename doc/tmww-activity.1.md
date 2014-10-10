Name
----
activity.plugin - player online activity statistics

Usage
-----

    subcommand: lastseen -- timeline of logon/logoff events
    subcommand: daily -- daily (in hours) online presence
    subcommand: monthly -- monthly (in days) online presence
    subcommand: average -- average online presence per day of week and per hour
    Common options:
        [ -n N ] -- limit output by N lines; default to 1 for all commands
        [ -r ] -- show ruler
        [ -s ] -- split stats and ruler with space after each 10 chars
    - time options:
        [ { -d | -m } N ] -- during N last days/month
        [ -f yyyy-mm[-dd] ] -- start interval
        [ -t yyyy-mm[-dd] ] -- end interval. defaults to current day if omitted
    - target options:
        [ -a ACCID ] -- account ID
        [ -c CHARNAME ] -- character
        [ -C CHARNAME ] -- all chars on account (account by char)
        [ -p PLAYER ] -- all chars on player
        [ -x CHARNAME ] -- exclude CHARNAME from result chars list

Description
-----------

- examine registered logon/logoff timeline
- compare online presence of given characters
- display daily (in hours) and monthly (in days) relative online presence
- display average online presence per day of week and per hour

All functions has kind of limits, e.g. default max days diapason is 150 and max
month diapason is 60. Logon/logoff event maximum count of players also has
default limit of 150.

Lastseen function has 2 working modes. 1st mode choosed with 1 line output
(default, set with -n option) and no provided dates interval. It will search
over all present logs starting from end. Other mode outputting more than 1
record require diapason set in days.

Average output bars are relative to each other. Daily and monthly bars are
absolute with 86400 seconds for monthly bar (full day) and 3600 seconds for
daily (full hour).

Bars can visually merge in two nearby lines. This could be solved choosing in
config lower ticks number.

Bars legend: "-" mean no data, "." mean zero appearance. Default timeout to get
"no data" is 20 minutes - if no events of logon/logoff happened (usually means
record was stopped or server downtime).

Example
-------

    $ tmww -ya activity tmw.org lastseen -f 2014-04-10 -t 2014-04-20 -p ginaria
    $ tmww lastseen -p ginaria
    2014-04/24 15:20:23 off: Ginaria
    $ tmww lastseen -f 2014-04-10 -t 2014-04-20 -p ginaria
    2014-04/16 16:03:39 off: Ginaria
    $ tmww lastseen -c "Seraphim  sama" -n 5
    2014-02/14 02:54:38 off: Seraphim  sama
    2014-02/15 21:53:40 on:  Seraphim  sama
    2014-02/15 23:38:00 off: Seraphim  sama
    2014-02/16 00:25:20 on:  Seraphim  sama
    2014-02/16 16:40:23 off: Seraphim  sama
    $ tmww daily -rp ginaria
    yyyy-mm/dd dow 012345678901234567890123
    2014-04/22 Tue ........................
    2014-04/23 Wed ........................
    2014-04/24 Thu ......▂▇▁▅▃.▄▃.▂..------
    $ tmww monthly -rsp ginaria
    yyyy-mm 1234567890 1234567890 1234567890 1
    2014-04 ---------▁ ▁▁▃▁▂▂.... ...▁------ -
    $ tmww average -rsp ginaria
    MTWTFSS 0123456789 0123456789 0123
    ▃▄▅▇▁▁▃ ....▂▇▅▃▃▅ ▃▁▂▃▂▂▂▃▂▁ ▁...
    $ tmww average -sp ginaria -m 3
    ▄▅▁▇▁▁▃ ....▁▃▄▆▆▇ ▃▃▂▄▄▆▅▅▄▂ ▁▁..

Config
------

VERSIONREPORT : string -> ~/log/tmww  
    log path to read logon/logoff events
SPARKCHARS : string -> 6  
    should be 6 or 7 - number of tick levels in statistics output
STATSPLIT : yes/no -> no  
    split stats and ruler with space after each 10 chars

Bugs
----
Sometimes script time could be choosen way with which new day recieve one/few
events from previous day with time of 23:5x or similar. Default workaround
expects such events within 10 mins.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-log(1), tmww-alts(1)


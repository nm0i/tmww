Name
----
versionlog.plugin - try determine player's client version using online list and client versions log

Description
-----------

.Action format

    versionlog

.Expected input data

Versions file format example:

    [04:01] ManaPlus (Windows; The Mana World; SDL1.2; 4144 v1.3.11.24)

Example location: http://updates.themanaworld.org/versions/2013-12-06.txt

Time (online list and log) expected to be UTC+0.

.Output format

Location: VERSIONREPORT/servername/YYYY-MM/DD.yml

    -   "time": "21:31:47"
        "detected": [ "21:31", "player1", "client1" ]
        "logon": [ "player1", "player2" ]
        "logoff": [ "player3" ]
        "versions": 
            - [ 2, "client2" ]
            - [ 1, "client1" ]
        "clients": 
            - [ "21:31", "client1" ]
            - [ "21:31", "client2" ]
            - [ "21:31", "client2" ]

versions/clients mapping depends on VERSIONSUMMARY option. It doesn't anyhow
affect other scripts, e.g. _client_. Log format is made this way for easy
reading for more extensive information examining target chars. Version logs
stay at logpath and are not deleted.

Config
------

VERSIONURLBASE : quoted : http://updates.themanaworld.org/version/  
    url path where logs are stored
VERSIONREPORT : string : ~/log/tmww  
    result version log location (same as for tmww log plugin)
VERSIONCACHE : string : ~/log/versions  
    destination for downloaded version log files
VERSIONSUMMARY : yes/no : _empty_  
    if _yes_ - print summary of versions like result from versiontable plugin

Example
-------

Default online list update time 20 seconds so if you don't have cron with
seconds discretisation example run looks like:

    $ watch -cpn 20 tmww versionlog

with config "versionlog.conf" containing

    DELTA 10
    actions {
        fetch
        servertime
        summary
        logon
        logoff
        newline
        versionlog
    }

Then you can watch results like this:

    $ cd VERSIONREPORT/servername && tail -f $(date -u +%Y-%m/%d).yml | grep --line-buffered detected

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-log(1), tmww-versiontable(1)


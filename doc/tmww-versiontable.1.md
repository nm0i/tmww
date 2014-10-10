Name
----
versiontable.plugin - try determine player's client version using online list and client versions summary table

Description
-----------

.Action format

    versiontable

.Expected input data

See example versiontable.html in distribution.

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

Version summary html tables stay at log path and are not deleted.

Config
------
VERSIONLINK : quoted -> http://updates.themanaworld.org/versions.php  
    link to download versions summary table
VERSIONREPORT : string -> ~/log/tmww  
    result version log location (same as for tmww log plugin)

Example
-------
Default online list update time 20 seconds so if you don't have cron with
seconds discretisation example run looks like:

    $ watch -cpn 20 tmww versiontable

with config "versiontable.conf" containing

    DELTA 10
    actions {
        fetch
        servertime
        summary
        logon
        logoff
        newline
        versiontable
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
tmww(1), tmww-config(5), tmww-log(1), tmww-versionlog(1)


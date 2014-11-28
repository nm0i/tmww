Name
----
log.plugin - log online activity (who logged on/off and when)

Description
-----------

IMPORTANT: run "log" action only after you performed "fetch"

.crontab example

Using default log.conf:

    */5 * * * * /path/to/tmww log >/dev/null 2>&1

Config
------

LOGPATH : string : ~/log/tmww  
    log dir

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5)


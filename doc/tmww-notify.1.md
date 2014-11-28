Name
----
notify.plugin - popup notification for logon/logoff event

Description
-----------

IMPORTANT: run "notify" action only after you performed "fetch"

.crontab example

    */15 * * * * DISPLAY=:0 TMWW_INSTANCE=notify_fr \
        /path/to/tmww -frd 840 -anotify default friend.list type logon type logoff
    * * * * * DISPLAY=:0 TMWW_INSTANCE=notify_att \
        /path/to/tmww -frd 30 -anotify default attention.list type alarm type logoff

Usage
-----

    LIST [ SOUNDEVENT SOUNDARG [ SOUNDEVENT SOUNDARG ] ]

where LIST is player list to generate logon/logoff events and
SOUNDEVENT/SOUNDARG optional pairs describe logon/logoff sound; see
tmww-config(5) and tmww-mbuzzer(1) for sound details.

Config
------

NOTIFYAGENT : string : /usr/bin/notify-send -t 2000 %t %b  
    execution command; %t substituted with title, %b - with message body
NOTIFYSOCKET : string :

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5)


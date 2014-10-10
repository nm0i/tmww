Name
----
accsniffer - wrapper around accsniffer util

Options
-------

    { start | stop | status }

Description
-----------
Accsniffer require tcpick with granted capabilities.

If _status_ command reported crash, leftover of accsniffer should be killed
with _stop_ and then restarted.

Accsniffer listens on all traffic from server, cuts account ids and calls alts
plugin to store char info. One sniffer per server.

- collects account IDs, resolves matched names from manual playerdb into
  accounts by default (comment out "resolve" commands and uncomment "add"
  inside accsniffer if you don't maintain manual playerdb).
- collects party names
- has simplest cache (default size is 50 names/50 parties)

Requires setup for tcpick same as e.g. wireshark - changing tcpick
group/adding user in group and setting tcpick capabilities:

    # setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpick
    # usermod -a -G wireshark yourmom
    # chgrp wireshark /usr/sbin/tcpick

Example
-------

    $ tmww -a accsniffer tmw.org status

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tcpick(8), tmww(1), tmww-config(5), tmww-alts(1), tmww-pysniffer(1)


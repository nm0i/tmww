Name
----
crime - operations on public GM logs

Synopsis
--------

    crime [-umrfbB]

Options
-------

-u  mirror GM logs folder
-m  cut readable messages
-r  parse logs for ban/block records
-f  fill up player records with ban/block results
-b  GM stats for bans (cumulative with -B)
-B  GM stats for blocks (cumulative with -b)

Config
------

CRIMEPATH : string -> $HOME/log/gm/$servername
    path to GM logs and parsed files

Example
-------

Example cron record for updating players records:

    * 5 * * * tmww crime -upf >/dev/null 2>&1

Option -f sets field "crime" to value "true" if some of known player alts got
ban/block over time. For reverse search use alts/server grep operation:

    $ cd ~/log/gm/server.themanaworld.org/records
    $ tmww grep bbb ban* block*

Bugs
----

-m , -r and -f options perform update using GNU make

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-alts(1), tmww-server(1)


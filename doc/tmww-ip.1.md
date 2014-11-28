Name
----
ip - login server log IPs filter

Usage
-----

    subcommand: domains -- form collision domains
        [ -w FILE ] -- write cache to default path (SERVERSTAFF)
        [ -r FILE ] -- use cache (e.g. formed with "tmww server ip -m2 -w FILE"
            skips date interval settings
        No -w or -r option causes output to stdout
        [ -u ] -- lookup all chars from matched domain IDs
        [ -n ] -- lookup all non-aliased chars from matched domain IDs
    subcommand: matches -- filter matching logins
        [ -g ] -- print date - time - id - ip - geoiplookup
        [ -i ] -- print date - time - id - ip
        [ -s ] -- geoiplookup stats
        No filter options will output lines unchanged.
    Common options:
    - time interval options:
        [ -m N ] -- last N monthes
        [ -d N ] -- last N days
        [ -f YYYY-MM-DD ] -- from date
        [ -t YYYY-MM-DD ] -- to date (optional)
    - char matching options:
        [ -p PLAYER ] -- target player
        [ -c CHAR ] -- target char
        [ -a ID ] -- target by account ID

Format
------

.Example login.log event

    2014-11-11 15:55:44.333: Authentification accepted (account: somelogin (id: 2233445), ip: 222.111.222.111)

.Collision domain format

    {"nids":[],"ids":[],"players":[],"ips":[]}

Files are JSON lines. Each line - one collision domain. Line is mapping with 4 keys:

nids        account IDs not associated with player names
ids         account IDs for known players
players     known players
ips         IPs where intersecting IDs seen

All values are strings.

Config
------

SERVERLOGINLOG : string : $SERVERPATH/login/login.log
    login server log location
SERVERSTAFF : string : $TMP/ip
    path to store preprocessed domains

Example
-------

    # cache whole login server log for all currently known player entries
    $ tmww ip domains -f 2013-01-01 -t 2014-01-01 -w 2013

    # output collision domain
    $ tmww ip domains -r 2013 -p frost

    # output non-associated chars with their ids
    $ tmww ip domains -r 2013 -p frost -n

    # output chars with their ids in matching domain
    $ tmww ip domains -r 2013 -a 2233445 -u

    # output geoiplookup stats
    $ tmww ip matches -f 2013-01-01 -t 2013-12-01 -s

Bugs
----

Default date conversion utilite is GNU date, so e.g. with date without day it
will fail conversion.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-server(1), jq(1)


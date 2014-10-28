Name
----
util - miscellineous uncategorized scripts

Usage
-----

    subcommand: grep PLAYER GREPARGS -- grep text for player alts
    subcommand: find PLAYER -- lookup online player list for player alts
    subcommand: stats LVL [STR AGI VIT INT DEX LUK] -- invoke stats script from $UTILPATH

Description
-----------

Subcommands usually reuse variables and code from other closely related
configs.

.Subcommand grep

    grep PLAYER GREPARGS

Generate pattern from known player chars and do grep. All options after PLAYER
name are passed directly to grep.

.Subcommand find

    find PLAYER

Look if any of known player alts is now online.

.Subcommand stats

    stats LVL [STR AGI VIT INT DEX LUK]

Destribute status points for given level and print points residue.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-alts(1), tmww-server(1)


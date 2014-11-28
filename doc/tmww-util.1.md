Name
----
util - miscellineous uncategorized scripts

Usage
-----

    subcommand: grep PLAYER GREPARGS -- grep text for player alts
    subcommand: find PLAYER -- lookup online player list for player alts
    subcommand: stats LVL [STR AGI VIT INT DEX LUK] -- invoke stats script from $UTILPATH
    subcommand: list -- list operations
        update id ID -- create update files for lists containing ID (user independent)
        update player PLAYER -- same for players (user independent)
        compile LIST -- compile list to PRIVTMP
        install LIST -- compile list + add update files for sniffer
    subcommand: mbuzzer -- pass arguments to mbuzzer util

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

.Subcommand list

    update id ID -- create update files for lists containing ID (user independent)
    update player PLAYER -- same for players (user independent)
    compile LIST -- compile list to PRIVTMP
    install LIST -- compile list + add update files for sniffer

Lists used for any kind of bot ACL, notification, watch and so on. See
tmww-list(7) for details.

.Subcommand mbuzzer

See tmww-mbuzzer(1) for details.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-alts(1), tmww-server(1), tmww-list(7),
tmww-mbuzzer(1)


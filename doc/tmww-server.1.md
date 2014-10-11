Name
----
server.plugin - server text databases operation

Usage
-----

subcommand: char -- character database handler  

    grep [ chars | ids | pcids ] REGEXP -- search known names, output names/names with ids
    fuzzy [ chars | ids | pcids ] PATTERN -- case-insensitive levenshtein distance 1 search
    agrep [ -e ERRORS ] [ chars | ids | pcids ] PATTERN -- approximate grep with max ERRORS
    [-cnar] [-f EXPR] [-s NUM] get { CHAR | [ skills | inventory | vars | id | char | accs | db | FIELD+ ]
        by { char CHAR | pcid PCID } }
    [-cnar] [-f EXPR] [-s NUM] show { CHAR | [ parties | storage | vars | ids | chars | accs | db | FIELD+ ]
        by { char CHAR | id ID | pcid PCID } }
    dig REGEXP -- grep + show pcids by ids from grep matches
    summary [ SUMMARY ] by { char CHAR | id ID | pcid PCID }

subcommand: party -- party database handler  

    get { CHAR | by { char CHAR | pcid PCID } }
    [-cnar] [-f EXPR] [-s NUM] show { CHAR | [ ids | chars | players | accs | db | FIELD+ ]
        by { char CHAR | party PARTY | player PLAYER | pcid PCID } }
    { grep | fuzzy | agrep [ -e ERRORS ] } PATTERN -- grep/approximate grep party name
    dig PATTERN -- grep + show ids/charname of party members

subcommand: player -- players database handler  

    ref -- field types quick reference
    create PLAYER
    remove PLAYER
    rename PLAYER to PLAYER
    add PLAYER FIELD value VALUE
    add PLAYER FIELD element VALUE -- adding alts will automatically resolve charname into account
    resolve PLAYER -- resolve all player alts into accounts
    del PLAYER FIELD
    del PLAYER FIELD element VALUE
    [-cnar] [-f EXPR] [-s NUM] get { CHAR | by { char CHAR | id ACCID | pcid PCID } }
    [-cnar] [-f EXPR] [-s NUM] show { PLAYER | [ ids | chars | parties | accs | db | FIELD+ ]
        by { char CHAR | id ID | pcid PCID } }
    summary [ SUMMARY ] by { char CHAR | id ID | player PLAYER | pcid PCID }
    list with FIELD
    list with { FIELD [ not ] as VALUE | VALUE [ not ] in FIELD }+
    dump PLAYER -- dump JSONline record of PLAYER; tmww player dump veryape
    record NUMBER -- access players db record by it's order number
    append STRING -- NOT SAFE append JSON player record of same format as with dump operation to end of dbplayers
        you should try sanitize operation if you not sure if there are duplicate entries or fields
    keys PLAYER -- tmww player keys veryape
    field PLAYER FIELD [FIELD]... -- tmww player field veryape name aka
    search STRING -- simple search in all fields
    sanitize -- remove keys with 0 length - empty arrays and hashes with null value
        resolve alts into accounts, report duplicate accounts and alts
    lregen -- regenerate shortened playerdb version if limiteddb is in use
    FIXME merge FILENAME -- simple merge player records + sanitize
    FIXME force-merge FILENAME -- replace duplicated records with new ones + sanitize

subcommand: select -- search inventory/storage

    select [-incs] by { ids ITEMID+ | names ITEMNAME+ | re REGEXP | itemsets GLOB+ }

Glossary
--------
Further text operates next terms:

accid, id, accname  
    _accid_ or just _id_ - account ID - first field in server account.txt. Same
    is referenced by athena scripting guide as _rid_. Accid has corresponding
    accname which is second field from account.txt and entered in client login
    field. In game player see other player entities with account ID (which
    explaines delayed rename if player relogs with other character on same
    account).
pcid  
    player character ID - first field from athena.txt; unique for each char;
    changes in case character was deleted and recreated on same account with
    same charname. Used in map-server logs
partyname, partyid  
    server side athena.txt reference characters party by numeric id, party
    names are stored in party.txt
account.txt  
    default "login/save/account.txt"; contains mail, registration date and so on;
    referenced as "ACCOUNTS" file
athena.txt  
    default "world/save/athena.txt"; contain snapshot of character states -
    stats, inventory, pcids, etc.; referenced as "SAVE" or just "DB" file

Doing lookup on map log server.plugin converts:

    player (dbplayers.jsonl) -> accids -> charnames (dbchars.txt) ->
        pcids (athena.txt)

Description
-----------
Short comparison to alts.plugin:

.alts.plugin

terms  
    accid, partyname, charname, playername

operations  

    char { add | resolve | sanitize | merge | get | show | grep | agrep | fuzzy | dig }
    party { add | sanitize | merge | get | show | grep | agrep | fuzzy }
    player { create | remove | rename | ref | add | resolve | del |
        get | show | list | dump | record | append | keys | field | search |
        sanitize | lregen | merge | forcemerge }

.server.plugin

terms  
    accid, pcid, partyname, partyid, charname, playername, db, accs, vars

operations  

    char { get | show | grep | agrep | fuzzy | dig | summary }
    party { get | show | grep | agrep | fuzzy | summary }
    player { create | remove | rename | ref | add | resolve | del |
        get | show | list | dump | record | append | keys | field | search |
        sanitize | lregen | merge | forcemerge | summary }

Aside of "show { ids | parties | players }" there are new "pcids" which are
first column values from athena.txt, "db" which is athena.txt itself formatted
with possible header, "accs" which means lines from account.txt, "vars" -
script variables per char/account.

As with alts.plugin "char get" used for operations on char, "char show" - to
get chars on accounts, "party show" - to get chars in same party and "player
show" to get all chars associated with player alias.

    char [ opts ] get { CHAR | [ skills | inventory | vars | id | char | accs | db | FIELD+ ]
        by { char CHAR | pcid PCID } }
    char [ opts ] show { CHAR | [ parties | storage | vars | ids | chars | accs | db | FIELD+ ]
        by { char CHAR | id ID | pcid PCID } }
    party get { CHAR | by { char CHAR | pcid PCID } }
    party [ opts ] show { CHAR | [ ids | chars | players | accs | db | FIELD+ ]
        by { char CHAR | party PARTY | player PLAYER | pcid PCID } }
    player [ opts ] get { CHAR | by { char CHAR | id ACCID | pcid PCID } }
    player [ opts ] show { PLAYER | [ ids | chars | parties | accs | db | FIELD+ ]
        by { char CHAR | id ID | pcid PCID } }

"char get" is used to perform most inventory-related searches.

"opts" touch only operations with fields like "show { db | accs }".

-c          field captions for custom fields (with FIELDS query)
-n          suppress append accid/charname as last column in db/accs filter
-a          suppress per-char fields and leave only per-account
-r          output raw tab-separated fields without pretty-printing
-f EXPR     override cut fields, EXPR passed as "cut -f" argument value
-s NUM      use backup suffix for all server files; for individual suffix define vars in shell

Output fields names for db/accs could be customized in config sections
"fieldsdb", "fieldsaccs", "fieldsvars" and "serverfieldsalias". There are few
hardcoded field names:

party       lookup of party name
player      lookup player name

"accs" fields output information per account (accid), "db" - per charname. "db"
may be omitted when listing fields defined in fieldsdb.

"inventory", "storage" and "summary" output described in aliases with "server_"
prefix like "server_inventory" in section "itemfieldsalias"; see tmww-db(1) for
details. Column "count" shows item count.

.Operation "summary"

"summary" operation always tries first player alias then chars on account and
performs few built-in calculations:

    char summary [ SUMMARY ] by { char CHAR | id ID | pcid PCID }
    player summary [ SUMMARY ] by { char CHAR | id ID | player PLAYER | pcid PCID }

Standart SUMMARY filters include:

gp (default)  
    for all chars summary += gp on chars and storages per account
bp  
    for all chars summary += bp
exp  
    for all chars summary += lvltable[level] + exp
items  
    for all chars sum up inventory and storage items

Output of gp/bp/exp filters are single integer.

Output format of "summary items" controlled by "server_summary" alias in
"itemfieldsalias" section.

.Subcommand "select"

    select [ OPTS ] by { ids ITEMID+ | names ITEMNAME+ | re REGEXP | itemsets GLOB+ }

Arguments to "itemset" are series of itemset names or quoted glob patterns
matching itemsets.

Options:

-i  include matched item ids
-n  include matched item names
-c  suppress player resolution (only per account info)
-s  single line output (don't split inventory/storage and match lines)

"select" searches inventory/storage. Example output:

    storage of "aaasdsad"; 0123123: bbbb, cccc
    match: ScarabArmlet (621)
    inventory of "aaasadsad"; playerdb alias: asdf, 10 known accounts; 0123123: aaaa
    match: ScarabArmlet (585), Eyepatch (621)

Result may be grepped with "-A 1" or "-B 1" options. Further lookup may be done
with "player/char summary items". See details on item query in tmww-db(1).

Format
------

.athena.txt

    pcid <tab> accid,slot <tab> charname <tab> ?,level,magicklevel? <tab>
        exp,job,zeny <tab> hp,hpmax,mp,mpmax <tab> str,agi,vit,int,dex,luk
        <tab> ?,? <tab> ?,?,? <tab> partyid,?,? <tab> ?,?,? <tab> ?,?,?,?,?
        <tab> map,x,y <tab> respmap,x,y,? <tab> ?????? <tab> inventory

.account.xt

    accid <tab> accname <tab> pwd_hash <tab> date time.usec <tab> gender
        <tab> login_counter <tab> ? <tab> mail <tab> ? <tab> ? <tab> lastip
        <tab> ? <tab> ?

Config
------

WARNING: there's no default value for SERVERPATH

SERVERPATH : string : _empty_  
    server installation path
SERVERSKILLDB : string : $SERVERPATH/world/map/db/skill_db.txt  
    location of skills description file
SERVERATHENA : string : $SERVERPATH/world/save/athena.txt  
    location of athena.txt
SERVERACCOUNT : string : $SERVERPATH/login/save/account.txt  
    location of account.txt
SERVERGM : string : $SERVERPATH/login/save/gm_account.txt  
    location of gm_account.txt
SERVERACCREG : string : $SERVERPATH/world/save/accreg.txt  
    location of accreg.txt
SERVERPARTY : string : $SERVERPATH/world/save/party.txt  
    location of party.txt
SERVERSTORAGE : string : $SERVERPATH/world/save/storage.txt  
    location of storage.txt

Sections
--------

Lines starting with "#" are comments.

.Section "fieldsdb"

    FIELD CSVFIELD FNAME

Line describes how to cut data: FIELD is field number in tab-separated data,
CSVFIELD is field number in comma-separated data within obtained chunk (or
"1"). Prepared data can be referenced as "FNAME" in filter expressions like
"char show".

Server plugin comes with set of default fields, see source for details.

.Section "fieldsaccs"

Format is same as for fieldsdb section.

.Section "fieldsreg"

    ALIAS NAME

Defaults example:

    fieldsaccreg {
        sgp #BankAccount
    }

.Section "serverfieldsalias"

    ALIAS FIELD+

Aliases are processed recursively (some older shells have artificial recursion
limit of ~128 calls); repeated fnames/aliases are simply ignored.

Defaults example:

    serverfieldsalias {
        q1 login mail lvl gp sgp lastip gender
    }

Example
-------

    # show char mail
    $ tcs accs login mail by char Cody

    # show player chars pcids and slot
    $ tps pcid slot by player laguna
    
    # show storage and carried gp for chars in party
    $ tgs lvl by party 'Witch house'
    
    # show all gp owned by players within party
    $ tmww party summary gp by party 'some rogue party'

Notes
-----

.Sort by column

Raw output flag is used for it. Example sort by two fields:

    tp -cr show lvl PC_DIE_COUNTER by player lycan | sort -rnk1,2 | column -ts $'\t'

Default output is sorted by account IDs only.

.Rank known players/left accounts by gp
    
    rank_by_gp() {
        ids=$( mktemp )
        tp nlist with player | while read player; do
            tp ids ${player} >> "${ids}"
            tp summary gp by player ${player}
        done | sort -nr
        athena=$( tmww -g SERVERATHENA )
        aids=$( mktemp )
        cut -f 2 "${athena}" | cut -d ',' -f 1 > "${aids}"
        sort -n "${ids}" | uniq |
            comm --nocheck-order -23 "${aids}" - |
            while read id; do
                tc summary gp by id ${id}
            done | sort -nr
    }

This way you may spot wealthy not-yet-associated aaccounts.
Same ranking may be done for other summary filters, e.g. exp and bp.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-alts(1), tmww-db(1)


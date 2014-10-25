Name
----
alts.plugin - query player database for alt/forum name

Usage
-----

subcommand: char -- character database handler  

    add id ID char CHAR -- add id/char pair to db; write conflicts to log
    resolve id ID char CHAR -- same as add + resolve all matched alts in playerdb into accounts
    grep [ names | ids ] REGEXP -- search known names, output names/names with ids
    fuzzy [ names | ids ] PATTERN -- case-insensitive levenshtein distance 1 search
    get [ [ id ] by char CHAR ] -- get CHAR acc_id
    show [ names | ids | parties ] by id ID -- get all known chars on acc_id
    show [ names | ids | parties ] by char CHAR -- get all known chars on same account as CHAR
    dig REGEXP -- grep + show ids by ids from grep matches
    sanitize -- remove older duplicate entries; write conflicts to log
    merge FILENAME -- put FILENAME into db; write conflicts to log

subcommand: party -- party database handler  

    add party PARTY char CHAR
    get [ by char ] CHAR -- get char's party name
    show [ ids | names | players ] by { party PARTY | char CHAR } -- party members lookup
    { grep | fuzzy } PATTERN -- grep/approximate grep party name
    sanitize -- show duplicates in partydb
    merge FILENAME -- put FILENAME into db; conflicts pushed to db and listed in merge log

subcommand: player -- players database handler  

    ref -- field types quick reference
    create PLAYER
    remove PLAYER
    rename PLAYER to PLAYER
    add PLAYER FIELD value VALUE
    add PLAYER FIELD element VALUE -- adding alts will autoresolve charname into account
    resolve PLAYER -- resolve all player alts into accounts
    del PLAYER FIELD
    del PLAYER FIELD element VALUE
    get { CHAR | by { char CHAR | id ACCID } } -- dereference player entry
    ids PLAYER -- print all known associated account IDs
    show [ ids | names | parties ] by { char CHAR | id CHAR | player PLAYER }
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
    FIXME forcemerge FILENAME -- replace duplicated records with new ones + sanitize

subcommand: arseoscope CHAR -- observe player alias/number of known accounts/alts

subcommand: grep PLAYER GREPARGS -- generate pattern from known player chars and do grep

Glossary
--------

accid, id  
    account ID seen from game client attached to player accounts. Charnames on
    same account has same account ID.
charname  
    character name - name you see in game
party  
    name of party character is in
player  
    player alias in dbplayers, which gathers accounts and alts (with yet
    unknown accid) known to be played by single person under one name
dbchars  
    _dbchars.txt_ - sorted account ID to charname reference
dbparty  
    _dbparty.txt_ - sorted partyname to charname reference
dbplayers  
    _dbplayers.jsonl_ - file describing player aliases - accounts, unresolved
    alts and extra info; IDs found in dbchars are resolved to account IDs in
    player record

Description
-----------
WARNING: alts.plugin require jq of version >= 1.4

tmww plugin *alts* creates and perform all operations/lookup on players alts
database and player lists. Database consists of few per server cleartext/jsonl
files with format described later. 

Player database goal is to combine known accounts and belonged chars under
common alias. Accounts are automatically collected into chars.txt. Alias for
player in players.jsonl contains _accounts_ mapping with known account IDs and
_alts_ mapping with known names but yet unknown account IDs. In case bot which
collect account IDs determine missing account ID it'll remove alt name from
players.jsonl record and instead add account ID.

Most lookup commands expected output of which is single value take only first
matching record. Collision detection is specific for each db.

Players DB in two words: players.db -> records -> fields -> values. Each record
has "player" alias. Character names with unknown account IDs are listed in
"alts" field. Every other known char is referenced over "accounts" field.

Config
------

ALTSPATH : string -> ${DIRCONFIG}/alts  
    DB location
LIMITED : yes/no -> no  
    see notes on _Limited access_
UPDATELIMITED : yes/no -> no  
    see notes on _Limited access_

Notes
-----

NOTE: no _alts_ plugin actions are intended to be called from _actions_
      config section.

Since whole thing is bunch of shell scripts working with text files, there's
improvised lock per server when operation modifies alts db. Timeout is 5
seconds, after which it will skip lock and overwrite temporary files.

Another nasty detail about shell is quotation. It's recommended to use single
quote to prevent shell variables expansion and so on. When you need to put
single quote inside single quote close main quotation and enclose single quote
in double quote; do this

    echo '"chips'"'n'"'fish"'

to achieve this

    "chips'n'fish"

Otherwise use escaping quotes.

For conflict/merge'n'add collision log you should try
_db_path/servername/char_conflicts.log_ or similar name for party conflicts.

.Char operations

Amount of alts on same account limited on query to 30.

By defaul fuzzy search performed from huge slow regexp pattern constructed in
script which is case insensitive, allow 1 absent char or 1 missed char. Fuzzy
pattern will skip spaces and won't accept lot of special chars. See
implementation for details. You can use agrep instead (if you have it). It's
not recommended to run fuzzy search with pattern of less than 4 chars.

On add operation all duplicate chars will be removed to conflicts log. This
operation is safe when character was moved to account with lower id.

Default merge strategy will remove all duplicate entries with lower account ids
to conflicts log. Default chardb format lacks timestamps to correctly resolve
duplicates.

Subcommand sanitize will perform same strategy on chardb without additions.

Subcommand dig is combination of grep + show ids by id for all grep matches.

.Party operations

Amount of alts in same party limited on query to 15.

Subcommand add will move colliding entries to party conflicts log.

Party merge will only combine files and remove duplicates. Collisions should be
removed by hand.

Subcommand sanitize prints partydb duplicate entries.

.Player operations

Player database is JSONlines file with predefined fields with record structure
like this:

    {"player":"asd","field1":"value","field2":["element1","element2"]}

Most operations on players DB performed using jq json swiss army knife. So if
you don't have it or don't want to setup players db fix accsniffer (if you're
using it) tmww operation from "resolve" to "add" - it will only add char into
chardb and skip playerdb.

Records are usually referenced by _player_; there are dedicated commands to
rename and delete entry to lessen typo errors. There are 2 general use cases for
this DB: automatic alts resolve and additional data storage to be then queried.

First case require manual add of elements into _alts_ field, which are char
names and get resolved into account IDs on _sanitize_ or _resolve_ commands or
in future after matching char resolve.

Second case allow storing of associated emails or something like marking of
active developers and tmwc members which allow queries like:

    tmww -a alts default player list with tmwc as true and code in roles

When you need to store single backslash as field value - it will be added as
is. Duplicate backslashes if you want to insert two or more backslashes in
row.

Adding elements will only check if duplicate was in field, it doesn't touch
duplicates in other fields or records. Sanitize won't touch them either, except
_accounts_ and _alts_ fields.

As a measure to preserve original ACL group of db files with multiuser access,
after operations on db files done they are moved back using "cat"; rsync only
preserved permissions but failed to preserve group.

.Sharing altsdb for multiple users

Example setup grants full altsdb access (ALTSPATH) to usergroup simply setting
up group and permissions on altsdb files. Shared LOCK is also required (e.g. in
shared TMP).

IMPORTANT: most probably on fresh run you'll have to touch and chmod db files
           the way you need them (e.g. to disable/enable world read access)

Some altsdb operations assume ACL is set to allow g+w access.

    ALTSPATH /share/folder/alts
    LOCK /shared/folder/.tmp

Sharing limited access to other users should be done with wrapper script above
main tmww to enforce "limited" plugin and filter off modifying commands.

.Limited access

It's possible to provide limited access, e.g. for sharing access to limited db
over whispers. Reason to remove aliases - throw away GMs and conflicting
players + add some information noise, so conflicting users can't freely guess
on chars excluded from access to be desired suspected alts. Limited policy
users should not be able to write to db and should not see own records for
obvious reasons.

    tmww -ya alts tmw.org arseoscope jdoe
    tmww -ya alts limited arseoscope jdoe

Filtered player records are listed in _UTILPATH/lregen.players_ one player
alias per line (empty lines and comments starting with "#" allowed). So if jdoe
was filtered, arseoscope on core db will show jdoe record and jdoe alt on
account, but with limited access will only show jdoe alts on account and no
connected accounts.

Limited base can be regenerated with "player lregen" command or if
UPDATELIMITED config option is set to "yes", limited base will be regenerated
on every update of main base.

Additional lines of upper example:

main config:

    UPDATELIMITED yes

limited access config:

    LIMITED yes

.Using RCS for db archiving

For ease of use it's recommended to keep files under RCS with common prefix,
e.g. dbchars.txt, dbparty.txt, dbplayers.jsonl. RCS will break file
permissions even with ACL enforced; it looks at write permission to check if
file locked; if we need files available for group access and use RCS as reserve
archiver you'll have to manually chmod 660 files (with git it's done setting up
hook).

NOTE: no need for chmod operations for single user install

    Create rcs archive with no default keyword substitution:
    $ mkdir RCS && chmod 660 db* && rcs -i -kk -t-'.' -U -M -q db*

    Initial commit/commit new version:
    $ ci -u -m -q db* && chmod 660 db*

    Show versions:
    $ rlog dbchars.txt

    Show difference between current version and last committed version:
    $ rcsdiff dbchars.txt

    Checkout last committed version:
    $ co -f -q db* && chmod 660 db*

    Checkout particular version (reported from rlog):
    $ co -f1.2 -q db* && chmod 660 db*

Format
------

.dbchars.txt

    acc_id _<space>_ char_name

Corresponding collision log is by default char_conflicts.log.

.dbparty.txt

    partyname _<htab>_ char_name

Corresponding collision log is by default party_conflicts.log.

.dbplayers.jsonl

JSONlines consists of self-sufficient json record per line. Each line is called
here a record. Every record of player.jsonl consists of mappings with
sequences or strings as values. All numbers and bool values should be written
as strings. Bool values convention is "true" and "false". No nested structures
allowed.

Chars allowed for player name are lower/uppercase, digits, space, dash and
underscore but recommended convention for player names is only lowercase with
digits. Field names are forced as lowercase alphabet only.

There's set of predefined field types which is veryfied on "player add" and
"player sanitize" operations. Fields not listed here aren't checked.

Example dbplayers.jsonl record:

    {"player":"jdoe","alts":["alt1"],"accounts":["2112233"],"tmwc":"true"}

.Default string fields

player      fixed player alias
name        IRL name
wiki        full wiki link
trello      full trello link
server      own server
port        login server port on own server
tmwc        _true_ if player is in TMWCommittee
active      _true_ if player is active (more useful to mark
            developers and GMs)
cc          country code (reference taken from IANA domains)

See recommended fields with "tmww player ref"

.Default array fields

forum       tmw.org forum names
aka         IRC names, code signatures, whatever
roles       set of prefedined roles
            recommended values are: "content", "sound",
            "gm","dev", "map", "pixel", "admin", "host",
            "wiki", "advisor", "translator", "packager"
alts        associated charnames
accounts    associated account IDs
links       personal blogs, facebook, other traces
xmpp        xmpp
mail        mail
skype       skype
repo        gitorious/github/bitbucket/whatever
tags        random tags; e.g. to to mark scammers
comments    any comment

See recommended fields with "tmww player ref"

Examples
--------
Next examples demonstrate usage with distributed configs and zsh aliases:

    # char ops

    $ tmww -a alts tmw.org char dig nard
    2172156 Bernard.
    2172156 Nard
    2172156 Nardis
    2172156 Sidran
    2179685 Luxima
    2179685 Marguerite
    2179685 Nard.
    2186035 Cornelius
    2186035 CRC-Nard
    2186035 .Nard
    $ tc grep ids '^nar'
    2115541 naruto
    2121285 Narus
    2172156 Nard
    2172156 Nardis
    2179685 Nard.
    $ tc fuzzy ids tormanov
    2155980 Thormanov
    $ tcs Grim
    Grim
    Grim!
    $ tcg veryape
    2215093
    $ tcsi 2215093
    Grim
    Grim!
    
    # party ops

    $ tgg Nard
    ☽Amaluna☾
    $ tgsp Nard
    2214854 Zirry
    2186438 johannelaliberte
    2088875 mandypinkmind
    2214155 rena
    2224509 Joseph^Sod
    2172156 Nard
    2206252 Rill
    
    # player ops

    # get player alias
    $ tpg Houston
    # this will give alias if present and dump all know alts on same acc
    $ ta Houston
    # show all known alts with ids for alias
    $ tps willee
    # show parties for every char of alias
    $ tpsp willee

    # dump player record
    $ tpd bjorn
    $ tp field Bjorn mail xmpp
    # example queries
    $ tpl cc as de and content in role
    $ tpl code in role and tmwc as true
    $ tpl code in role or admin in role
    $ tp search orziffer

.Example config directory structure

    config/
    ├── lists/
    │   └── server.themanaworld.org/
    │       ├── char_name/
    │       │   ├── auto.guild.fixes
    │       │   ├── auto.guild
    │       │   └── auto.party
    │       ├── guilds/
    │       │   └── CRC
    │       ├── auto.gm
    │       ├── alarm -> friend
    │       ├── bot
    │       ├── friend
    │       └── foe
    ├── alts/
    │   └── server.themanaworld.org/
    │       ├── RCS/
    │       ├── dbchars.txt
    │       ├── char_conflicts.log
    │       ├── dbparty.txt
    │       ├── party_conflicts.log
    │       └── dbplayers.jsonl
    ├── plugins/
    │   ├── accsniffer.plugin
    │   ├── accsniffer.zsh
    │   └── alts.plugin
    ├── utils/
    │   ├── accsniffer
    │   └── validjsonl.py
    ├── default.conf -> tmw.org.conf
    ├── arseoscope.conf
    └── tmw.org.conf

Notes
-----

.Pretty-print playerdb query

    $ tmww player nlist with tmwc as true and active as true |
      while read line; do tmww player dump $line |
      jq -r '"\(.player) (\(.name))\(.mail // empty | " <" + .[] + ">" )"'; done 

which will print only matches with email, so it results in something like
(multiple mails on single record generate multiple lines):

    irukard (Krzysztof Daszuta) <irukard@gmail.com>
    rotonen (Joni Orponen) <j_orponen@hotmail.com>
    wombat (wombat) <hpwombat@yahoo.com>

.How to search forum/charname pairs

Searching player by forum name is done using "player search" command.

Searching forum name of char (assuming charnames in player records are
automagically substituted with accounts) is done by:

1. "player get" + "player field PREV_RESULT forum"
2. "player search" if charname isn't yet in chardb

.How to browse roles

    # print all role tags (recommended and custom)
    jq -r '.roles[]' dbplayers.jsonl 2>&- | sort | uniq -c | sort -rn
    # print all players with specified role
    tp list with pixel in roles

.Number of newbies approaching spot with active accsniffer

    # usage: charseen <N-from-tail> [ <N> ]
    # example: charseen 100; charseen 200 100
    charseen() {
    tail -n "$1" dbchars.txt | head -n "${2:-$1}" |
        cut -d ' ' -f 1 | uniq |
        awk 'NR>1{print $1-a}{a=$1}' | sort -n |
        awk '{a+=$1;b[NR]=$1}
            END{print NR " uniqs, av. " a/NR ", med. " b[int(NR/2)]}'
    }

    $ cd $(tmww -g ALTSPATH) && charseen 100
    88 uniqs, av. 11.25, med. 8

Bugs
----
Results on some operations/queries to check if map:[array] contains exact
element might be unexpected ("jq contains" will return true if pattern is
matched as substring; expression for strict matching was tested where
possible). Few commands has substring check on purpose, e.g. "player list".

Substring matching is case sensitive e.g. in "player list with Chaos in forum",
which will output "axzell", because he has "ChaosCrossAG" forum name, but with
"player list with chaos in forum" is will output "chaosava".

jq 1.4 added -S key to sort hashes allowing more readable diffs. If you have jq
of earlier version just remove -S key from jq calls in _players.lib.sh_ .

Default recommended fields and roles are hardcoded in 4 places: markdown manual
source, plugin, zsh completion and optional validation script.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
jq(1), tmww(1), tmww-config(5), tmww-accsniffer(1), tmww-pysniffer(1)


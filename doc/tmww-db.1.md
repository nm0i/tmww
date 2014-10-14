Name
----
db.plugin - item/mob db lookup (using tmwa-server-data)

Usage
-----

subcommand: item [ OPTS ]  

    get { NAME | [ id | name | db | FIELD+ ] by { id ID | name NAME } }
    show { names | ids | db | FIELD+ } by { ids ID+ | names NAME+ | re REGEXP | itemset ITEMSET }
    mobs by { ids ID+ | names NAME+ | re REGEXP } -- show mobs dropping item/items

subcommand: mob [ OPTS ]  

    get { NAME | [ id | name | db | FIELD+ ] by { id ID | name NAME } }
    show [ names | ids | db | FIELD+ ] by { ids ID+ | names NAME+ | re REGEXP }
    drops by { id ID | name NAME } -- show mob drops

Description
-----------

Options:

c       no fields captions
n       suppress append id/name to fields query
r       output raw tab-separated fields without pretty-printing
f EXPR  custom "cut -f" expression for db filter

Fields for item/mob db are hardcoded as simple order of field names. You should
fix plugin when you fix field order in original files. Field names should be in
query lowercase. Few field names are hardcoded:

typename  
    translates item type to type string like "usable", "head", or "sword"
    typenames are taken from "equip_*" defines in $SERVERDBPATH/const.txt
fname  
    filename (without leading path) which contain match item/mob

"itemset" items filter which tries "ITEMSET.id.itemset" then
"ITEMSET.name.itemset" in $UTILPATH. .name.itemset files contain item name per
line, .id.itemset - ids.

Regexp pattern is case insensitive extended regexp matching subset of item
name (regexp wrapped with ".*" expressions).

Format
------

item_db.txt  

    ID, Name, Label, Type, Price, Sell, Weight, ATK, DEF, Range, Mbonus,
        Slot, Gender, Loc, wLV, eLV, View, {UseScript}

mob_db.txt  

    ID, Name, Jname, LV, HP, SP, EXP, JEXP, Range1, ATK1, ATK2, DEF, MDEF,
        STR, AGI, VIT, INT, DEX, LUK, Range2, Range3, Scale, Race, Element,
        Mode, Speed, Adelay, Amotion, Dmotion,
        Drop1id, Drop1%,
        Drop2id, Drop2%,
        Drop3id, Drop3%,
        Drop4id, Drop4%,
        Drop5id, Drop5%,
        Drop6id, Drop6%,
        Drop7id, Drop7%,
        Drop8id, Drop8%,
        Item1, Item2, MEXP, ExpPer, MVP1id, MVP1per, MVP2id, MVP2per,
        MVP3id, MVP3per, mutationcount, mutationstrength

Config
------

SERVERPATH : string : _empty_  
    server installation path
SERVERDBPATH : string : $SERVERPATH/world/map/db  
    location of item/mob db and supportive files in server data

Sections
--------

Lines starting with "#" are comments.

.Section "mobfiles"

    GLOBPATT

One per line shell glob pattern describing mob files location
relative to SERVERDBPATH. Section data replaces default values.

Defaults example:

    mobfiles {
        *_mob_db.txt
    }

.Section "itemfiles"

    GLOBPATT

One per line shell glob pattern describing item files location
relative to SERVERDBPATH. Section data replaces default values.

.Section "mobfieldsalias"

    ALIAS NAME+

Aliases are processed recursively (some older shells have artificial recursion
limit of ~128 calls); repeated fnames/aliases are simply ignored.

    mobfieldsalias {
         m1 lvl hp sp speed stats
         drops d1id d2id d3id d4id d5id d6id d7id d8id
         fulldrops d1id d1p d2id d2p d3id d3p d4id d4p d5id d5p d6id d6p d7id d7p d8id d8p
         stats str agi vit int dex luk
    }

.Section "itemfieldsalias"

Same as "mobfieldsalias". Default example:

    itemfieldsalias {
        i1 type typename atk def usescript
    }

Bugs
----
Item and mob db fields are tmwa-specific and are hardcoded; default aliases
too; completion updates only aliases defined in config.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-server(1)


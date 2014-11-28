Name
----
tmww - lists format

Lists
-----

Lists have no implied whitelist/blacklist policy. It should be set by
application using list.

.Lists format

Comments start with "#". Empty lines allowed. Any non-comment like is charname.
This part is safe for applications not making use of directives.

Comments may contain directives, following comment sign. Unknown directives
ignored. Directives are ignored when line starts with at least two "#", like:

    ## directive

List compilation depends on filename extension and directives.

.Directives

char  
    used e.g. to include character starting with "#" sign
id  
    include chars from id
chars  
    include chars on same account as char
player  
    include all chars for player
list  
    include list (depends on list extension)
rlist  
    concatenate list name with ROLE (if defined) and include list
exclude  
    exclude result of any valid directive from list

"mode" optional directive with "bl" and "wl" values may be used when
application make use of white/blacklist (only top level mode applied).

.Extensions

list  
    regular list
plist  
    player names list; no directives allowed
alist  
    account IDs list - get all chars on listed chars accounts
clist  
    all non-directive characters are taken as using "chars" directive (all
    chars on account)

.Lists compilation

    config/
    └── lists
        └── server.themanaworld.org
            ├── role
            │   ├── some_list ^1^
            │   └── some_list.fixes ^2^
            ├── gm_list
            ├── some_list ^3^
            └── some_list.fixes ^4^

When "role" is defined, compilation applies list 1, then 2. In general case
list 3 then 4 applied.

list.fixes allow fixes for automatically updated lists, like guild roster.

.Update system

    sniffer on server1
        dbchars, dbplayer
        dir: shared_folder/uplist/server1/user1/
            dir: char1/
                file: guild.ids
            file: list1.ids
            file: list1.updated
            file: list2.ids
    user1
        instance1 - console client
            list1, list2, guild
        instance2 - notifier script
            list1, list2

In this example list1 is updated (indicated by file list1.updated) and should
be recompiled by any instance using this list.

Update system works for multiple instances under multiple users running single
sniffer with shared database.

List is compiled to list.ids with .clist or directives like chars, id and player. List is
compiled to list.players with .plist or player directives.

Config
------

LISTCOMPPATH : string : $PRIVTMP/lists  
    path to store compiled lists (per server)
UPLISTPATH : string : $PRIVTMP/uplists  
    path to store list update files (per server)

Example
-------

    ## example attack list
    # mode bl
    # list friends.list
    # list auto.guild.list
    # list auto.party.list
    # exclude char Sneaky Bandit

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5), tmww-alts(1), tmww-server(1), tmww-accsniffer(1),
tmww-pysniffer(1)


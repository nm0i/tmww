Name
----
tmww - config format documentation

Format
------
Config consists of comments, options and sections. Comments start with #.

Options synthax:

    OPTIONNAME _whitespace_ unquoted_value
    OPTIONNAME _whitespace_ "double-quoted value"

where OPTIONNAME is alphanumeric/underscore, unquoted value is single word,
quoted values have no restriction. Unquoted options are evaluated as is (e.g.
to expand path) so safety advice are same as to shell variables. Options are
available inside script with TMWW_ prefix, e.g. LINK become TMWW_LINK.

Sections synthax:

    SECTIONNAME _whitespace_ {
        [sectionline]...
    }

Sections are not parsed automatically. Example of section parsed in tmww script
is "event" section defining ring tone for event.

Sections may refer to lists, which are stored in $LISTPATH/$servername.

NOTE: lists purpose might be different from storing char names, so it's
      recommended for lists to skip unknown mappings ("key: value")

Configs allows INCLUDE special option to include other config. Only one config
can be included, no recursive inclusions.

Some path variables should be quoted (they are expanded inside plugin). Consult
respective plugin manuals.

Config
------

LINK : quoted : http://server.themanaworld.org/online.html  
    html/txt online list link
LOCALLINK : string : _empty_  
    local tmwa online list
SERVERNAME : string : server.themanaworld.org  
    defines _$servername_; if skipped, _$servername_ is cut from _$LINK_
ROLE : string : main  
    role value for plugins making use of it
INSTANCE : string : common  
    see instances explanation
DELTA : int : 16  
    delay in seconds from last download of online list allowed to skip update;
    see _Instances_ for comment on running multiple instances
DRYRUN : yes/no : no  
    see _Dryrun_ comment
CMDACTION : string : _empty_  
    pass cmdline arguments to defined CMDACTION plugin and skip _actions_ section
CMDPREFIX : string : _empty_  
    prefix cmdline options passed to plugin called from commandline
VERBOSE : yes/no : no  
    output executed plugins names and error codes
PLUGINPATH : string : ~/.config/tmww/plugins  
    neat tmww features
UTILPATH : string : ~/.config/tmww/utils  
    exterior applications/scripts used by plugins
TMP : string : /tmp  
    see notes on TMP
PRIVTMP : string : ~/.tmp  
    see notes on PRIVTMP
LOCK : string : /var/lock  
    lock/PID files
LISTPATH : string : ~/.config/tmww/lists  
    player lists with _$servername_ subfolder
HIGHLIGHT : yes/no : no  
    highlight service messages like 'fetching!', 'servertime' and such (works for 'watch' program)
ANSICAPABLE : yes/no : no  
    see notes on colors
COLORS : yes/no : yes  
    use colors
IPCPATH : string : $PRIVTMP/ipc  
    miscellineous UDS/FIFO path (see plugins for details)
RING : yes/no : no  
    play sound on "ring" action (and matched event)
PLAY : quoted : "play -q"  
    binary to play sound
PLAYDEV : string : _empty_  
    ALSA device pass with as environment variable to PLAY bin
RINGSOCKET : yes/no : no  
    write mbuzzer events to socket instead of playing with _PLAY_
RINGSOCKETFILE : string : $IPCPATH/mbuzzer.socket  
    mbuzzer UDS file
RINGPATH : string : ~/.sound/event  
    default event sounds path
RINGFESTLANG : string : "english"
    festival language
LISTINSTALL : string : no
    default list action (compile if "no", install if "yes"; see tmww-list(7) )
INCLUDE : string : _empty_  
    include other config; see INCLUDE description

Sections
--------

.Section "actions"

    _plugin/function_ [ arguments ]

Actions to perform in order they listed with repective options after action
name. Action which is not built-in tried as plugin.

built-in actions:

fetch       download and process online list (see notes on dryrun in this document)
localfetch  copy local tmwa online list and process it
servertime  print servertime
summary     print number of players online
loggedon    print players logged on
loggedoff   print players logged off
newline     print newline
ring        use default ring
trigger     execute custom commands for logon/logoff events from "trigger" section
external    special word forging action command line and passing it to external executable
event       same as external but only when logon/logoff detected
script      execute script embedded inside section

_ring_ calls _PLAY_ command with argument from _event_ section on matched
event. If _RINGSOCKET_ set to "yes", tmww will send JSON line using mbuzzer
util; see tmww-mbuzzer(1) .

_external_ command passes arguments to external application.

Examples:

    external echo tmp: $TMWW_TMP
    external echo 123 | awk -- "{print \"a $servername b\",\$0,\"c\"}"
    external printf "some variable %s here\n" $TMWW_LINK
    external sleep 2
    event printf "\a"

_script_ executes shell code from defined section. All internal facilities
available. See man section "Script".

.Section "event"

    all { on | off } { event | file | festival } STRING
    list LIST { on | off } { event | file | festival } STRING
    pattern REGEXP { on | off } { event | file | festival } STRING

Rules for RING action. Only last matched event will be played.

Pattern match char names with extended regexp. Lists are taken from LISTPATH,
see tmww-list(7) . "event" matters more with _RINGSOCKET_ var set to "yes"
(event sound symlinks are taken from _RINGPATH_ ). "festival" will send
following data as stdin for festival --tts.

Comments starting with "#" are allowed. This section is empty by default.

.Section "trigger"

    all { on | off } COMMAND
    list LIST { on | off } COMMAND
    pattern REGEXP { on | off } COMMAND

Commands to be called on respective logon/logoff event; e.g. bot launcher
commands (as simple monitor). All lines are checked (except commented lines).

Comments starting with "#" are allowed. This section is empty by default.

.Section "overload"

    lib substituted_libs+

This section is empty by default and used to overload libraries providing
functions with colliding names.

Script action
-------------

_script_ executes shell code from defined section. All internal facilities
available. See man section "Script".

Parameters are taken from actions list. To restore parameters from command
line, do:

    eval set -- "$prefixed_params"

Section should be finished just as any other section with line containing only
"}". Return from "script" action is done with "continue" statement.

NOTE: there are some troubles e.g. with escaping double quotes inside double
      quotes caused by executing from shell eval function, they are easily
      bypassed with single quotes or double/single quotes alteration.

See tmww-plugin(7) for description of tmww provided facilities.

Notes
-----

.Multiple users setup

Script won't do your administrative tasks, so it's necessary that shared
folders (like TMP) are manually created with chgrp and chmod 2770 (ug+rw and
g+s); user umask should be 002 (if no other methods, should be added in
~/.profile), or better of all ACL set with

    setfacl -d -m group:yourgroup:rw shared/

There are two options to check:

1) directory with group write access so group members can remove files
2) files are g+w which most probably require setting up ACL

Operations on shared files require both things but online lists sharing
("fetch" action) will work even without ACL set just with files removed before
write attempt.

    PLUGINPATH /shared/folder/plugins
    UTILPATH /shared/folder/utils
    LOCK /shared/folder/.tmp/lock
    TMP /shared/folder/.tmp

Example
-------
See example_config.conf in distribution.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-plugin(7), tmww-mbuzzer(1)


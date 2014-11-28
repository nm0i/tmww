Name
----
tmww - The Mana World Watcher scripts

Synopsis
--------
tmww [-vhpecbrsy] [-a ACTION] [-d DELTA] [CONFIG [OPTIONS]]

Overview
--------
tmww (The Mana World Watcher) is POSIX compliant shell script performing
miscellaneous subsidiary tasks on tmwa online player list and other game data.
Typical usage includes online list pretty print, notifications if friends are
online and logging of players online presence.

Options
-------
-v  print version and exit
-h  print command line options help and exit
-p  list available plugins and exit
-g  output config variable; e.g. "TMWW_PLUGINPATH=test tmww -g PLUGINPATH"
-u  disallow reusing external variables, e.g. "TMWW_PLUGINPATH=test tmww -ug PLUGINPATH"
-z  dump aliases from zsh completions and exit
-e  output executed plugin names and exit error codes - override VERBOSE; set to "yes"
-c  black & white - override COLORS; set to "no"
-b  unset bold text attribute for service messages - override HIGHLIGHT; set to "no"
-r  override RING; set to "yes"
-s  override RING; set to "no"
-y  override DRYRUN; set to "yes"
-f  override DRYRUN (set to "no") and run "fetch" action before anything else
-a ACTION  
    override CMDACTION;
    options -h and -v after specified action will display help/version for this action
-d DELTA  
    override DELTA for downloading players list
    delta is delay in seconds from last download allowed to skip update
 CONFIG  
    first tried from currend directory, if not found - tried with .conf
    extension in DIRCONFIG

Example calls:

    $ tmww -h
    $ tmww -p
    $ tmww -a alts -h
    $ tmww average -h
    $ tmww -a activity tmw.org average -p ginaria -rsd10
    $ watch tmww -ra watch -d 16 tmw.org

Description
-----------
tmww itself does nothing and serves as wrapper for *plugins*. Plugins performs
*actions*. Each tmww instance is allowed to perform multiple actions described
in config section "actions". Config file may define default CLI action which
will recieve all extra command line arguments. Default action may be overridden
with _-a_ option.

Plugins will print available command line options when "-h" key is given after "-a action" like:

    $ tmww -a alts -h

Help will be displayed when first option after config is "-h" with configs with
predefined command line action.

.Online list parsers

Online list parsers are autoselected depending on online list (referenced by
_LINK_ config option) extension: _.txt_ and _.html_ . tmww should be upgraded
each time online list format is changed.

.Running multiple tmww instances

Multiple tmww instances usually reuse online list. Options solving conflicts
between multiple instances are DELTA, INSTANCE and DRYRUN. Even so tmww will
make use of lock to prevent other instances from running at same time.

DELTA is delay in seconds from last download allowed to skip update (delta =
current epoch seconds - online list modification epoch seconds). Delta variable
make sense for multiple tmww instances running/scheduled (e.g. watch and
notify, so notify with large delta can reuse link downloaded by watch instance
and load it in case watch was not running).

Typical times to reference: fetch default timeout is set to 9 seconds,
server.themanaworld.org online list updates every 20 seconds, per server lock
file abandon delay is hard coded to 10 seconds.

INSTANCE for instances making use of logon/logoff lists and runned with
different DELTA should be different, so e.g. notify instance running every 15
mins will not generate/make incorrect logon/logoff events using same old online
list copy as watch instance running every 5 minutes. When shared online list is
stored in TMP folder, instance temp files are stored in PRIVTMP.

.Temporary folders

There are two temporary folders required: TMP and PRIVTMP. First is used as
shared folder between users and instances, most often storing online list. All
files as folder itself are RW for all. PRIVTMP is where personal "old" copies
of online lists are stored, where lists compiled and so on. Shared TMP can be
also use e.g. for LOCK and DBLOCK with restricted multiuser access.

Default shared TMP folder contents:

tmww-_servername_-raw               raw txt/html file. One per _servername_
tmww-_servername_-online            parsed list with char name per line. One per _servername_
tmww-_servername_-gm                gm list extracted from online list
tmww-_servername_-online.INSTANCE   example name convention of copy of parsed online list
                                    for generating logon/logoff lists
tmww-_servername_-logon             logon events for current running instance
tmww-_servername_-logoff            logoff char names for current instance

Default shipping contains example raw online lists.

.Dryrun

DRYRUN config option will prevent online list fetching and modification of
logon/logoff lists generated from online list copy referenced by INSTANCE
variable; in other words DRYRUN prevents "fetch" action (this action is
responsible for logon/logoff lists generation, backuping and so on).

Use cases:

- situation when you monitor "tmww watch" instance and want to run another
  "tmww watch" instance with different settings but not corrupting main
  logon/logoff reporting.
- debug case: dry run will not fetch online list every time you fire tmww
  instance and will not touch logon/logoff lists
- some plugins only reuse path settings from config and require no online list
  at all

NOTE: DRYRUN may not be supported by plugins fetching additional data on each
      run

Opposite to -y option -f will force "fetch" action before any other action take
place.

.Dependencies

Plugins may define other recommended plugins or dependency plugins. Conflicts
are not resolved automatically. No warnings with conflicting plugins are
displayed. No plugin version checked. All potentially conflicting plugins
should be resolved by hand - not running them simultaneously/on common target.

Example of conflicting plugins: versions and log. Both will duplicate
logon/logoff events and have possibility of simultaneous write to log.

.Utils

Plugins can refer to utils which are searched inside /path/to/config/utils/.
Util path is also used as storage for internal configs and data files.

Files
-----
~/.config/tmww/*.conf  
    default path to configs;
    overridden from env with DIRCONFIG

~/.config/tmww/plugins/*.plugin  
    plugins; used with tmww -a , CMDACTION or in action section
    overridden with PLUGINPATH

~/.config/tmww/plugins/*.lib.sh  
    functions shared between plugins

~/.config/tmww/plugins/*.zsh  
    completion code for plugin/config script; auto-included with OMZ plugin;

~/.config/tmww/utils/
    scripts and misc files/lists/configs reused between plugins and users;
    overridden with UTILPATH

Bugs
----
All shell-related precautions apply here. Plugin-specific bugs covered in
plugin manuals.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww-versionlog(1), tmww-versiontable(1), tmww-activity(1), tmww-alts(1),
tmww-server(1), tmww-accsniffer(1), tmww-client(1), tmww-watch(1),
tmww-db(1), tmww-server(1)

tmww-config(5)  default config, single/multiuser configuration notes
tmww-plugin(7)  how to write plugin
tmww-zsh(7)     completion details


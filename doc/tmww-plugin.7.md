Name
----
tmww - plugins extensibility guide

Description
-----------

.Plugins

All plugins try to use UTC time, server time assumed to be the same.

Plugins utilize functions and variables provided by tmww. Functions recommended
to utilize reside in "common routines" tmww section. Examples of reused variables are:

- system variables like _$FETCH_, _$AWK_ and so on
- $servertime, $servername, _$list\_logon_, _$list\_logoff_, _$list\_online_ and autoupdate lists like _$list\_gm_
- color variables like _$color\_green_ and _$color\_red_ (see notes on using color)

Lot of plugins data is expected to have per-server structure. Server name
accessible by _$servername_ variable is usually determined from online list
variable _LINK_ but could be overriden with _SERVERNAME_.

.Writing plugins

Plugin contains recommended lines available for simple grep, like _conflict_,
_depends_, _recommend_, _whatis_. Plugins should parse command line parameters
themself. Error/warning messages are printed to stderr. Exit from plugin made
only over "return" possibly with return code. Return code > 0 is treated as
error.

Recommended behavior for plugins working with lists - just skip/silently ignore
lines with disallowed chars like double quotes or colon to avoid future
conflicts.

Plugins using logon/logoff events from auto lists like GM should handle copying
such lists theirselves See instances explanation in tmww-config(5).

Make sure you don't build variable names with prefix/suffix so they could be
wrong recognized or use ${} form. Use expand_path to validate path and expand
tilde. If you don't validate integers don't forget to redirect error messages,
like:

    [ "$TMWW_INTEGER" -ne 0 2>/dev/null ] && echo $TMWW_INTEGER

IMPORTANT:  make sure you clear variables starting actions - this is required
            for custom scripts using plugins with runaction

.Standart facilities

See tmww source for implementatio details and existing plugins for usage
examples.

Functions:

- verbose, warning, error, error_params (and derived), check_string_chars
- comm_23, comm_12, make_csv, make_qcsv
- check_lock - sets trap on lock dir
- trap_add
- check_dir
- requireplugin
- runaction (see example in inspect.conf)
- process_section

Variables:

- highlight and color definitions
- err_flag (set from error function)
- uniqifs, backifs
- configdata (set from process_section)
- plugin_options (options passes to plugin on command line or with runaction)
- servername
- lists - list_raw and so on

When reusing plugins functions, "func_" prefixed functions should be used
instead of "aux_" prefixed when possible.

.Colors

tmww defines colors depending on config option ANSICAPABLE. colors are
available then as _color__ prefix + color name, e.g. _color_red_.

Colors and highlight marker are hardcoded as terminal escape sequences.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5)


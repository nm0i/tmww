Name
----
tmww - zsh completion overview

Description
-----------

Things being completed:

- configs
- plugins
- online list charnames
- player aliases from db
- standart fields (string/array)
- standart roles in roles field
- full plugins synthax
- scripts inside configs also can be completed

On zsh start central oh-my-zsh tmww plugin will include all files found in
default plugins path cut from system-wide tmww script executable. These files
define shortcut aliases like

    alias ta="tmww arseoscope"

List of all aliases displayed with:

    $ tmww -z

Next comment lines provide proper descriptions in completion:

file.plugin:

- "# whatis: { description }" -- description in "tmww -p" or "tmww -a <tab>"

file.conf:

- "# zshcompdesc: { plugin -> description }" -- description in "tmww <tab>"
- "# zshcompoverride: { plugin }" -- plugin.zsh overriding action completion
  for custom scripts in configs

Online charnames completion reloads each time you restart completion with tab.

Standart fields and roles for alts.plugin are duplicated multiple times, so one
should do some grep in order to reassign them.

Player aliases completion values are cached and regenerated each weak. As with
any zsh cached completion easiest way to force regeneration - delete old
completion cache. Try "${ZSH}/cache/TMWW_servername".

Integration
-----------

.Manual instructions

Clone oh-my-zsh:

    $ git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh
    $ cp ~/.zshrc ~/.zshrc.orig
    $ cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

Place tmww.plugin.zsh to ${ZSH}/custom/plugins/tmww/ .
Then include "tmww" to plugins array in ~/.zshrc; something like:

    plugins=(git compleat debian tmww)

And reload zsh session.

Example
-------
See example_script.zsh in distribution or default inspect.conf and inspect.zsh.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-config(5)


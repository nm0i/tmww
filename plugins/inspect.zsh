# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

_tmww_plugin_inspect() {
    _tmww_servername
    _arguments \
        '(-)-h[show help]' \
        '-c[add client versions summary to output]' \
        ': :_tmww_arg_chars'
}


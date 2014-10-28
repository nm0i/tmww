# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

alias tgrep="tmww util grep"
alias tfind="tmww util find"
alias tstats="tmww util stats"

#
# code
#
#

_tmww_plugin_util() {
    _tmww_servername
    if [ -n "$_opt_tmww_prefix" ]; then
        _call_function ret _tmww_apply_prefix
    else
        if (( CURRENT == 2 )); then
            local ops; ops=(
                'grep:"PLAYER GREPARGS -- grep text for player alts"'
                'find:"PLAYER -- lookup online player list for player alts"'
                'stats:"LVL [STR AGI VIT INT DEX LUK] -- invoke stats script from $UTILPATH"'
            )
            _alternative "subcommand:subcommand:((${ops}))"
        else
            local cmd; cmd="util_${words[2]}"
            #_tmww_debug cmd $cmd words $words current $CURRENT
            if (( $+functions[_tmww_plugin_${cmd}] )); then
                _arguments "*:: :_tmww_plugin_${cmd}"
            else
                _message "no operation completion available"
            fi
        fi
    fi
}

# PLAYER
_tmww_plugin_util_find() {
    _arguments \
        ': :_tmww_arg_players'
}

# PLAYER GREPARGS
_tmww_plugin_util_grep() {
    _arguments \
        ': :_tmww_arg_players' \
        '*::"grep arguments":_files'
}

# LVL STR AGI VIT INT DEX LUK
_tmww_plugin_util_stats() {
    _arguments \
        ":LVL:" \
        ":STR:" \
        ":AGI:" \
        ":VIT:" \
        ":INT:" \
        ":DEX:" \
        ":LUK:"
}


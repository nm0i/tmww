# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

alias tgrep="tmww util grep"
alias tfind="tmww util find"
alias tstats="tmww util stats"
alias tlist="tmww util list"
alias tbuzzer="tmww util mbuzzer"

#
# config
#
#

# IMPORTANT: using default.conf
#            change this variable if you have custom setup
if (( ! $+_opt_tmww_listpath )); then
    _opt_tmww_listpath=$( tmww -ug LISTPATH )
    eval _opt_tmww_listpath="${_opt_tmww_listpath:-${_opt_tmww_DIRCONFIG}/lists}"
fi

#
# code
#
#

_tmww_arg_lists() {
    local curcontext="${curcontext}:lists" listpath
    listpath="${_opt_tmww_listpath}/${_opt_tmww_servername}"
    _files -W ${listpath} -F "*~"
}

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
                'list:"list operations"'
                'mbuzzer:"pass arguments to mbuzzer util"'
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

_tmww_plugin_util_list() {
    local state
    _arguments \
        "-f[force recompile]" \
        "*:: :->util_list"

    case $state in
        util_list)
            words=("dummy" "${words[@]}")
            CURRENT=$(expr $CURRENT + 1)
            _regex_arguments _cmd /$'[^\0]##\0'/ \
                \( \
                    /$'update\0'/ ":util:util:(update)" \
                    \( \
                        /$'id\0'/ ":util:util:(id)" \
                        /$'[^\0]##\0'/ ":ids:$_desc_arg_id:" \
                    \| \
                        /$'player\0'/ ":util:util:(player)" \
                        /$'[^\0]##\0'/ ":players: :_tmww_arg_players" \
                    \) \
                \| \
                    /$'(compile|install)\0'/ ":util:util:(compile install)" \
                    /$'[^\0]##\0'/ ":files: :_tmww_arg_lists" \
                \)
            _cmd "$@"
            ;;
    esac
}


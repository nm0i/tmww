# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

alias tsum="tmww summary"
alias tsim="tmww similar"

#
# code
#
#

_tmww_plugin_client() {
    local _args_client_ndmft; _args_client_ndmft=(
        "-n[limit output by N lines; default to 2 for all commands]:$_desc_arg_integer:"
        "(-f -t -m)-d[during N last days]:$_desc_arg_integer:"
        "(-f -t -d)-m[during N last months]:$_desc_arg_integer:"
        "(-d -m)-f[start interval of yyyy-mm<-dd> format]:$_desc_arg_date:"
        "(-d -m)-t[end interval of yyyy-mm<-dd> format; defaults to current day if omitted]:$_desc_arg_date:"
    )
    local _args_client_acCp; _args_client_acCp=(
        "(-c -C -p)-a[account ID]:$_desc_arg_id:"
        "(-a -C -p)-c[charname]: :_tmww_arg_chars"
        "(-a -c -p)-C[all chars on account (account by char)]: :_tmww_arg_chars"
        "(-a -c -C)-p[all chars on player]: :_tmww_arg_players"
    )
    local _args_client_i; _args_client_i=(
        "-i[include target player chars (only for <similar> subcommand)]"
    )
    local _args_client_su; _args_client_su=(
        "-s[pattern case sensitivity (only for <pattern> subcommand)]"
        "-u[client version (useragent) search pattern, e.g. <Linux.*1.4.1.18>]:$_desc_arg_regexp:"
    )

    # extract servername from config
    # required for chars completion
    _tmww_servername

    if [ -n "$_opt_tmww_prefix" ]; then
        _call_function ret _tmww_apply_prefix
    else
        if (( CURRENT == 2 )); then
            local ops; ops=(
                'timeline:"tail detected clients log in order of records"'
                'similar:"chars top list detected to use most frequent client version"'
                'summary:"top list of most frequent detected versions for char/player"'
                'pattern:"chars top list on time interval with client names matching pattern"'
            )
            _alternative "subcommand:subcommand:((${ops}))"
        else
            local cmd; cmd="client_${words[2]}"
            #_tmww_debug cmd $cmd words $words current $CURRENT
            if (( $+functions[_tmww_plugin_${cmd}] )); then
                _arguments "*:: :_tmww_plugin_${cmd}"
            else
                _message "no operation completion available"
            fi
        fi
    fi
}

# timeline  a:c:C:p:n:d:m:f:t:
_tmww_plugin_client_timeline() {
    _arguments "${_args_client_acCp[@]}" "${_args_client_ndmft[@]}"
}

# similar   ia:c:C:p:n:d:m:f:t:
_tmww_plugin_client_similar() {
    _arguments "${_args_client_acCp[@]}" "${_args_client_ndmft[@]}" "${_args_client_i[@]}"
}

# summary   a:c:C:p:n:d:m:f:t:
_tmww_plugin_client_summary() {
    _arguments "${_args_client_acCp[@]}" "${_args_client_ndmft[@]}"
}

# pattern   sn:d:m:f:t:u:
_tmww_plugin_client_pattern() {
    _arguments "${_args_client_acCp[@]}" "${_args_client_ndmft[@]}" "${_args_client_su[@]}"
}


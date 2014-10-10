# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

# be aware of conflict with td (textdraw)
alias td="tmww daily"
alias tm="tmww monthly"
alias tv="tmww activity"
alias tl="tmww lastseen"

#
# code
#
#

_desc_arg_date="yyyy-mm[-dd]"

_tmww_plugin_activity() {
    local _args_activity_dft; _args_activity_dft=(
        "(-f -t -m)-d[during N last days]:$_desc_arg_integer:"
        "(-d -m)-f[start interval of yyyy-mm<-dd> format]:$_desc_arg_date:"
        "(-d -m)-t[end interval of yyyy-mm<-dd> format; defaults to current day if omitted]:$_desc_arg_date:"
    )
    local _args_activity_m; _args_activity_m=(
        "(-f -t -d)-m[during N last months]:$_desc_arg_integer:"
    )
    local _args_activity_n; _args_activity_n=(
        "-n[limit output by N lines; default to 2 for all commands]:$_desc_arg_integer:"
    )
    local _args_activity_acCp; _args_activity_acCp=(
        "(-c -C -p)-a[account ID]:$_desc_arg_id:"
        "(-a -C -p)-c[charname]: :_tmww_arg_chars"
        "(-a -c -p)-C[all chars on account (account by char)]: :_tmww_arg_chars"
        "(-a -c -C)-p[all chars on player]: :_tmww_arg_players"
    )
    local _args_activity_x; _args_activity_x=(
        "*-x[exclude CHARNAME from result chars list]: :_tmww_arg_chars"
    )
    local _args_activity_rs; _args_activity_rs=(
        "-r[show ruler]"
        "-s[split stats and ruler with space after each 10 chars]"
    )

    # extract servername from config
    # required for chars completion
    _tmww_servername

    if [ -n "$_opt_tmww_prefix" ]; then
        _call_function ret _tmww_apply_prefix
    else
        if (( CURRENT == 2 )); then
            local ops; ops=(
                'lastseen:"timeline of logon/logoff events"'
                'daily:"daily (in hours) online presence"'
                'monthly:"monthly (in days) online presence"'
                'average:"average online presence per day of week and per hour"'
            )
            _alternative "subcommand:subcommand:((${ops}))"
        else
            local cmd; cmd="activity_${words[2]}"
            #_tmww_debug cmd $cmd words $words current $CURRENT
            if (( $+functions[_tmww_plugin_${cmd}] )); then
                _arguments "*:: :_tmww_plugin_${cmd}"
            else
                _message "no operation completion available"
            fi
        fi
    fi
}

# lastseen  a:c:C:p:x:n:d:f:t:
_tmww_plugin_activity_lastseen() {
    _arguments "${_args_activity_acCp[@]}" "${_args_activity_dft[@]}" "${_args_activity_x[@]}" "${_args_activity_n[@]}"
}

# daily     rsa:c:C:p:x:d:f:t:
_tmww_plugin_activity_daily() {
    _arguments "${_args_activity_acCp[@]}" "${_args_activity_dft[@]}" "${_args_activity_x[@]}" "${_args_activity_rs[@]}"
}

# monthly   rsa:c:C:p:x:d:m:f:t:
_tmww_plugin_activity_monthly() {
    _arguments "${_args_activity_acCp[@]}" "${_args_activity_dft[@]}" "${_args_activity_x[@]}" "${_args_activity_m[@]}" "${_args_activity_rs[@]}"
}

# average   rsa:c:C:p:x:d:m:f:t:
_tmww_plugin_activity_average() {
    _arguments "${_args_activity_acCp[@]}" "${_args_activity_dft[@]}" "${_args_activity_x[@]}" "${_args_activity_m[@]}" "${_args_activity_rs[@]}"
}


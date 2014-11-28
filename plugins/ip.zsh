# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

#
# config
#
#

# IMPORTANT: using default.conf
#            change this variable if you have custom setup
if (( ! $+_opt_tmww_ipcachepath )); then
    _opt_tmww_ipcachepath=$( tmww -ug SERVERSTAFF )
    eval _opt_tmww_ipcachepath="${_opt_tmww_ipcachepath:-${_opt_tmww_sharedtmp}/ip}"
fi

#
# code
#
#

_tmww_arg_ipcache() {
    _files -W "${_opt_tmww_ipcachepath}" -F "*~"
}

_tmww_plugin_ip() {
    local _args_ip_interval; _args_ip_interval=(
        "(-f -t -m)-d[during N last days]:$_desc_arg_integer:"
        "(-f -t -d)-m[during N last months]:$_desc_arg_integer:"
        "(-d -m)-f[start interval]:date:"
        "(-d -m)-t[end interval; defaults to current day if omitted]:date:"
    )
    local _args_ip_char; _args_ip_char=(
        "(-c -p)-a[account ID]:$_desc_arg_id:"
        "(-a -p)-c[ID of charname]: :_tmww_arg_chars"
        "(-a -c)-p[all IDs on player]: :_tmww_arg_players"
    )
    local _args_ip_domains; _args_ip_domains=(
        "(-w)-r[read from cache file]: :_tmww_arg_ipcache"
        "(-r -a -c -p)-w[write cache to default path (SERVERSTAFF)]: :_tmww_arg_ipcache"
        "(-u)-n[lookup all non-aliased chars from matched domain IDs]"
        "(-n)-u[lookup all chars from matched domain IDs]"
    )
    local _args_ip_matches; _args_ip_matches=(
        "(-i -s)-g[print date - time - id - ip - geoiplookup]"
        "(-g -s)-i[print date - time - id - ip]"
        "(-i -g)-s[geoiplookup stats]"
    )
    _tmww_servername
    if [ -n "$_opt_tmww_prefix" ]; then
        _call_function ret _tmww_apply_prefix
    else
        if (( CURRENT == 2 )); then
            local ops; ops=(
                'domains:"form collision domains"'
                'matches:"filter matching logins"'
            )
            _alternative "subcommand:subcommand:((${ops}))"
        else
            local cmd; cmd="ip_${words[2]}"
            #_tmww_debug cmd $cmd words $words current $CURRENT
            if (( $+functions[_tmww_plugin_${cmd}] )); then
                _arguments "*:: :_tmww_plugin_${cmd}"
            else
                _message "no operation completion available"
            fi
        fi
    fi
}

_tmww_plugin_ip_domains() {
    _arguments "${_args_ip_interval[@]}" "${_args_ip_char[@]}" "${_args_ip_domains[@]}"
}

_tmww_plugin_ip_matches() {
    _arguments "${_args_ip_interval[@]}" "${_args_ip_char[@]}" "${_args_ip_matches[@]}"
}


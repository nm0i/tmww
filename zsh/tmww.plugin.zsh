# The Mana World Watcher completion
# gpl 3, willee, 2014

#
# config
#
#

zstyle ':completion:*:*:tmww:*' verbose yes
zstyle ':completion:*:*:tmww:*:descriptions' format '%B%d%b'
zstyle ':completion:*:*:tmww:*:messages' format '%B%d%b'
zstyle ':completion:*:*:tmww:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:*:tmww:*' group-name ''

# with _opt_tmww_debug set to "yes" make sure to run "tail -f" if you created debug file with mkfifo
_opt_tmww_debug="no"
_debug_file=~/temp/debug_pipe

_tmww_def_servername="server.themanaworld.org"

_tmww_debug() {
    [ "${_opt_tmww_debug}" = "yes" ] && echo "$@" > $_debug_file
}

# grab default config path as _opt_tmww_DIRCONFIG from tmww itself
eval _opt_tmww_$( sed -n '/DIRCONFIG=/{p;q};15q' `command -v tmww 2>/dev/null` )

# IMPORTANT: action override is completed before config but plugins path may be changed using config
#            in any way using default.conf
#            feel free to change if you use custom setup
_opt_tmww_pluginpath=$( sed -n '/^ *PLUGINPATH /{s/^ *PLUGINPATH  *//p;q};15q' ${_opt_tmww_DIRCONFIG}/default.conf )
eval _opt_tmww_pluginpath="${_opt_tmww_pluginpath:-${_opt_tmww_DIRCONFIG}/plugins}"
#_tmww_debug pluginpath ${_opt_tmww_pluginpath}

# IMPORTANT: using default.conf
#            change this variable if you have shared tmp in different location
_opt_tmww_sharedtmp=$( sed -n '/^ *TMP /{s/^ *TMP  *//p;q};15q' ${_opt_tmww_DIRCONFIG}/default.conf )
eval _opt_tmww_sharedtmp="${_opt_tmww_sharedtmp:-/tmp}"
#_tmww_debug sharedtmp ${_opt_tmww_sharedtmp}

_desc_arg_string="string"
_desc_arg_integer="integer number"
_desc_arg_file="file"
_desc_arg_regexp="regexp"

#
# code
#
#

typeset -A opt_args
local _opt_tmww_mainopts _opt_tmww_action _opt_tmww_prefix
local tmp

# grab configs with descriptions from hardcoded path
if (( ! $+_opt_tmww_configs )); then
    typeset -a _opt_tmww_configs
    for i in "${(@f)$(cd ${_opt_tmww_DIRCONFIG} && ls *.conf)}"; do
        tmp=$(sed -n '/^# zshcompdesc:/{s/^# zshcompdesc:  *//p;q};15q' ${_opt_tmww_DIRCONFIG}/$i)
        if [ -n "${tmp}" ]; then
            tmp="${i%%.conf}:${tmp}"
        else
            tmp="${i%%.conf}"
        fi
        #_tmww_debug configs "${tmp}, $i"
        _opt_tmww_configs+=("\"${tmp}\"")
    done
fi

# grab plugins with descriptions from default path
if (( ! $+_opt_tmww_plugins )); then
    typeset -a _opt_tmww_plugins
    for i in "${(@f)$(cd ${_opt_tmww_pluginpath} && ls *.plugin)}"; do
        tmp=$(sed -n '/^# whatis:/{s/^# whatis:  *//p;q};15q' ${_opt_tmww_pluginpath}/$i)
        if [ -n "${tmp}" ]; then
            tmp="${i%%.plugin}:${tmp}"
        else
            tmp="${i%%.plugin}"
        fi
        #_tmww_debug plugins "${tmp}, $i"
        _opt_tmww_plugins+=("\"${tmp}\"")
    done
fi

_tmww_wrapper() {
    local curcontext="$curcontext" expl state state_descr context line ign args ret=1

    # vhpecbrsya:d:
    local commands; commands=(
        '(-)-v[print version and exit]'
        '(-)-h[print command line options help or selected action help and exit]'
        '(-)-p[list available plugins and exit]'
        '-e[output executed plugin names and exit error codes - override VERBOSE; set to "yes"]'
        '-c[black & white - override COLORS; set to "no"]'
        '-b[unset bold text attribute for service messages - override HIGHLIGHT; set to "no"]'
        '(-s)-r[override RING; set to "yes"]'
        '(-r)-s[override RING; set to "no"]'
        '-y[override DRYRUN; set to "yes"]'
        '-d+[override DELTA for downloading players list (see manpage)]:integer DELTA in seconds; default is 20:'
    )
    
    _opt_tmww_mainopts=$words

    _arguments -s -S $commands[@] \
        "-a+[override CMDACTION; option -h after specified action display action usage and exit]: :->actions" \
        '*::config:_tmww_config'
            
    case "$state" in
        actions)
            _alternative "actions:supplied action plugins:((${_opt_tmww_plugins}))"
            ;;
    esac
}

_tmww_config() {
    local tmp cmd
    if (( CURRENT == 1 )); then
        _alternative "defconf:supplied configs:((${_opt_tmww_configs}))" \
            "fileconf:user config file:_path_files -g \*.conf" || \
                _message "unknown option or config: $words[CURRENT]"
    else
        _opt_tmww_action=''; _opt_tmww_prefix=''
        # crop cli defined action
        # not safe
        # getting array key with something like ${(k)opt_args[(r)alts]} failed with joined opts like -baalts
        _tmww_util_action() { local act; zparseopts -E a:=act 2>&-; echo "${act[2]}"; }
        _opt_tmww_action=$( eval _tmww_util_action $_opt_tmww_mainopts 2>&- )
 
        _opt_tmww_target_conf="${_opt_tmww_DIRCONFIG}/${words[1]}.conf"
        if [ -z "$_opt_tmww_action" -a -f "${_opt_tmww_target_conf}" ]; then
            # now try to cut action/prefix from provided config
            # searching only first definition in provided config; skipping includes
            _opt_tmww_action=$( sed -n '/^# zshcompoverride: /{s/^# zshcompoverride:  *//p;q}' ${_opt_tmww_target_conf})
            [ -z "${_opt_tmww_action}" ] && \
                _opt_tmww_action=$( sed -n '/^ *CMDACTION/{s/^ *CMDACTION  *//p;q}' ${_opt_tmww_target_conf})
            _opt_tmww_prefix=$( sed -n '/^ *CMDPREFIX/{s/^ *CMDPREFIX  *//p;q}' ${_opt_tmww_target_conf} )
        fi
        
        #_tmww_debug action "$_opt_tmww_action" "$_opt_tmww_prefix"

        if (( $+functions[_tmww_plugin_$_opt_tmww_action] )); then
            _call_function ret _tmww_plugin_$_opt_tmww_action || _message 'no more arguments'
        else
            _message "action has no completion"
        fi
    fi
}

#
# shared
#
#

_tmww_apply_prefix() {
    if (( $+functions[_tmww_plugin_${_opt_tmww_action}_${_opt_tmww_prefix}] )); then
        _call_function ret _tmww_plugin_${_opt_tmww_action}_${_opt_tmww_prefix} || _message 'no more arguments'
    else
        _message "no completion for prefixed action"
    fi
}

_tmww_servername() {
    _opt_tmww_servername=$( sed -n '/^ *SERVERNAME /{s/^ *SERVERNAME  *//p;q};15q' "${_opt_tmww_target_conf}" )
    [ -z "${_opt_tmww_servername}" ] && {
        _opt_tmww_servername=$( sed -n '/^ *LINK /{s/^ *LINK  *//p;q};15q' "${_opt_tmww_target_conf}" )
        # validate link
        case "${_opt_tmww_servername}" in
            http://*/?*.*)
                # extract server name
                _opt_tmww_servername="${_opt_tmww_servername#http://}"
                _opt_tmww_servername="${_opt_tmww_servername%%/*}"
                ;;
        esac
    }
    eval _opt_tmww_servername="${_opt_tmww_servername:-${_tmww_def_servername}}"
    #_tmww_debug ${_opt_tmww_servername}
}

compdef _tmww_wrapper tmww

for i in "${_opt_tmww_pluginpath}"/*.zsh; do
    . $i
done


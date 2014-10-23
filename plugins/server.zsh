# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3
#
alias sp="tmww splayer"
alias sps="tmww splayer show"
# alias spsi="tmww splayer show ids by id"
# alias spsc="tmww splayer show ids by char"
alias spsi="tmww splayer show parties by id"
alias spsc="tmww splayer show parties by char"
alias spd="tmww splayer dump"
alias spg="tmww splayer get"
alias spgi="tmww splayer get by id"
alias spu="tmww splayer summary"

alias sx="tmww sparty"
alias sxg="tmww sparty get"
alias sxs="tmww sparty show ids by char"
alias sxsp="tmww sparty show players by char"

alias sc="tmww schar"
alias scd="tmww schar dig"
alias scs="tmww schar show"
alias scsi="tmww schar show by id"
alias scg="tmww schar get"
alias scu="tmww schar summary"

# reusing "tmww arseoscope" alias (default "ta") from alts.zsh

alias ssel="tmww select"

#
# config
#
#

zmodload zsh/mapfile

# comment next line if you don't want to generate altsdb players completion
_opt_tmww_use_altdb=1

# IMPORTANT: using default.conf
#            change this variable if you have custom setup
if (( ! $+_opt_tmww_altspath )); then
    _opt_tmww_altspath=$( tmww -ug ALTSPATH )
    eval _opt_tmww_altspath="${_opt_tmww_altspath:-${_opt_tmww_DIRCONFIG}/alts}"
fi

# IMPORTANT: using default.conf
#            change this variable if you have custom setup
if (( ! $+_opt_tmww_serverdbpath )); then
    _opt_tmww_serverdbpath=$( tmww -ug SERVERDBPATH )
    eval _opt_tmww_serverdbpath="${_opt_tmww_serverdbpath:-${HOME}/tmwAthena/tmwa-server-data/world/map/db}"
fi

_desc_select="select subcommand completion"
_desc_arg_pcid="PCID [0-9]{6}"
_desc_arg_partyid="PARTYID [0-9]"

#
# code
#
#

# relying on code from alts.zsh
# skipping _tmww_arg_players, cache regen criterias
# skipping _tmww_arg_chars

typeset -a _tmww_server_config_fieldsdb _tmww_server_config_fieldsaccs _tmww_server_config_fieldsreg _tmww_server_config_serverfieldsalias

_tmww_server_config_fieldsdb=( "${(@f)$(awk -- '
    /^fieldsdb \{/{a=1}/^\}$/&&a{exit}(a+0)>1{print $3}a{a+=1}' \
    ${_opt_tmww_DIRCONFIG}/default.conf )}" )

_tmww_server_config_fieldsaccs=( "${(@f)$(awk -- '
    /^fieldsaccs \{/{a=1}/^\}$/&&a{exit}(a+0)>1{print $3}a{a+=1}' \
    ${_opt_tmww_DIRCONFIG}/default.conf )}" )

_tmww_server_config_fieldsreg=( "${(@f)$(awk -- '
    /^fieldsreg \{/{a=1}/^\}$/&&a{exit}(a+0)>1{print $1}a{a+=1}' \
    ${_opt_tmww_DIRCONFIG}/default.conf )}" )

_tmww_server_config_serverfieldsalias=( "${(@f)$(awk -- '
    /^serverfieldsalias \{/{a=1}/^\}$/&&a{exit}(a+0)>1{print $1}a{a+=1}' \
    ${_opt_tmww_DIRCONFIG}/default.conf )}" )

# db ops specific options
_tmww_args_server=(
    "-c[field captions for custom fields (with FIELDS query)]"
    "-n[suppress append accid/charname as last column in db/accs filter]"
    "-a[suppress per-char fields and leave only per-account]"
    "-t[append target when possible for summary commands]"
    "-r[output raw tab-separated fields without pretty-printing]"
    "-f[override cut fields, EXPR passed as cut -f argument value]:cut -f expression:"
    "-s[use backup suffix for all server files; for individual suffix define vars in shell]:db backup suffix:"
    )

# db ops specific options
_tmww_args_select=(
    "-i[include matched item ids]"
    "-n[include matched item names]"
    "-c[suppress player resolution (only per account info)]"
    "-s[single line output (do not split inventory/storage and match lines)]"
    )

_tmww_plugin_server() {
    local -a _tmww_server_fieldsdb _tmww_server_fieldsaccs _tmww_server_fieldsreg _tmww_server_serverfieldsalias

    _tmww_server_fieldsdb=( pcid accid slot lvl exp job gp
        str agi vit int dex luk partyid fstats fskills fvars )

    _tmww_server_fieldsaccs=( login hash date g counter mail lastip )
    _tmww_server_fieldsreg=( sgp )
    _tmww_server_serverfieldsalias=( player party pid zeny agp stats qdb gender accname seen ip qacc q1 )

    # extract servername from config
    _tmww_servername

    # reusing alts.zsh policy
    local update_policy
    zstyle -s ":completion:*:*:tmww:*:alts:" cache-policy update_policy
    if [[ -z "$update_policy" ]]; then
        zstyle ":completion:*:*:tmww:*:alts:" cache-policy _cache_policy_tmww_players
    fi

    if [ -n "$_opt_tmww_prefix" ]; then
        _call_function ret _tmww_apply_prefix
    else
        if (( CURRENT == 2 )); then
            local ops; ops=(
                'char:"characters db operations"'
                'party:"party operations"'
                'player:"operations on JSONlines players database"'
                'arseoscope:"compact CHARNAME description - accounts known, chars on same account"'
                'select:"search chars by inventory and storage"'
            )
            _alternative "subcommand:subcommand:((${ops}))"
        else
            local cmd; cmd="server_${words[2]}"
            #_tmww_debug cmd $cmd words $words current $CURRENT
            if (( $+functions[_tmww_plugin_${cmd}] )); then
                _arguments "*:: :_tmww_plugin_${cmd}"
            else
                _message "no operation completion available"
            fi
        fi
    fi
}

#
# char ops
#
#

_tmww_plugin_server_char() {
    _arguments -s \
        "${_tmww_args_server[@]}" \
        "*:: :_tmww_plugin_server_char_args"
}

_tmww_plugin_server_char_args() {
    if (( CURRENT == 1 )); then
        local ops; ops=(
            'grep:"[ chars | ids ] REGEXP -- search known chars, output chars/chars with ids"'
            'fuzzy:"[ chars | ids ] PATTERN -- case-insensitive levenshtein distance 1 search"'
            'agrep:"[ -e ERRORS ] [ chars | ids ] REGEXP -- approximate search"'
            'get:"{ CHAR | [ id ] by char CHAR } -- get account id of CHAR"'
            'show:"{ CHAR | [ chars | ids ] by { id ID | char CHAR } } -- get all known chars on acc_id"'
            'dig:"REGEXP -- grep + show ids by ids from grep matches"'
            'summary:"{ gp | bp | exp | items } by { char CHAR | id ID | pcid PCID }"'
        )
        _alternative "subop:subcommand operation:((${ops}))"
    else
        local cmd; cmd="server_char_${words[1]}"
        if (( $+functions[_tmww_plugin_${cmd}] )); then
            words=("dummy" "${words[@]}")
            CURRENT=$(expr $CURRENT + 1)
            _arguments "*:: :_tmww_plugin_${cmd}"
        else
            _message "no operation completion available"
        fi
    fi
}

# dig REGEXP
_tmww_plugin_server_char_dig() {
    _arguments \
        ":$_desc_arg_regexp:"
}

# grep [ chars | ids ] REGEXP
_tmww_plugin_server_char_grep() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            /$'(chars|ids)\0'/ ":char:$_desc_char:(chars ids)" \
            /$'[^\0]##\0'/ ":chars:$_desc_arg_regexp:" \
        \| \
            /$'[^\0]##\0'/ ":chars:$_desc_arg_regexp:" \
        \)
    _cmd "$@"
}

# agrep [ -e ERRORS ] [ chars | ids ] REGEXP
_tmww_plugin_server_char_agrep() {
    local state
    _arguments \
        "-e[number of errors]:$_desc_arg_integer:" \
        "*:: :->agrep"

    case $state in
        agrep)
            # feel free to fix whenever you find right synthax
            # not breaking internals for _regex_arguments after _arguments
            words=("dummy" "${words[@]}")
            CURRENT=$(expr $CURRENT + 1)
            _regex_arguments _cmd /$'[^\0]##\0'/ \
                \( \
                    /$'(chars|ids)\0'/ ":char:$_desc_char:(chars ids)" \
                    /$'[^\0]##\0'/ ":chars:$_desc_arg_regexp:" \
                \| \
                    /$'[^\0]##\0'/ ":chars:$_desc_arg_regexp:" \
                \)
            _cmd "$@"
            ;;
    esac
}

# fuzzy [ chars | ids ] FUZZY
_tmww_plugin_server_char_fuzzy() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            /$'(chars|ids)\0'/ ":char:$_desc_char:(chars ids)" \
            /$'[^\0]##\0'/ ":chars:$_desc_arg_fuzzy:" \
        \| \
            /$'[^\0]##\0'/ ":chars:$_desc_arg_fuzzy:" \
        \)
    _cmd "$@"
}

# get { CHAR | [ skills | inventory | vars | id | char | accs | db | FIELD+ ] by { char CHAR | pcid PCID } }
_tmww_plugin_server_char_get() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            \( \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \| \
                /$'(skills|inventory|vars|id|char|accs|db)\0'/ ":char:$_desc_char:(skills inventory vars id char accs db)" \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \| \
                \( \
                    /$'([^\0]##\0~by\0)'/ ":fieldsdb:db fields:(${_tmww_server_fieldsdb})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsaccs:accs fields:(${_tmww_server_fieldsaccs})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsreg:reg fields:(${_tmww_server_fieldsreg})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsalias:fields aliases:(${_tmww_server_serverfieldsalias})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsdb:db fields from default config:(${_tmww_server_config_fieldsdb})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsaccs:accs fields from default config:(${_tmww_server_config_fieldsaccs})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsreg:reg fields from default config:(${_tmww_server_config_fieldsreg})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsalias:fields aliases from default config:(${_tmww_server_config_serverfieldsalias})" \
                \) \
                \# \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \) \
            \( \
                /$'pcid\0'/ ":char:$_desc_char:(pcid)" \
                /$'[^\0]##\0'/ ":char:$_desc_arg_pcid:" \
            \| \
                /$'char\0'/ ":char:$_desc_char:(char)" \
                /$'[^\0]##\0'/ ':char: :_tmww_arg_chars' \
            \) \
        \| \
            /$'[^\0]##\0'/ ':char: :_tmww_arg_chars' \
        \)
    _cmd "$@"
}

# show { CHAR | [ parties | storage | vars | ids | chars | accs | db | FIELD+ ]
#   by { char CHAR | id ID | pcid PCID } }
_tmww_plugin_server_char_show() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            \( \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \| \
                /$'(parties|storage|vars|id|char|accs|db)\0'/ ":char:$_desc_char:(parties storage vars id char accs db)" \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \| \
                \( \
                    /$'([^\0]##\0~by\0)'/ ":fieldsdb:db fields:(${_tmww_server_fieldsdb})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsaccs:accs fields:(${_tmww_server_fieldsaccs})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsreg:reg fields:(${_tmww_server_fieldsreg})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsalias:fields aliases:(${_tmww_server_serverfieldsalias})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsdb:db fields from default config:(${_tmww_server_config_fieldsdb})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsaccs:accs fields from default config:(${_tmww_server_config_fieldsaccs})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsreg:reg fields from default config:(${_tmww_server_config_fieldsreg})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":fieldsalias:fields aliases from default config:(${_tmww_server_config_serverfieldsalias})" \
                \) \
                \# \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \) \
            \( \
                /$'pcid\0'/ ":char:$_desc_char:(pcid)" \
                /$'[^\0]##\0'/ ":char:$_desc_arg_pcid:" \
            \| \
                /$'id\0'/ ":char:$_desc_char:(id)" \
                /$'[^\0]##\0'/ ":char:$_desc_arg_id:" \
            \| \
                /$'char\0'/ ":char:$_desc_char:(char)" \
                /$'[^\0]##\0'/ ':char: :_tmww_arg_chars' \
            \) \
        \| \
            /$'[^\0]##\0'/ ':char: :_tmww_arg_chars' \
        \)
    _cmd "$@"
}

# summary { gp | bp | exp | items } by { char CHAR | id ID | pcid PCID }
_tmww_plugin_server_char_summary() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        /$'(gp|bp|exp|items)\0'/ ":char:$_desc_char:(gp bp exp items)" \
        /$'by\0'/ ":char:$_desc_char:(by)" \
        \( \
            /$'pcid\0'/ ":char:$_desc_char:(pcid)" \
            /$'[^\0]##\0'/ ":char:$_desc_arg_pcid:" \
        \| \
            /$'id\0'/ ":char:$_desc_char:(id)" \
            /$'[^\0]##\0'/ ":char:$_desc_arg_id:" \
        \| \
            /$'char\0'/ ":char:$_desc_char:(char)" \
            /$'[^\0]##\0'/ ':char: :_tmww_arg_chars' \
        \)
    _cmd "$@"
}

#
# party ops
#
#

_tmww_plugin_server_party() {
    if (( CURRENT == 2 )); then
        local ops; ops=(
            'grep:"REGEXP -- grep party name"'
            'fuzzy:"PATTERN -- approximated search of party name"'
            'agrep:"[ -e ERRORS ] REGEXP -- approximate search"'
            'get:"{ CHAR | by char CHAR } -- get party name of CHAR"'
            'show:"{ CHAR | [ chars | ids ] by { party PARTY | char CHAR } } -- party members lookup"'
        )
        _alternative "subop:subcommand operation:((${ops}))"
    else
        local cmd; cmd="server_party_${words[2]}"
        if (( $+functions[_tmww_plugin_${cmd}] )); then
            _arguments "*:: :_tmww_plugin_${cmd}"
        else
            _message "no operation completion available"
        fi
    fi
}

# grep REGEXP
_tmww_plugin_server_party_grep() {
    _arguments \
        ":$_desc_arg_regexp:"
}

# agrep [ -e ERRORS ] REGEXP
_tmww_plugin_server_party_agrep() {
    _arguments \
        "-e[number of errors]:$_desc_arg_integer:" \
        ":$_desc_arg_regexp:"
}

# fuzzy PATTERN
_tmww_plugin_server_party_fuzzy() {
    _arguments \
        ":$_desc_arg_fuzzy:"
}

# get { CHAR | by { char CHAR | pcid PCID } }
_tmww_plugin_server_party_get() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            /$'by\0'/ ":party:$_desc_party:(by)" \
            \( \
                /$'char\0'/ ":party:$_desc_party:(char)" \
                /$'[^\0]##\0'/ ':chars: :_tmww_arg_chars' \
            \| \
                /$'pcid\0'/ ":party:$_desc_party:(pcid)" \
                /$'[^\0]##\0'/ ":party:$_desc_arg_pcid:" \
            \) \
        \| \
            /$'[^\0]##\0'/ ":chars: :_tmww_arg_chars" \
        \)
    _cmd "$@"
}

# show { CHAR | [ pcids | ids | chars | players ]
#   by { char CHAR | party PARTY | partyid PARTYID | pcid PCID } }
_tmww_plugin_server_party_show() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            \( \
                /$'(pcids|chars|ids|players)\0'/ ":party:$_desc_party:(pcids chars ids players)" \
                /$'by\0'/ ":party:$_desc_party:(by)" \
            \| \
                /$'by\0'/ ":party:$_desc_party:(by)" \
            \) \
            \( \
                /$'char\0'/ ":party:$_desc_party:(char)" \
                /$'[^\0]##\0'/ ':chars: :_tmww_arg_chars' \
            \| \
                /$'party\0'/ ":party:$_desc_party:(party)" \
                /$'[^\0]##\0'/ ":party:$_desc_arg_party:" \
            \| \
                /$'pcid\0'/ ":party:$_desc_party:(pcid)" \
                /$'[^\0]##\0'/ ":party:$_desc_arg_pcid:" \
            \| \
                /$'partyid\0'/ ":party:$_desc_party:(partyid)" \
                /$'[^\0]##\0'/ ":party:$_desc_arg_partyid:" \
            \) \
        \| \
            /$'[^\0]##\0'/ ":chars: :_tmww_arg_chars" \
        \)
    _cmd "$@"
}

#
# player ops
#
#

_tmww_plugin_server_player() {
    _arguments -s \
        "${_tmww_args_server[@]}" \
        "*:: :_tmww_plugin_server_player_args"
}

_tmww_plugin_server_player_args() {
    if (( CURRENT == 1 )); then
        local ops; ops=(
            'ref:"-- field types quick reference"'
            'create:"PLAYER -- create player record; duplicates reported"'
            'remove:"PLAYER -- remove player record"'
            'rename:"PLAYER to PLAYER -- rename player by changing <player> field value"'
            'add:"PLAYER FIELD { value | element } STRING -- adding alts will automatically resolve charname into account"'
            'resolve:"PLAYER -- resolve all player alts into accounts"'
            'del:"PLAYER FIELD [ element VALUE ]"'
            'get:"{ CHAR | by { char CHAR | id ACCID | pcid PCID } }"'
            'show:"{ PLAYER | [ ids | chars | parties | accs | db | FIELD+ ] by { char CHAR | id ID | pcid PCID } }"'
            'summary:"{ gp | bp | exp | items } by { char CHAR | id ID | player PLAYER | pcid PCID }"'
            'list:"list with { FIELD | { { FIELD [ not ] as VALUE | VALUE [ not ] in FIELD } { and | or } }+ }"'
            'dump:"PLAYER -- dump JSONline record of PLAYER"'
            'record:"NUMBER -- access players db record by ordinal number"'
            'append:"STRING -- append JSON player record of same format as with dump operation to end of dbplayers"'
            'keys:"PLAYER -- list of fields in player record"'
            'field:"PLAYER FIELD+ -- tmww player field veryape name aka mail"'
            'search:"STRING -- simply case insensitive search in all fields, elements and values"'
            'sanitize:"-- remove keys with 0 length - empty arrays and hashes with null value, resolve alts into accounts, report duplicate accounts and alts"'
            'lregen:"-- regenerate shortened playerdb version if limiteddb is in use"'
        )
        _alternative "subop:subcommand operation:((${ops}))"
    else
        local cmd; cmd="server_player_${words[1]}"
        if (( $+functions[_tmww_plugin_${cmd}] )); then
            words=("dummy" "${words[@]}")
            CURRENT=$(expr $CURRENT + 1)
            _arguments "*:: :_tmww_plugin_${cmd}"
        else
            _message "no operation completion available"
        fi
    fi
}

# search STRING
_tmww_plugin_server_player_search() {
    _arguments \
        ":$_desc_arg_search:"
}

# append STRING
_tmww_plugin_server_player_append() {
    _arguments \
        ":$_desc_arg_dumpjson:"
}

# create PLAYER
_tmww_plugin_server_player_create() {
    # suggest already known players
    _arguments \
        ":$_desc_arg_rules_player:_tmww_arg_players"
}

# dump PLAYER
_tmww_plugin_server_player_dump() {
    _arguments \
        ": :_tmww_arg_players"
}

# keys PLAYER
_tmww_plugin_server_player_keys() {
    _arguments \
        ": :_tmww_arg_players"
}

# record NUMBER
_tmww_plugin_server_player_record() {
    _arguments \
        ":$_desc_arg_record:"
}

# remove PLAYER
_tmww_plugin_server_player_remove() {
    _arguments \
        ": :_tmww_arg_players"
}

# rename PLAYER to PLAYER
_tmww_plugin_server_player_rename() {
    _arguments \
        ": :_tmww_arg_players" \
        ":$_desc_arg_rules_player:(to)" \
        ": :_tmww_arg_players"
}

# field PLAYER FIELD+
_tmww_plugin_server_player_field() {
    # _value function cannot provide logically separated groups of values
    # so completing either this way (without removing used array element)
    # or with combined array using _value

    #_regex_arguments _cmd /$'[^\0]#\0'/ \
    #    /$'[^\0]##\0'/ ":player: :_tmww_arg_players" \
    #    \( /$'[^\0]##\0'/ ":ref_str:standart string fields:(${ref_str})" \| \
    #        /$'[^\0]##\0'/ ":ref_arr:standart array fields:(${ref_arr})" \) \#
    #_cmd "$@"
    
    _arguments \
        ": :_tmww_arg_players" \
        "*:: :{_values -w -s ' ' 'standart fields' ${ref_str} ${ref_arr}}"
}

# del PLAYER FIELD [ element VALUE ]
_tmww_plugin_server_player_del() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        /$'[^\0]##\0'/ ":player: :_tmww_arg_players" \
        \( \
            /${${(j:|:)$(echo ${^ref_str}-)}//-/$'\0'}/ ":ref_str:standart string fields:(${ref_str})" \
        \| \
            /$'[^\0]##\0'/ ":ref_arr:standart array fields:(${ref_arr})" \
            /$'element\0'/ ":ref_arr:$_desc_player:(element)" \
            /$'[^\0]##\0'/ ":player:$_desc_arg_string:" \
        \)
    _cmd "$@"
}

# get { CHAR | by { char CHAR | id ACCID } }
_tmww_plugin_server_player_get() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            /$'by\0'/ ":player:$_desc_player:(by)" \
            \( \
                /$'char\0'/ ":player:$_desc_player:(char)" \
                /$'[^\0]##\0'/ ':chars: :_tmww_arg_chars' \
            \| \
                /$'id\0'/ ":player:$_desc_player:(id)" \
                /$'[^\0]##\0'/ ":player:$_desc_arg_id:" \
            \) \
        \| \
            /$'[^\0]##\0'/ ":chars: :_tmww_arg_chars" \
        \)
    _cmd "$@"
}

# show { PLAYER | [ ids | chars | parties ] by { char CHAR | id CHAR | player PLAYER } }
_tmww_plugin_server_player_show() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            \( \
                /$'(chars|ids|parties)\0'/ ":player:$_desc_player:(chars ids parties)" \
                /$'by\0'/ ":player:$_desc_player:(by)" \
            \| \
                /$'by\0'/ ":player:$_desc_player:(by)" \
            \) \
            \( \
                /$'char\0'/ ":player:$_desc_player:(char)" \
                /$'[^\0]##\0'/ ':chars: :_tmww_arg_chars' \
            \| \
                /$'id\0'/ ":player:$_desc_player:(id)" \
                /$'[^\0]##\0'/ ":ids:$_desc_arg_id:" \
            \| \
                /$'player\0'/ ":player:$_desc_player:(player)" \
                /$'[^\0]##\0'/ ":players: :_tmww_arg_players" \
            \) \
        \| \
            /$'[^\0]##\0'/ ":players: :_tmww_arg_players" \
        \)
    _cmd "$@"
}

# add PLAYER FIELD { value | element } STRING
_tmww_plugin_server_player_add() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        /$'[^\0]##\0'/ ":player: :_tmww_arg_players" \
        \( \
            /${${(j:|:)$(echo ${^ref_str}-)}//-/$'\0'}/ ":ref_str:standart string fields:(${ref_str})" \
            /$'value\0'/ ":ref_str:$_desc_player:(value)" \
            /$'[^\0]##\0'/ ":player:$_desc_arg_string:" \
        \| \
            \( \
                /$'roles\0'/ ":ref_arr:standart array fields:(roles)" \
                /$'element\0'/ ":ref_arr:$_desc_player:(element)" \
                /$'[^\0]##\0'/ ":player:standart roles:($ref_roles)" \
            \| \
                /$'alts\0'/ ":ref_arr:standart array fields:(alts)" \
                /$'element\0'/ ":ref_arr:$_desc_player:(element)" \
                /$'[^\0]##\0'/ ":chars: :_tmww_arg_chars" \
            \| \
                /$'[^\0]##\0'/ ":ref_arr:standart array fields:(${ref_arr})" \
                /$'element\0'/ ":ref_arr:$_desc_player:(element)" \
                /$'[^\0]##\0'/ ":player:$_desc_arg_string:" \
            \) \
        \)
    _cmd "$@"
}

# list with { FIELD | { { FIELD [ not ] as VALUE | VALUE [ not ] in FIELD } { and | or } }+ }
_tmww_plugin_server_player_list() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        /$'with\0'/ ":player:$_desc_player:(with)" \
        \( \
        \( \
            /${${(j:|:)$(echo ${^ref_str}-)}//-/$'\0'}/ ":ref_str:standart string fields:(${ref_str})" \
            \( \
                /$'not\0'/ ":player:$_desc_player:(not)" \
                /$'as\0'/ ":player:$_desc_player:(as)" \
            \| \
                /$'as\0'/ ":player:$_desc_player:(as)" \
            \) \
            /$'[^\0]##\0'/ ":player:$_desc_arg_string:" \
        \| \
            /$'[^\0]##\0'/ ":player:string or standart roles:($ref_roles)" \
            \( \
                /$'not\0'/ ":player:$_desc_player:(not)" \
                /$'in\0'/ ":player:$_desc_player:(in)" \
            \| \
                /$'in\0'/ ":player:$_desc_player:(in)" \
            \) \
            /$'[^\0]##\0'/ ":ref_arr:standart array fields:(${ref_arr})" \
        \) \
        \( \
            /$'and\0'/ ":player:$_desc_player:(and)" \
        \| \
            /$'or\0'/ ":player:$_desc_player:(or)" \
        \) \
        \) \#
    _cmd "$@"
}

#
# arseoscope op
#
#

_tmww_plugin_server_arseoscope() {
    _arguments \
        ': :_tmww_arg_chars'
}

#
# select op
#
#

_tmww_plugin_server_select() {
    local state
    _arguments -s "${_tmww_args_select[@]}" "*:: :->select"

    case $state in
        select)
            # feel free to fix whenever you find right synthax
            # not breaking internals for _regex_arguments after _arguments
            words=("dummy" "${words[@]}")
            CURRENT=$(expr $CURRENT + 1)
            _regex_arguments _cmd /$'[^\0]##\0'/ \
                /$'by\0'/ ":select:$_desc_select:(by)" \
                \( \
                    /$'names\0'/ ":select:$_desc_select:(names)" \
                    /$'[^\0]##\0'/ ':items: :_tmww_arg_items' \
                    \# \
                \| \
                    /$'ids\0'/ ":select:$_desc_select:(ids)" \
                    /$'[^\0]##\0'/ ":select:$_desc_arg_itemid:" \
                    \# \
                \| \
                    /$'re\0'/ ":select:$_desc_select:(re)" \
                    /$'[^\0]##\0'/ ":select:$_desc_arg_regexp:" \
                \| \
                    /$'itemsets\0'/ ":select:$_desc_select:(itemsets)" \
                    /$'[^\0]##\0'/ ":items:$_desc_arg_itemset:(${_tmww_db_itemsets})" \
                    \# \
                \)
            _cmd "$@"
            ;;
    esac
}


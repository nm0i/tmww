# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3
#
# don't forget to not overlap tcc and tpp with those aliases
alias tp="tmww player"
alias tps="tmww player show"
# alias tpsi="tmww player show ids by id"
# alias tpsc="tmww player show ids by char"
alias tpsi="tmww player show parties by id"
alias tpsc="tmww player show parties by char"
alias tpsp="tmww player show parties by player"
alias tpd="tmww player dump"
alias tpg="tmww player get"
alias tpgi="tmww player get by id"

alias tg="tmww party"
alias tgg="tmww party get"
alias tgs="tmww party show ids by char"
alias tgsp="tmww party show players by char"

alias tc="tmww char"
alias tcd="tmww char dig"
alias tcs="tmww char show"
alias tcsi="tmww char show by id"
alias tcg="tmww char get"

alias ta="tmww arseoscope"

#
# config
#
#

zmodload zsh/mapfile

# required to regenerate list of player aliases from db
_opt_tmww_jq=$( command -v jq 2>&- )

# comment next line if you don't want to generate altsdb players completion
_opt_tmww_use_altdb=1

# IMPORTANT: using default.conf without parsing INCLUDE configs
#            change this variable if you have custom setup
_opt_tmww_altspath=$( tmww -ug ALTSPATH )
eval _opt_tmww_altspath="${_opt_tmww_altspath:-${_opt_tmww_DIRCONFIG}/alts}"

_desc_arg_player="player alias"
_desc_arg_char="character name"
_desc_arg_id="account ID"

_desc_char="char subcommand completion"
_desc_party="party subcommand completion"
_desc_player="player subcommand completion"

_desc_arg_party="enquoted party name; single quotes recommended"
_desc_arg_fuzzy="fuzzy search - case insensitive, l33t chars, one missing and one incorrect character; no spaces; default characters allowed [-/\\.,_a-zA-Z0-9]"
_desc_arg_search="case insensitive string"
_desc_arg_dumpjson="JSON string, e.g. from player dump operation"
_desc_arg_record="record number starting from 1"
_desc_arg_rules_player="player name; recommended character set [-_a-z0-9]"

#
# code
#
#

# cache invalidation criterias
_cache_policy_tmww_players() {
    # rebuild every week
    local -a oldp
    oldp=( "$1"(Nm+7) )
    (( $#oldp ))
}

# complete players
_tmww_arg_players() {
    local curcontext="${curcontext}:alts" altpath
    if [ -n "${_opt_tmww_use_altdb}" ]; then
        if _cache_invalid TMWW_ALTS_"${_opt_tmww_servername}" || \
            ! _retrieve_cache TMWW_ALTS_"${_opt_tmww_servername}"; then

            altpath="${_opt_tmww_altspath}/${_opt_tmww_servername}"

            
            if [ -n "${_opt_tmww_jq}" ]; then
                _opt_tmww_players=("${(@f)$(cd ${altpath} && jq -r '.player' dbplayers.jsonl )}")
                _store_cache TMWW_ALTS_"${_opt_tmww_servername}" _opt_tmww_players
                _tmww_debug players regenerated for ${_opt_tmww_servername}
            fi
        fi
    fi
    if [ -n "${_opt_tmww_players}" -a -n "${_opt_tmww_use_altdb}" ]; then
        _describe "$_desc_arg_player" _opt_tmww_players
    else
        _message "no player aliases available"
    fi
}

# complete characters
_tmww_arg_chars() {
    local -a _opt_tmww_chars
    local fname="${_opt_tmww_sharedtmp}/tmww/tmww-${_opt_tmww_servername}-online"
    #_tmww_debug ${fname}
    if [ -f "${fname}" ]; then
        # protecting ":" for _describe
        _opt_tmww_chars=( ${(f)mapfile[${fname}]//:/\\:} )
        _describe "$_desc_arg_char" _opt_tmww_chars
    else
        _message "no online list found to complete chars"
    fi
}

_tmww_plugin_alts() {
    local -a ref_str ref_arr ref_role
    ref_str=( name wiki trello server port tmwc active cc )
    ref_arr=( aka roles alts accounts links xmpp mail skype repo forum tags comments )
    ref_roles=( content sound music gm code map pixel admin host wiki advisor translator packager web concept dude )

    # extract servername from config
    _tmww_servername

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
                'char:"operations on accid:charname database"'
                'party:"operations on party:charname database"'
                'player:"operations on JSONlines players database"'
                'arseoscope:"compact CHARNAME description - accounts known, chars on same account"'
            )
            _alternative "subcommand:subcommand:((${ops}))"
        else
            local cmd; cmd="alts_${words[2]}"
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

_tmww_plugin_alts_char() {
    if (( CURRENT == 2 )); then
        local ops; ops=(
            'add:"id ID char CHAR -- add id/char pair to db; write conflicts to log"'
            'resolve:"id ID char CHAR -- same as add + resolve all matched alts in playerdb into accounts"'
            'grep:"[ chars | ids ] REGEXP -- search known chars, output chars/chars with ids"'
            'fuzzy:"[ chars | ids ] PATTERN -- case-insensitive levenshtein distance 1 search"'
            'agrep:"[ -e ERRORS ] [ chars | ids ] REGEXP -- approximate search"'
            'get:"{ CHAR | [ id ] by char CHAR } -- get account id of CHAR"'
            'show:"{ CHAR | [ chars | ids ] by { id ID | char CHAR } } -- get all known chars on acc_id"'
            'dig:"REGEXP -- grep + show ids by ids from grep matches"'
            'sanitize:"-- remove older duplicate entries; write conflicts to log"'
            'merge:"FILENAME -- put FILENAME into db; write conflicts to log"'
        )
        _alternative "subop:subcommand operation:((${ops}))"
    else
        local cmd; cmd="alts_char_${words[2]}"
        if (( $+functions[_tmww_plugin_${cmd}] )); then
            _arguments "*:: :_tmww_plugin_${cmd}"
        else
            _message "no operation completion available"
        fi
    fi
}

# dig REGEXP
_tmww_plugin_alts_char_dig() {
    _arguments \
        ":$_desc_arg_regexp:"
}

# merge FILENAME
_tmww_plugin_alts_char_merge() {
    _arguments \
        ":$_desc_arg_file:_files"
}

# add id ID char CHAR
_tmww_plugin_alts_char_add() {
    _arguments \
        ":$_desc_char:(id)" \
        ":$_desc_arg_id:" \
        ":$_desc_char:(char)" \
        ": :_tmww_arg_chars"
}

# resolve id ID char CHAR
_tmww_plugin_alts_char_resolve() {
    _arguments \
        ":$_desc_char:(id)" \
        ":$_desc_arg_id:" \
        ":$_desc_char:(char)" \
        ": :_tmww_arg_chars"
}

# grep [ chars | ids ] REGEXP
_tmww_plugin_alts_char_grep() {
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
_tmww_plugin_alts_char_agrep() {
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
_tmww_plugin_alts_char_fuzzy() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            /$'(chars|ids)\0'/ ":char:$_desc_char:(chars ids)" \
            /$'[^\0]##\0'/ ":chars:$_desc_arg_fuzzy:" \
        \| \
            /$'[^\0]##\0'/ ":chars:$_desc_arg_fuzzy:" \
        \)
    _cmd "$@"
}

# get { CHAR | [ id ] by char CHAR }
_tmww_plugin_alts_char_get() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            \( \
                /$'id\0'/ ":char:$_desc_char:(id)" \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \| \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \) \
            /$'char\0'/ ":char:$_desc_char:(char)" \
            /$'[^\0]##\0'/ ':chars: :_tmww_arg_chars' \
        \| \
            /$'[^\0]##\0'/ ":chars: :_tmww_arg_chars" \
        \)
    _cmd "$@"
}

# show { CHAR | [ chars | ids | parties ] by { id ID | char CHAR } }
_tmww_plugin_alts_char_show() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            \( \
                /$'(chars|ids|parties)\0'/ ":char:$_desc_char:(chars ids parties)" \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \| \
                /$'by\0'/ ":char:$_desc_char:(by)" \
            \) \
            \( \
                /$'char\0'/ ":char:$_desc_char:(char)" \
                /$'[^\0]##\0'/ ':chars: :_tmww_arg_chars' \
            \| \
                /$'id\0'/ ":char:$_desc_char:(id)" \
                /$'[^\0]##\0'/ ":char:$_desc_arg_id:" \
            \) \
        \| \
            /$'[^\0]##\0'/ ":chars: :_tmww_arg_chars" \
        \)
    _cmd "$@"
}

#
# party ops
#
#

_tmww_plugin_alts_party() {
    if (( CURRENT == 2 )); then
        local ops; ops=(
            'add:"party PARTY char CHAR"'
            'grep:"REGEXP -- grep party name"'
            'fuzzy:"PATTERN -- approximated search of party name"'
            'agrep:"[ -e ERRORS ] REGEXP -- approximate search"'
            'get:"{ CHAR | by char CHAR } -- get party name of CHAR"'
            'show:"{ CHAR | [ chars | ids ] by { party PARTY | char CHAR } } -- party members lookup"'
            'sanitize:"-- show duplicates in partydb"'
            'merge:"FILENAME -- put FILENAME into db; conflicts pushed to db and listed in merge log"'
        )
        _alternative "subop:subcommand operation:((${ops}))"
    else
        local cmd; cmd="alts_party_${words[2]}"
        if (( $+functions[_tmww_plugin_${cmd}] )); then
            _arguments "*:: :_tmww_plugin_${cmd}"
        else
            _message "no operation completion available"
        fi
    fi
}

# grep REGEXP
_tmww_plugin_alts_party_grep() {
    _arguments \
        ":$_desc_arg_regexp:"
}

# agrep [ -e ERRORS ] REGEXP
_tmww_plugin_alts_party_agrep() {
    _arguments \
        "-e[number of errors]:$_desc_arg_integer:" \
        ":$_desc_arg_regexp:"
}

# fuzzy PATTERN
_tmww_plugin_alts_party_fuzzy() {
    _arguments \
        ":$_desc_arg_fuzzy:"
}

# merge FILENAME
_tmww_plugin_alts_party_merge() {
    _arguments \
        ":$_desc_arg_file:_files"
}

# add id ID char CHAR
_tmww_plugin_alts_party_add() {
    _arguments \
        ":$_desc_party:(party)" \
        ":$_desc_arg_party:" \
        ":$_desc_party:(char)" \
        ": :_tmww_arg_chars"
}

# get { CHAR | by char CHAR }
_tmww_plugin_alts_party_get() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            /$'by\0'/ ":party:$_desc_party:(by)" \
            /$'char\0'/ ":party:$_desc_party:(char)" \
            /$'[^\0]##\0'/ ':chars: :_tmww_arg_chars' \
        \| \
            /$'[^\0]##\0'/ ":chars: :_tmww_arg_chars" \
        \)
    _cmd "$@"
}

# show { CHAR | [ chars | ids | players ] by { party ID | char CHAR } }
_tmww_plugin_alts_party_show() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            \( \
                /$'(chars|ids|players)\0'/ ":party:$_desc_party:(chars ids players)" \
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

_tmww_plugin_alts_player() {
    if (( CURRENT == 2 )); then
        local ops; ops=(
            'ref:"-- field types quick reference"'
            'create:"PLAYER -- create player record; duplicates reported"'
            'remove:"PLAYER -- remove player record"'
            'rename:"PLAYER to PLAYER -- rename player by changing <player> field value"'
            'add:"PLAYER FIELD { value | element } STRING -- adding alts will automatically resolve charname into account"'
            'resolve:"PLAYER -- resolve all player alts into accounts"'
            'del:"PLAYER FIELD [ element VALUE ]"'
            'get:"{ CHAR | by { char CHAR | id ACCID } } -- dereference player entry"'
            'show:"{ PLAYER | [ ids | chars ] by { char CHAR | id CHAR | player PLAYER } } -- lookup"'
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
        local cmd; cmd="alts_player_${words[2]}"
        if (( $+functions[_tmww_plugin_${cmd}] )); then
            _arguments "*:: :_tmww_plugin_${cmd}"
        else
            _message "no operation completion available"
        fi
    fi
}

# search STRING
_tmww_plugin_alts_player_search() {
    _arguments \
        ":$_desc_arg_search:"
}

# append STRING
_tmww_plugin_alts_player_append() {
    _arguments \
        ":$_desc_arg_dumpjson:"
}

# create PLAYER
_tmww_plugin_alts_player_create() {
    # suggest already known players
    _arguments \
        ":$_desc_arg_rules_player:_tmww_arg_players"
}

# dump PLAYER
_tmww_plugin_alts_player_dump() {
    _arguments \
        ": :_tmww_arg_players"
}

# keys PLAYER
_tmww_plugin_alts_player_keys() {
    _arguments \
        ": :_tmww_arg_players"
}

# record NUMBER
_tmww_plugin_alts_player_record() {
    _arguments \
        ":$_desc_arg_record:"
}

# remove PLAYER
_tmww_plugin_alts_player_remove() {
    _arguments \
        ": :_tmww_arg_players"
}

# rename PLAYER to PLAYER
_tmww_plugin_alts_player_rename() {
    _arguments \
        ": :_tmww_arg_players" \
        ":$_desc_arg_rules_player:(to)" \
        ": :_tmww_arg_players"
}

# field PLAYER FIELD+
_tmww_plugin_alts_player_field() {
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
_tmww_plugin_alts_player_del() {
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
_tmww_plugin_alts_player_get() {
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
_tmww_plugin_alts_player_show() {
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
_tmww_plugin_alts_player_add() {
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
_tmww_plugin_alts_player_list() {
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

_tmww_plugin_alts_arseoscope() {
    _arguments \
        ': :_tmww_arg_chars'
}


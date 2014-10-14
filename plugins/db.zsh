# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3
#
alias ti="tmww item"
alias tig="tmww item get"
alias tii="tmww item get by id"
alias tis="tmww item show i1 by names"
alias tir="tmww item show i1 by re"
alias tiss="tmww item show i1 by itemset"
alias tim="tmww item mobs by names"

alias tm="tmww mob"
alias tmg="tmww mob get"
alias tmi="tmww mob get by id"
alias tms="tmww mob show m1 by names"
alias tmr="tmww mob show m1 by re"
alias tmss="tmww mob show m1 by itemset"
alias tmd="tmww mob drops by name"
alias tmdi="tmww mob drops by id"

#
# config
#
#

zmodload zsh/mapfile

# comment next line if you don't want to generate item/mob names completion
_opt_tmww_use_db=1

# IMPORTANT: using default.conf
#            change this variable if you have custom setup
if (( ! $+_opt_tmww_serverdbpath )); then
    _opt_tmww_serverdbpath=$( tmww -ug SERVERDBPATH )
    eval _opt_tmww_serverdbpath="${_opt_tmww_serverdbpath:-${HOME}/tmwAthena/tmwa-server-data/world/map/db}"
fi

# IMPORTANT: using default.conf
#            change this variable if you have custom setup
if (( ! $+_opt_tmww_utilpath )); then
    _opt_tmww_utilpath=$( tmww -ug UTILPATH )
    eval _opt_tmww_utilpath="${_opt_tmww_utilpath:-${DIRCONFIG}/utils}"
fi

_desc_arg_item="item name without spaces and special characters (like GreenApple)"
_desc_arg_itemid="item ID"
_desc_arg_mob="mob name without spaces and special characters (like JackO)"
_desc_arg_mobid="mob ID"
_desc_arg_itemset="filename.{id|name}.itemset from UTILPATH"

#
# code
#
#

# grab aliases from default config and itemsets from UTILPATH
typeset -a _tmww_db_config_itemfieldsalias _tmww_db_config_mobfieldsalias

_tmww_db_config_mobfieldsalias=( "${(@f)$(awk -- '
    /^mobfieldsalias \{/{a=1}/^\}$/&&a{exit}(a+0)>1{print $1}a{a+=1}' \
    ${_opt_tmww_DIRCONFIG}/default.conf )}" )

_tmww_db_config_itemfieldsalias=( "${(@f)$(awk -- '
    /^itemfieldsalias \{/{a=1}/^\}$/&&a{exit}(a+0)>1{print $1}a{a+=1}' \
    ${_opt_tmww_DIRCONFIG}/default.conf )}" )

_tmww_db_itemsets=( ${(u)"${(@f)$(cd ${_opt_tmww_utilpath} && ls *.itemset )}"/.*/} ) 2>/dev/null

# db ops specific options
_tmww_args_db=(
    "-c[no fields captions]"
    "-n[suppress append id/name to fields query]"
    "-r[output raw tab-separated fields without pretty-printing]"
    "-f[custom cut -f expression for db filter]:cut -f expression:"
    )

# cache invalidation criterias
# conditions are common for items/mobs names using common cache file
# caches regenerated separately using individual files and policies
_cache_policy_tmww_db() {
    # rebuild every week
    local -a oldp
    oldp=( "$1"(Nm+7) )
    (( $#oldp ))
}

# complete item names
_tmww_arg_items() {
    local curcontext="${curcontext}:itemdb" dbfiles
    if [ -n "${_opt_tmww_use_db}" ]; then
        if _cache_invalid TMWW_ITEMDB_"${_opt_tmww_servername}" || \
            ! _retrieve_cache TMWW_ITEMDB_"${_opt_tmww_servername}"; then

            dbfiles=($(awk -- '/^itemfiles \{/{a=1}/^\}$/&&a{exit}(a+0)>1{print}a{a+=1}' \
                "${_opt_tmww_DIRCONFIG}/default.conf" ))
            [ -z "${dbfiles}" ] && dbfiles="*_item_db.txt"
            dbfiles=( ${(u)$(echo ${_opt_tmww_serverdbpath}/${^~dbfiles})} )
            
            _opt_tmww_items=("${(@f)$(sed '\|^//|d;s/^[^,]*, *\([^, ]*\),.*/\1/' ${dbfiles})}")
            _store_cache TMWW_ITEMDB_"${_opt_tmww_servername}" _opt_tmww_items
            _tmww_debug items regenerated for ${_opt_tmww_servername}
        fi
    fi
    if [ -n "${_opt_tmww_items}" -a -n "${_opt_tmww_use_db}" ]; then
        _describe "$_desc_arg_item" _opt_tmww_items
    else
        _message "no item names available"
    fi
}

# complete mob names
_tmww_arg_mobs() {
    local curcontext="${curcontext}:mobdb" dbfiles
    if [ -n "${_opt_tmww_use_db}" ]; then
        if _cache_invalid TMWW_MOBDB_"${_opt_tmww_servername}" || \
            ! _retrieve_cache TMWW_MOBDB_"${_opt_tmww_servername}"; then

            dbfiles=($(awk -- '/^mobfiles \{/{a=1}/^\}$/&&a{exit}(a+0)>1{print}a{a+=1}' \
                "${_opt_tmww_DIRCONFIG}/default.conf" ))
            [ -z "${dbfiles}" ] && dbfiles="*_mob_db.txt"
            dbfiles=( ${(u)$(echo ${_opt_tmww_serverdbpath}/${^~dbfiles})} )
            _tmww_debug "${dbfiles}"
            
            _opt_tmww_mobs=("${(@f)$(sed '\|^//|d;s/^[^,]*, *\([^, ]*\),.*/\1/' ${dbfiles})}")
            _store_cache TMWW_MOBDB_"${_opt_tmww_servername}" _opt_tmww_mobs
            _tmww_debug mobs regenerated for ${_opt_tmww_servername}
        fi
    fi
    if [ -n "${_opt_tmww_mobs}" -a -n "${_opt_tmww_use_db}" ]; then
        _describe "$_desc_arg_mob" _opt_tmww_mobs
    else
        _message "no mob names available"
    fi
}

_tmww_plugin_db() {
    local _desc_item="item subcommand completion"
    local _desc_mob="mob subcommand completion"

    local -a _tmww_db_mobfieldsalias _tmww_db_itemfieldsalias _tmww_db_fieldsmob _tmww_db_fieldsitem

    _tmww_db_fieldsmob=( ID Name Jname LV HP SP EXP JEXP Range1 ATK1 ATK2 DEF MDEF
    STR AGI VIT INT DEX LUK Range2 Range3 Scale Race Element Mode Speed
    Adelay Amotion Dmotion
    D1id D1% D2id D2% D3id D3% D4id D4%
    D5id D5% D6id D6% D7id D7% D8id D8%
    Item1 Item2 MEXP ExpPer MVP1id MVP1per MVP2id MVP2per MVP3id MVP3per
    mutationcount mutationstrength
    fname )

    _tmww_db_fieldsitem=(ID Name Label Type Price Sell Weight ATK DEF Range Mbonus
    Slot Gender Loc wLV eLV View UseScript
    fname typename )

    _tmww_db_mobfieldsalias=( drops fulldrops stats lvl m1 )
    _tmww_db_itemfieldsalias=( i1 )

    # extract servername from config
    _tmww_servername

    local update_policy
    zstyle -s ":completion:*:complete:tmww:*:itemdb:" cache-policy update_policy
    if [[ -z "$update_policy" ]]; then
        zstyle ":completion:*:complete:tmww:*:itemdb:" cache-policy _cache_policy_tmww_db
    fi
    zstyle -s ":completion:*:complete:tmww:*:mobdb:" cache-policy update_policy
    if [[ -z "$update_policy" ]]; then
        zstyle ":completion:*:complete:tmww:*:mobdb:" cache-policy _cache_policy_tmww_db
    fi

    if [ -n "$_opt_tmww_prefix" ]; then
        _call_function ret _tmww_apply_prefix
    else
        if (( CURRENT == 2 )); then
            local ops; ops=(
                'item:"item operations"'
                'mob:"mob operations"'
            )
            _alternative "subcommand:subcommand:((${ops}))"
        else
            local cmd; cmd="db_${words[2]}"
            # _tmww_debug cmd $cmd words $words current $CURRENT
            if (( $+functions[_tmww_plugin_${cmd}] )); then
                _arguments "*:: :_tmww_plugin_${cmd}"
            else
                _message "no operation completion available"
            fi
        fi
    fi
}

#
# item ops
#
#

_tmww_plugin_db_item() {
    _arguments \
        "${_tmww_args_db[@]}" \
        "*:: :_tmww_plugin_db_item_args"
}

_tmww_plugin_db_item_args() {
    if (( CURRENT == 1 )); then
        local ops; ops=(
            'get:"{ NAME | [ id | name | db | FIELD+ ] by { id ID | name NAME } }"'
            'show:"[ names | ids | db | FIELD+ ] by { ids ID+ | names NAME+ | re REGEXP | itemset ITEMSET }"'
            'mobs:"by { ids ID+ | names NAME+ | re REGEXP } -- show mobs dropping item/items"'
        )
        _alternative "subop:subcommand operation:((${ops}))"
    else
        local cmd; cmd="db_item_${words[1]}"
        #_tmww_debug argscmd $cmd words $words current $CURRENT
        if (( $+functions[_tmww_plugin_${cmd}] )); then
            _arguments "*:: :_tmww_plugin_${cmd}"
        else
            _message "no operation asd completion available"
        fi
    fi
}

# get { NAME | [ id | name | db | FIELD+ ] by { id ID | name NAME } }
_tmww_plugin_db_item_get() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            \( \
                /$'by\0'/ ":item:$_desc_item:(by)" \
            \| \
                /$'(id|name|db)\0'/ ":item:$_desc_item:(id name db)" \
                /$'by\0'/ ":item:$_desc_item:(by)" \
            \| \
                \( \
                    /$'([^\0]##\0~by\0)'/ ":itemfield:item fields:(${(L)_tmww_db_fieldsitem})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":itemalias:item fields aliases:(${_tmww_db_itemfieldsalias})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":itemaliasconf:item fields aliases from default config:(${_tmww_db_config_itemfieldsalias})" \
                \) \
                \# \
                /$'by\0'/ ":item:$_desc_item:(by)" \
            \) \
            \( \
                /$'id\0'/ ":item:$_desc_item:(id)" \
                /$'[^\0]##\0'/ ":item:$_desc_arg_itemid:" \
            \| \
                /$'name\0'/ ":item:$_desc_item:(name)" \
                /$'[^\0]##\0'/ ':item: :_tmww_arg_items' \
            \) \
        \| \
            /$'[^\0]##\0'/ ':item: :_tmww_arg_items' \
        \)
    _cmd "$@"
}

# show { names | ids | db | FIELD+ } by { ids ID+ | names NAME+ | re REGEXP | itemset ITEMSET }
_tmww_plugin_db_item_show() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            /$'(names|ids|db)\0'/ ":item:$_desc_item:(names ids db)" \
        \| \
            \( \
                /$'([^\0]##\0~by\0)'/ ":itemfield:item fields:(${(L)_tmww_db_fieldsitem})" \
            \| \
                /$'([^\0]##\0~by\0)'/ ":itemalias:item fields aliases:(${_tmww_db_itemfieldsalias})" \
            \| \
                /$'([^\0]##\0~by\0)'/ ":itemaliasconf:item fields aliases from default config:(${_tmww_db_config_itemfieldsalias})" \
            \) \
            \# \
        \) \
        /$'by\0'/ ":item:$_desc_item:(by)" \
        \( \
            /$'names\0'/ ":item:$_desc_item:(names)" \
            /$'[^\0]##\0'/ ':items: :_tmww_arg_items' \
            \# \
        \| \
            /$'ids\0'/ ":item:$_desc_item:(ids)" \
            /$'[^\0]##\0'/ ":item:$_desc_arg_itemid:" \
            \# \
        \| \
            /$'re\0'/ ":item:$_desc_item:(re)" \
            /$'[^\0]##\0'/ ":item:$_desc_arg_regexp:" \
        \| \
            /$'itemset\0'/ ":item:$_desc_item:(itemset)" \
            /$'[^\0]##\0'/ ":item:$_desc_arg_itemset:(${_tmww_db_itemsets})" \
        \)
    _cmd "$@"
}


# mobs by { ids ID+ | names NAME+ | re REGEXP }
_tmww_plugin_db_item_mobs() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        /$'by\0'/ ":item:$_desc_item:(by)" \
        \( \
            /$'names\0'/ ":item:$_desc_item:(names)" \
            /$'[^\0]##\0'/ ':items: :_tmww_arg_items' \
            \# \
        \| \
            /$'ids\0'/ ":item:$_desc_item:(ids)" \
            /$'[^\0]##\0'/ ":item:$_desc_arg_itemid:" \
            \# \
        \| \
            /$'re\0'/ ":item:$_desc_item:(re)" \
            /$'[^\0]##\0'/ ":item:$_desc_arg_regexp:" \
        \)
    _cmd "$@"
}

#
# mob ops
#
#

_tmww_plugin_db_mob() {
    _arguments \
        "${_tmww_args_db[@]}" \
        "*:: :_tmww_plugin_db_mob_args"
}

_tmww_plugin_db_mob_args() {
    if (( CURRENT == 1 )); then
        local ops; ops=(
            'get:"{ NAME | [ id | name | db | FIELD+ ] by { id ID | name NAME } }"'
            'show:"[ names | ids | db | FIELD+ ] by { ids ID+ | names NAME+ | re REGEXP }"'
            'drops:"by { id ID | name NAME } -- show mob drops"'
        )
        _alternative "subop:subcommand operation:((${ops}))"
    else
        local cmd; cmd="db_mob_${words[1]}"
        #_tmww_debug cmd $cmd words $words current $CURRENT
        if (( $+functions[_tmww_plugin_${cmd}] )); then
            _arguments "*:: :_tmww_plugin_${cmd}"
        else
            _message "no operation completion available"
        fi
    fi
}

# get { NAME | [ id | name | db | FIELD+ ] by { id ID | name NAME } }
_tmww_plugin_db_mob_get() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            \( \
                /$'by\0'/ ":mob:$_desc_mob:(by)" \
            \| \
                /$'(id|name|db)\0'/ ":mob:$_desc_mob:(id name db)" \
                /$'by\0'/ ":mob:$_desc_mob:(by)" \
            \| \
                \( \
                    /$'([^\0]##\0~by\0)'/ ":mobfield:item fields:(${(L)_tmww_db_fieldsmob})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":mobalias:item fields aliases:(${_tmww_db_mobfieldsalias})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":mobaliasconf:item fields aliases from default config:(${_tmww_db_config_mobfieldsalias})" \
                \) \
                \# \
                /$'by\0'/ ":mob:$_desc_mob:(by)" \
            \) \
            \( \
                /$'id\0'/ ":mob:$_desc_mob:(id)" \
                /$'[^\0]##\0'/ ":mob:$_desc_arg_mobid:" \
            \| \
                /$'name\0'/ ":mob:$_desc_mob:(name)" \
                /$'[^\0]##\0'/ ':mob: :_tmww_arg_mobs' \
            \) \
        \| \
            /$'[^\0]##\0'/ ':mob: :_tmww_arg_mobs' \
        \)
    _cmd "$@"
}

# show [ names | ids | db | FIELD+ ] by { ids ID+ | names NAME+ | re REGEXP }"'
_tmww_plugin_db_mob_show() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        \( \
            /$'by\0'/ ":mob:$_desc_mob:(by)" \
        \| \
            \( \
                /$'(names|ids|db)\0'/ ":mob:$_desc_mob:(names ids db)" \
            \| \
                \( \
                    /$'([^\0]##\0~by\0)'/ ":mobfield:mob fields:(${(L)_tmww_db_fieldsmob})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":mobalias:mob fields aliases:(${_tmww_db_mobfieldsalias})" \
                \| \
                    /$'([^\0]##\0~by\0)'/ ":mobaliasconf:mob fields aliases from default config:(${_tmww_db_config_mobfieldsalias})" \
                \) \
                \# \
            \) \
            /$'by\0'/ ":mob:$_desc_mob:(by)" \
        \) \
        \( \
            /$'names\0'/ ":mob:$_desc_mob:(names)" \
            /$'[^\0]##\0'/ ':mobs: :_tmww_arg_mobs' \
            \# \
        \| \
            /$'ids\0'/ ":mob:$_desc_mob:(ids)" \
            /$'[^\0]##\0'/ ":mob:$_desc_arg_mobid:" \
            \# \
        \| \
            /$'re\0'/ ":mob:$_desc_mob:(re)" \
            /$'[^\0]##\0'/ ":mob:$_desc_arg_regexp:" \
        \)
    _cmd "$@"
}

# drops by { id ID | name NAME }
_tmww_plugin_db_item_mobs() {
    _regex_arguments _cmd /$'[^\0]#\0'/ \
        /$'by\0'/ ":mob:$_desc_mob:(by)" \
        \( \
            /$'name\0'/ ":mob:$_desc_mob:(name)" \
            /$'[^\0]##\0'/ ':mobs: :_tmww_arg_mobs' \
        \| \
            /$'id\0'/ ":mob:$_desc_mob:(id)" \
            /$'[^\0]##\0'/ ":mob:$_desc_arg_mobid:" \
        \)
    _cmd "$@"
}


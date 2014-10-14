#!/bin/sh
# tmww lib: player.lib.sh

# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

# check if not run from tmww
if [ "$TMWW_PLUGINS" != "yes" ] ; then
    echo >&2 "This script is tmww lib and not intended for manual run."
    exit 1
fi

#
# common
#
#

# chars allowed in player alias name (as shell pattern inside [])
playerchars="a-zA-Z0-9_\-"

[ "${TMWW_LIMITED}" = "yes" ] && playerdb="${limiteddb}"

JQ=$(command -v jq >/dev/null 2>&1)

# eval TMWW_ALTSPATH="${TMWW_ALTSPATH:-${DIRCONFIG}/alts}"
TMWW_ALTSPATH="${TMWW_ALTSPATH:-${DIRCONFIG}/alts}"
TMWW_ALTSPATH=${TMWW_ALTSPATH}/${servername}
TMWW_UPDATELIMITED="${TMWW_UPDATELIMITED:-no}"
TMWW_LIMITED="${TMWW_LIMITED:-no}"
playerdb="${TMWW_ALTSPATH}/dbplayers.jsonl"
limiteddb="${TMWW_ALTSPATH}/limited.jsonl"
# separate temp files in case of lockfile timeout
# using PRIVTMP here to avoid endless chmod to ensure multiuser support
playerdbtmp=${TMWW_PRIVTMP}/playerdb.temp
playerdbtmp2=${TMWW_PRIVTMP}/playerdb.temp2

check_jq() {
    if [ -z "${JQ}" ]; then
        error "jq not found. Aborting."
        return 1
    fi
}

check_player() {
    check_string_chars "$1" "*[!${playerchars}]*" "Disallowed characters at player name" || return 1
    if ! grep -m 1 "\"player\":\"$1\"" "${playerdb}" >/dev/null 2>&1 ; then
        error "No such player: $1"; return 1
    fi
}

check_id() {
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in ID" || return 1
}

TMWW_DBLOCK="${TMWW_LOCK}/tmww-db-${servername}"
set_db_lock() {
    check_lock "altdb" "${TMWW_DBLOCK}" 35
}

unset_db_lock() {
    rmdir ${TMWW_DBLOCK} 2>/dev/null
}

# format: single line, space separated
player_fields_string="name wiki trello server port tmwc active cc"
player_fields_array="aka roles alts accounts links xmpp mail skype repo forum"
player_fields_roles="content sound music gm code map pixel admin host wiki advisor translator packager web concept dude"

#
# player show/get
#
#

aux_player_show_chars_by_char() {
    result=$(aux_player_get_by_char "$1")
    [ -z "$result" ] || aux_player_show_chars_by_player "${result}"
}

aux_player_show_ids_by_char() {
    result=$(aux_player_get_by_char "$1")
    [ -z "$result" ] || aux_player_show_ids_by_player "${result}"
}

aux_player_show_parties_by_char() {
    result=$(aux_player_get_by_char "$1")
    [ -z "$result" ] || aux_player_show_parties_by_player "${result}"
}

aux_player_show_chars_by_id() {
    result=$(aux_player_get_by_id "$1")
    [ -z "$result" ] || aux_player_show_chars_by_player "${result}"
}

aux_player_show_ids_by_id() {
    result=$(aux_player_get_by_id "$1")
    [ -z "$result" ] || aux_player_show_ids_by_player "${result}"
}

aux_player_show_parties_by_id() {
    local party
    result=$(aux_player_get_by_id "$1")
    [ -z "$result" ] || aux_player_show_parties_by_player "${result}"
}

aux_player_show_chars_by_player() {
    aux_player_query_chardb "$1"
    aux_player_query_alts "$1"
}

aux_player_show_ids_by_player() {
    aux_player_query_chardb "$1"
    aux_player_query_alts "$1"
}

aux_player_show_parties_by_player() {
    local party
    aux_player_query_chardb "$1" | while read -r line; do
        party=$( func_party_get "${line#????????}" )
        if [ -z "${party}" ]; then
            printf "%s\n" "${line}"
        else
            printf "%-32s -- %s\n" "${line}" "${party}"
        fi
    done
    # player not recorded in dbchars most probably has no party known
    aux_player_query_alts "$1"
}

aux_player_query_chardb() {
    aux_player_ids "$1" | while read line; do
        aux_char_show_chars_by_id "${line}"
    done
}

aux_player_query_alts() {
    ${JQ} -r "if (.[\"player\"]==\"$1\") then \
        (if (.alts|length)>0 then .alts[] else empty end) \
        else empty end" "${playerdb}" 2>&-
}

func_player_show() {
    local output_format critetion
    output_format="chars"; critetion=""
    [ -z "$2" -a ! -z "$1" ] && {
        check_player "$1" || return 1
        aux_player_show_ids_by_player "$1"
        return
    }
    if [ "$1" != "by" ]; then
        case "$1" in
            chars|ids|parties) : ;;
            *) error_incorrect; return 1 ;;
        esac
        output_format="$1"
        shift
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$1" ] && { error_missing; return 1; }
    check_jq || return 2
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    case "${criterion}" in
        player) check_player "$1" || return 1 ;;
        id)     check_id "$1" || return 1 ;;
        char)   : ;;
        *)      error_incorrect; return 1 ;;
    esac
    eval aux_player_show_${output_format}_by_${criterion} \"\$@\"
    return $?
}

# if char in chardb, get accid and lookup playerdb with accid 
# otherwise try unresolved "alts" fields
aux_player_get_by_char() {
    result=$(func_char_get "$1")
    if [ -z "$result" ]; then
        check_string_chars "$1" "*[!a-zA-Z0-9-_/\\\!\@\#\$\%^\&\*\(\)\,\.\'\ ]*" \
            "Disallowed characters at charname" || return 1
        # escape backslash for awk + for json
        chname=$(printf "%s" "$1" | sed ${ESED} 's/\\/\\\\\\\\/g;s/([.*+!@#$%^/?[{|()])/\\\1/g')
        ${AWK} ${AWKPARAMS} -v chname="${chname}" -- '
        $0 ~ "\"alts\":\\[[^]]*\"" chname "\"" {
            sub("^.*\"player\":\"",""); sub("\".*$","")
            print; exit
            }
        ' ${playerdb}
    else
        aux_player_get_by_id "$result"
    fi
}

# only 1st match
aux_player_get_by_id() {
    check_string_chars "$1" "*[!0-9]*" "Invalid account ID" || return 1
    ${AWK} ${AWKPARAMS} -v accid="$1" -- '
    $0 ~ "\"accounts\":\\[[^]]*\"" accid "\"" {
        sub("^.*\"player\":\"",""); sub("\".*$","")
        print; exit
        }
    ' ${playerdb}
}

func_player_get() {
    local criterion
    [ -z "$2" -a ! -z "$1" ] && {
        aux_player_get_by_char "$1"
        return
    }
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    case "${criterion}" in
        char)   : ;;
        id)     check_id "$1" || return 1 ;;
        *)      error_incorrect; return 1 ;;
    esac
    eval aux_player_get_by_${criterion} \"\$1\"
    return $?
}

#
# player misc
#
#

# with FIELD as/in VALUE and/or FIELD as/in VALUE
# and so on
aux_player_list() {
    local pattern
    pattern=''
    [ "$1" = "with" ] || { error_incorrect; return 1; }
    shift
    check_jq || return 2
    # show with field
    [ -z "$2" -a ! -z "$1" ] && {
        ${JQ} -r --arg field "$1" "if has(\$field) then .player \
            else empty end" "${playerdb}" 2>&1
        return
    }
    # combine pattern
    while true; do
        if [ ! -z "$3" ]; then
            if [ "$2" = "as" ]; then
                escapedvalue=$( sed_chars "$3" )
                pattern="${pattern} contains({\"$1\":\"${escapedvalue}\"})"
                shift 3
            elif [ "$2" = "in" ]; then
                escapedvalue=$( sed_chars "$1" )
                pattern="${pattern} contains({\"$3\":[\"${escapedvalue}\"]})"
                shift 3
            elif [ "$2" = "not" -a "$3" = "as" -a ! -z "$4" ]; then
                escapedvalue=$( sed_chars "$4" )
                pattern="${pattern} (contains({\"$1\":\"${escapedvalue}\"})|not)"
                shift 4
            elif [ "$2" = "not" -a "$3" = "in" -a ! -z "$4" ]; then
                escapedvalue=$( sed_chars "$1" )
                pattern="${pattern} (contains({\"$4\":[\"${escapedvalue}\"]})|not)"
                shift 4
            else error_incorrect; return 1; fi
        else error_incorrect; return 1; fi
        if [ -z "$1" ]; then
            break
        elif [ "$1" = "and" -o "$1" = "or" ]; then
            pattern="${pattern} $1"
            shift
        else error_incorrect; return 1; fi
    done
    ${JQ} -r "if ${pattern} then .player \
        else empty end" "${playerdb}" 2>&-
}

# comma separated list
func_player_list() {
    result=$(aux_player_list "$@" | make_csv )
    [ -z "$result" ] || printf "%s\n" "$result"
}

# player per line
func_player_nlist() {
    aux_player_list "$@"
}

# args:
# 1 -- player
# 2.. -- fields to query
func_player_field() {
    local name
    [ -z "$1" -o -z "$2" ] && { error_missing; return 1; }
    name=$1; shift
    pat=$(
        for i in "$@"; do
        check_string_chars "$i" "*[!a-z]*" "Disallowed characters at field name" || return 1
        printf "\"%s\"\n" "$i"; done | make_csv) || return 1
    check_jq || return 2
    ${JQ} -c -M --arg name "${name}" "if (.[\"player\"]==\$name) then \
        {$pat} else empty end|with_entries(if (.value|length)>0 then \
        . else empty end) // empty" "${playerdb}" 2>&-
}

# args:
# 1 -- player
func_player_keys() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_jq || return 2
    ${JQ} -c -M --arg player "$1" "if (.[\"player\"]==\$player) then keys \
        else empty end" "${playerdb}" 2>&-
}

aux_player_ids() {
    ${JQ} -r --arg player "$1" 'if (.["player"]==$player) then
        .accounts // empty | .[] else empty end' "${playerdb}" 2>&-
}

# args:
# 1 -- player
func_player_ids() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_jq || return 2
    aux_player_ids "$1"
}

# args:
# 1 -- player
func_player_dump() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    grep -m 1 "\"player\":\"$1\"" "${playerdb}"
}

# args:
# 1 -- number
func_player_record() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters at player name" || return 1
    [ "$1" -eq 0 ] && return 1
    sed -n "$1{p;q}" "${playerdb}"
}

# args:
# 1 -- substring
func_player_search() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    result=$(grep -i "$1" "${playerdb}" 2>&1 | \
        sed ${ESED} -n 's/.*"player":"([^"]+)".*/\1/p' | make_csv )
        [ -z "$result" ] || printf "%s\n" "$result"
}

func_player_create() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    if grep -m 1 "\"player\":\"$1\"" "${playerdb}" >/dev/null 2>&1 ; then
        error "Player $1 exists."
    else
        check_string_chars "$1" "*[!${playerchars}]*" "Disallowed characters in player name" || return 1
        set_db_lock
        cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
        printf "{\"player\":\"%s\"}\n" "$1" >> "${playerdbtmp}"
        store_shared "${playerdbtmp}" "${playerdb}"
        unset_db_lock
        func_player_lregen
    fi
}

aux_player_sanitize() {
    # resolve alts
    ${JQ} -r "if (.[\"player\"]==\"$1\") then \
        (if (.alts|length)>0 then .alts[] else empty end) \
        else empty end" ${playerdbtmp} 2>&- | \
        while read -r charname; do
        # skip empty field. sanitize operation cleans them
        [ -z "$charname" ] && continue
        # chname=$(printf "%s" "$charname" | sed ${ESED} 's/\\/\\\\/g;s/([.*+!@#$%^/?[{|()])/\\\1/g')
        result=$(func_char_get "$charname")
        # error isn't expected
        if [ ! -z "$result" ]; then
            ${JQ} -c -M --arg alt "$charname" --arg accid "$result" \
                "if ((has(\"alts\") and (.alts|map(.==\$alt)|contains([true])))) \
                then ((.accounts|=.+[\$accid])|(.alts|=.-[\$alt])) else . end" \
                "${playerdbtmp}" > "${playerdbtmp2}" 2>&-
                # "if contains({\"alts\":[\$alt]}) then \
            # this sucks
            mv "${playerdbtmp2}" "${playerdbtmp}"
        fi
        done
    # remove duplicates, leave unique array elements; sort entries
    ${JQ} -S -c -M --arg player "$1" "if (.[\"player\"]==\$player) then \
        (with_entries(if (.value|length)>0 then (if (.value|type)==\"array\" \
        then .value|=(.|unique) else . end) else empty end)) else . end" \
        "${playerdbtmp}" > "${playerdbtmp2}" 2>&-
    store_shared "${playerdbtmp2}" "${playerdbtmp}"
}

# resolve all alts in player record
# args: PLAYER
func_player_resolve() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!${playerchars}]*" "Disallowed characters in player name" || return 1
    [ ! -s "${playerdb}" ] && return 3
    check_jq || return 2
    set_db_lock
    cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
    aux_player_sanitize "$@"
    store_shared "${playerdbtmp}" "${playerdb}"
    unset_db_lock
    func_player_lregen
}

# sanitize:
#   resolve all alts
# does not check default field types - string/array; use validation util
func_player_sanitize() {
    [ -z "$1" ] || { error_toomuch; return 1; }
    [ ! -s "${playerdb}" ] && return 3
    check_jq || return 2
    set_db_lock
    cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
    echo "Checking duplicate records..."
    # check repeated records
    sed ${ESED} -n 's/.*"player":"([^"]+)".*/\1/p' ${playerdb} | sort | \
        uniq -d | while read duplicate; do
        echo "Duplicated record: $duplicate"
    done
    echo "Clearing duplicate field elements and empty fields..."
    # make sure work only with valid records with "player" field
    sed ${ESED} -n 's/.*"player":"([^"]+)".*/\1/p' ${playerdbtmp} | \
        while read playername; do \
            aux_player_sanitize "$playername"
        done
    store_shared "${playerdbtmp}" "${playerdb}"
    unset_db_lock
    echo "Checking duplicate alts/accounts..."
    # report duplicates
    ( ${JQ} -c -M "if (.alts|length)>0 then \
        \"player \\(.player), alt \\(.alts[])\" else empty end" \
        "${playerdb}" 2>&-
        ${JQ} -c -M "if (.accounts|length)>0 then \
        \"player \\(.player), account \\(.accounts[])\" else empty end" \
        "${playerdb}" 2>&-
    ) | sort -t ',' -k 2 | ${AWK} ${AWKPARAMS} -- '
        BEGIN { FS=","; prev = ""; prevfield=""; dup = 0 }
        /^$/ { next }
        {
            if ( $2 == prevfield ) {
                print prev; dup++
            } else {
                if ( dup != 0) print prev
                dup = 0
            }
            prev = $0; prevfield = $2
        }
        END { if ( dup != 0) print prev }
    '
    [ -x ${TMWW_UTILPATH}/validjsonl.py ] && {
        echo "Validating known playerdb fields..."
        ${TMWW_UTILPATH}/validjsonl.py ${playerdb}
        [ $? -ne 0 ] && echo "Validation failed!"
    }
    echo "Sanitation finished."
    func_player_lregen
}

func_player_ref() {
    [ -z "$1" ] || { error_toomuch; return 1; }
    printf "string: %s\n" "${player_fields_string}"
    printf "array:  %s\n" "${player_fields_array}"
    printf "roles:  %s\n" "${player_fields_roles}"
}

# single backslash sequence will be added as is
# duplicate backslashes if you want to insert two or more backslashes in row
# duplicates in field elements will be skipped
# adding alt will attempt to resolve it
# adding account will not check for duplicates in other records
# PLAYER FIELD value VALUE
# PLAYER FIELD element VALUE
func_player_add() {
    [ -z "$5" -a ! -z "$4" ] || { error_incorrect; return 1; }
    # exit if field was player. use create/rename/remove to change player
    [ "$2" = "player" ] && return 1
    # enforce types for standart fields
    if printf "%s\n" "${player_fields_string}" | grep -wq -- "$2" ; then
        [ "$3" != "value" ] && { error_params "Field must be of string type"; return 1; }
    elif printf "%s\n" "${player_fields_array}" | grep -wq -- "$2" ; then
        [ "$3" != "element" ] && { error_params "Field must be array"; return 1; }
    fi
    # check lowercase field name
    check_string_chars "$2" "*[!a-z]*" "Field name must be lowercase" || return 1
    check_jq || return 2
    set_db_lock
    cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
    # result is undefined with non-default field of incompatible type
    if [ "$3" = "value" ]; then
        ${JQ} -S -c -M --arg name "$1" --arg element "$4" \
            "if (.[\"player\"]==\$name) \
            then .[\"$2\"] = \$element else . end" \
            "${playerdbtmp}" > "${playerdbtmp2}" 2>&-
    elif [ "$3" = "element" ]; then
        # check for duplicates in array
        if [ "$2" = "alts" ]; then
            result=$(func_char_get "$4")
            if [ -z "$result" ]; then
                field="$2"; element="$4"
            else
                field="accounts"; element="$result"
            fi
        else
            field="$2"; element="$4"
        fi
        # silly comparison bcause jq can't strict "contains"
        ${JQ} -S -c -M --arg name "$1" --arg element "$element" \
            "if ((.[\"player\"]==\$name) and \
            ((has(\"${field}\") and (.[\"${field}\"]|map(.==\$element)|contains([true])))|not)) \
            then .[\"${field}\"] += [\$element] else . end" \
            "${playerdbtmp}" > "${playerdbtmp2}" 2>&-
    else error_incorrect; unset_db_lock; return 1; fi
    if [ "$?" -eq 0 ]; then
        store_shared "${playerdbtmp2}" "${playerdb}"
    else
        error "Error occured. Contact db owner to check consistency."
    fi
    unset_db_lock
    func_player_lregen
}

aux_player_del_field() {
    check_jq || return 2
    set_db_lock
    cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
    ${JQ} -S -c -M --arg name "$1" --arg field "$2" \
        "if (.[\"player\"]==\$name) then \
        (with_entries(select(.key!=\$field))) else . end" \
        "${playerdbtmp}" > "${playerdbtmp2}" 2>&-
    if [ "$?" -eq 0 ]; then
        store_shared "${playerdbtmp2}" "${playerdb}"
    else
        error "Error occured. Contact db owner to check consistency."
    fi
    unset_db_lock
}

aux_player_del_element() {
    check_jq || return 2
    set_db_lock
    cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
    # remove element and field if no elements inside
    ${JQ} -S -c -M --arg name "$1" --arg element "$4" \
        "if ((.[\"player\"]==\$name) and \
        (has(\"$2\") and (.[\"$2\"]|map(.==\$element)|contains([true])))) \
        then .[\"$2\"] -= [\$element] else . end | \
        with_entries(if (.value|length)>0 then . else empty end)" \
        "${playerdbtmp}" > "${playerdbtmp2}" 2>&-
    if [ "$?" -eq 0 ]; then
        store_shared "${playerdbtmp2}" "${playerdb}"
    else
        error "Error occured. Contact db owner to check consistency."
    fi
    unset_db_lock
}

func_player_del() {
    # check lowercase field name
    check_string_chars "$2" "*[!a-z]*" "Field name must be lowercase." || return 1
    if [ -z "$3" -a -n "$2" ]; then
        aux_player_del_field "$@"
    elif [ -z "$5" -a -n "$4" -a "$3" = "element" ]; then
        aux_player_del_element "$@"
    else error_incorrect; fi
    func_player_lregen
}

func_player_remove() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    set_db_lock
    cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
    grep -v "\"player\":\"$1\"" "${playerdbtmp}" > "${playerdbtmp2}"
    store_shared "${playerdbtmp2}" "${playerdb}"
    unset_db_lock
    func_player_lregen
}

func_player_append() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    set_db_lock
    cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
    printf "%s\n" "$1" >> "${playerdbtmp}"
    store_shared "${playerdbtmp}" "${playerdb}"
    unset_db_lock
    func_player_lregen
}

# PLAYER to NEWNAME
func_player_rename() {
    [ -n "$4" ] && { error_toomuch; return 1; }
    [ -z "$3" ] && { error_missing; return 1; }
    [ "$2" != "to" ] && { error_incorrect; return 1; }
    check_string_chars "$3" "*[!${playerchars}]*" "Disallowed characters in player name" || return 1
    check_jq || return 2
    set_db_lock
    cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
    ${JQ} -S -c -M --arg name "$1" --arg newname "$3" \
        "if (.[\"player\"]==\$name) \
        then .player = \$newname else . end" \
        "${playerdbtmp}" > "${playerdbtmp2}" 2>&-
    if [ "$?" -eq 0 ]; then
        store_shared "${playerdbtmp2}" "${playerdb}"
    else
        error "Error occured. Contact db owner to check consistency."
    fi
    unset_db_lock
    func_player_lregen
}

# regenerate shortened playerdb version if limiteddb is in use
func_player_lregen() {
    # quite return if no there's no limited db
    [ "$TMWW_UPDATELIMITED" = "yes" ] || return 0
    # ensure previous command finished successfully
    [ "$err_flag" -ne 1 ] || return 1
    [ -z "$1" ] || { error_toomuch; return 1; }
    [ -f "${playerdb}" ] || return 3
    [ -f "${TMWW_UTILPATH}/lregen.players" ] || {
        error "Protected playerlist is missed!"
        return 3
    }
    set_db_lock
    ${AWK} ${AWKPARAMS} -- '
        FNR == NR && $1 !~ /^#/ { a[ $1 ]++ }
        {
            match($0,/"player":"([^"]+)"/);
            split(substr($0,RSTART,RLENGTH),b,/"/);
            # print "_" b[4] "_" a[b[4]] "_" ; next
            if ( ! ( b[4] in a ) ) print
        }
        ' "${TMWW_UTILPATH}/lregen.players" "${playerdb}" > "${limiteddb}"
    unset_db_lock
}

#
# arseoscope
#
#

func_arseoscope() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    result=$( func_char_get "$1" )
    [ -z "${result}" ] || {
        plresult=$( aux_player_get_by_id "${result}" )
        [ -z "${plresult}" ] || {
            accounts=$( aux_player_ids "${plresult}" | \
                ${AWK} ${AWKPARAMS} 'BEGIN{s=0}{s+=1}END{print s}')
            printf "playerdb alias: %s; %s known accounts; " "${plresult}" "${accounts}"
        }
        printf "%s: " "${result}"
        aux_char_show_chars_by_id "${result}" | make_csv
        echo
    }
}

#
# shared
#
#

# this pattern generator skips spaces for char/party fuzzy search functions
aux_fuzzy_pattern() {
    # constructing horrible case-insensitive pattern
    # with missed, suppressed and few l33t chars
    # this provides 1 possible error
    # for more possible errors just use agrep; seems ok with 1
    printf "%s" "$*" | sed "s/\(.\)/\1 /g" | ${AWK} ${AWKPARAMS} -- '
        BEGIN { chars = "" }
        {
            for ( i=1; i<=NF; i++ ) {
                s=""
                if ( $i ~ "l" ) s = "I"
                if ( $i ~ "I" ) s = "l"
                if ( $i ~ "O" ) s = "0"
                if ( $i ~ "0" ) s = "O"
                # if ( $i ~ "5" ) s = "sS"
                # if ( $i ~ "s|S" ) s = "5"
                chars = sprintf("%s%s", chars, "[" tolower($i) toupper($i) s "] ")
            }
            n = split(chars, fuzzy)
            # printf("(")
            # letter not found
            for ( i=1; i<=n; i++ ) {
                # printf("%s", fuzzy[1])
                for ( j=1; j<=n; j++ ) {
                    if ( j == i )
                        printf("%s?", fuzzy[j])
                    else
                        printf("%s", fuzzy[j])
                }
                printf("|")
            }
            # letter is different
            for ( i=1; i<=n; i++ ) {
                # printf("%s", fuzzy[1])
                for ( j=1; j<=n; j++ ) {
                    if ( j == i )
                        printf(".?")
                    else
                        printf("%s", fuzzy[j])
                }
                printf("|")
            }
            # missing letter between
            for ( i=1; i<n; i++ ) {
                for ( j=1; j<=n; j++ ) {
                    if ( j == i )
                        printf("%s.?", fuzzy[j])
                    else
                        printf("%s", fuzzy[j])
                }
                if ( i != n - 1) printf("|")
            }
            # printf(")")
        }
    '
}


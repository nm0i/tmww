#!/bin/sh
# tmww lib: db.lib.sh

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

# WARNING:  there's no SERVERPATH default. which means if you don't set it in
#           config you'll have to regenerate all variables based on SERVERPATH
#           by hand before you call any function using them
TMWW_SERVERDBPATH="${TMWW_SERVERDBPATH:-${TMWW_SERVERPATH}/world/map/db}"
# TMWW_SERVER="${TMWW_SERVER:-${TMWW_SERVERPATH}/}"

mobfiles='*_mob_db.txt
'

itemfiles='*_item_db.txt
'

# describe csv fields in order they are present in db
# format: single words
# IMPORTANT: no leading newline!
fieldsmob='ID Name Jname LV HP SP EXP JEXP Range1 ATK1 ATK2 DEF MDEF
STR AGI VIT INT DEX LUK Range2 Range3 Scale Race Element Mode Speed
Adelay Amotion Dmotion
D1id D1% D2id D2% D3id D3% D4id D4%
D5id D5% D6id D6% D7id D7% D8id D8%
Item1 Item2 MEXP ExpPer MVP1id MVP1per MVP2id MVP2per MVP3id MVP3per
mutationcount mutationstrength'

# describe fields in order they are present in db
# format: single words
# IMPORTANT: no leading newline!
fieldsitem='ID Name Label Type Price Sell Weight ATK DEF Range Mbonus
Slot Gender Loc wLV eLV View UseScript'

mobfieldsalias='drops d1id d2id d3id d4id d5id d6id d7id d8id
fulldrops d1id d1p d2id d2p d3id d3p d4id d4p d5id d5p d6id d6p d7id d7p d8id d8p
drop1id d1id
drop2id d2id
drop3id d3id
drop4id d4id
drop5id d5id
drop6id d6id
drop7id d7id
drop8id d8id
drop8id d8id
drop1per d1p
drop2per d2p
drop3per d3p
drop4per d4p
drop5per d5p
drop6per d6p
drop7per d7p
drop8per d8p
stats str agi vit int dex luk
lvl lv
level lv
m1 lvl hp sp speed stats
'

itemfieldsalias='i1 type typename weight atk def mbonus usescript
server_inventory id count name
server_storage id count name
server_summary id count name
'

# args:
# 1 -- field in space separated data to check
# 2 -- array to merge
# require $configdata
aux_conf_add_field() {
    local temp input
    temp=$( configdata=$( printf "%s\n" "${configdata}" | sed 's/\\/\\\\/g' )
        eval input=\"\$$2\"
        printf "%s\n" "${input}" | \
        ${AWK} ${AWKPARAMS} -v f="$1" -v d="${configdata}" -- '
        BEGIN { split(d,p,"\n")
            for (i in p) if (p[i] !~ "^ *#")
                {gsub("^ +","",p[i]);split(p[i],j); w[j[f]]=p[i]}}
        $f in w {print w[$f]; delete w[$f]; next}
        {print}
        END {for (k in w) print w[k]}' )
    eval $2=\"\${temp}\"
}

process_section "mobfieldsalias"
aux_conf_add_field 1 mobfieldsalias
process_section "itemfieldsalias"
aux_conf_add_field 1 itemfieldsalias
process_section "mobfiles"
[ -z "${configdata}" ] || mobfiles="${configdata}"
process_section "itemfiles"
[ -z "${configdata}" ] || itemfiles="${configdata}"

# prepafix each pattern, concat lines
db_prepare_files() {
    local f
    printf "%s" "$1" | while read line; do
        printf "%s " "${TMWW_SERVERDBPATH}/${line}"
    done
}

mobfiles=$( db_prepare_files "${mobfiles}" )
[ -z "${mobfiles}" ] && { error "No mob files found. Aborting."; return 1; }
itemfiles=$( db_prepare_files "${itemfiles}" )
[ -z "${itemfiles}" ] && { error "No item files found. Aborting."; return 1; }

# space-separated list of fields to output
compiled_fields=''
# space-separated list of compiled aliases and fields to prevent deadloop/repeats
compiled_aliases=''

# input - aliases/fields until "by" encountered
# WARNING:  server.plugin passes to item printer one more special column type
#           "count", this parser (for cli usage) doesn't have it
aux_compile_fields() {
    local i w f m
    i=0 # counter of alias/fields given to compile
    for f in "$@"; do
        [ "$f" = "by" ] && return $i
        check_string_chars "$f" "*[!-a-zA-Z0-9_]*" "Disallowed characters in field name" || return 1
        i=$(expr $i + 1)
        if echo "${compiled_aliases}" | grep -qw -- $f; then
            continue
        fi
        # first try alias then field
        if echo "${fieldsalias}" | grep -q -- "^$f " ; then
            aux_compile_fields $(printf "%s" "${fieldsalias}" | grep "^$f" | cut -d ' ' -f 2- ) || return 1
        elif [ "$f" = "fname" ]; then
            compiled_fields="${compiled_fields} fname fname"
            compiled_aliases="${compiled_aliases} $f"
        elif [ "${mode}" = "item" -a "$f" = "count" -a -n "${db_item_count}" ]; then
            compiled_fields="${compiled_fields} count count"
            compiled_aliases="${compiled_aliases} $f"
        elif [ "${mode}" = "item" -a "$f" = "typename" ]; then
            need_type=1
            compiled_fields="${compiled_fields} typename typename"
            compiled_aliases="${compiled_aliases} $f"
        elif echo "${fieldslist}" | grep -qwi -- $f ; then
            m=$( sed_chars "$f" )
            w=$( printf "%s\n" "${fieldslist}" | tr ' ' '\n' | tr -s '\n' |
                sed -n "y/${ucase}/${lcase}/;/$m/{=;q}" )
            m=$( printf "%s\n" "${fieldslist}" | grep -wiom1 "$f" )
            [ -z "$w" ] && { error "Unknown field $f. Aborting." ; return 1; }
            if [ "${mode}" = "mob" ]; then
                compiled_fields="${compiled_fields} mob $m $(expr $w + 1)"
            else
                compiled_fields="${compiled_fields} item $m $(expr $w + 1)"
            fi
            compiled_aliases="${compiled_aliases} $f"
        else
            error "Unknown field $f. Aborting." ; return 1
        fi
    done
}

aux_compile_items() {
    local mode
    fieldslist="${fieldsitem}"
    fieldsalias="${itemfieldsalias}"
    compiled_fields=''; compiled_aliases=''
    need_type=''
    mode="item"
    aux_compile_fields "$@"
    return $?
}

aux_compile_mobs() {
    local mode
    fieldslist="${fieldsmob}"
    fieldsalias="${mobfieldsalias}"
    compiled_fields=''; compiled_aliases=''
    mode="mob"
    aux_compile_fields "$@"
    return $?
}

# require variable "res" with lines to print
# require variable "db_command" to determine item/mob output
aux_db_print() {
    {
        [ -n "${res}" ] && {
            if [ "${db_command}" = "item" ]; then
                [ -n "${db_no_caption}" ] || {
                    printf "%s" "${fieldsitem}" | tr ' ' '\t' | tr '\n' '\t'; printf "\n" ; }
                printf "%s\n" "${res}" | sed "s/, */${tabchar}/g"
            else
                [ -n "${db_no_caption}" ] || {
                    printf "%s" "${fieldsmob}" | tr ' ' '\t' | tr '\n' '\t'; printf "\n" ; }
                printf "%s\n" "${res}" | sed "s/, */${tabchar}/g"
            fi
        } | if [ -n "${db_cut_fields}" ]; then cut -f "${db_cut_fields}" ; else cat; fi
    } | if [ -z "${db_raw_fields}" ]; then column -ts "${tabchar}"  ; else cat; fi
}

# args: pairs of field and field type
# example: gp db login acc mail acc #BankAccount reg
# arguments are prepared/compiled by aux_compile_wrapper
aux_db_fields_printer() {
    local t n pcontent
    # printf "arg: %s\n" "$@"
    nofield=''
    if [ -n "$1" ]; then
        [ -z "$2" ] && { error "Internal error: incorrect fields format"; return 1; }
        case "$1" in
            count)
                [ -z "${server_no_caption}" ] &&
                    fields_caption="${fields_caption}"$(printf "N\011" )
                # reorder inventory items count to match grep output order
                pcontent=$( printf "%s" "${prepared_db}" | cut -f 2 | while read line; do
                    printf "%s\n" "${db_item_count}" | sed -n "/^${line},/{s/.*,//p;q}"
                done)
                shift 2
                ;;
            mob|item)
                [ -z "$3" ] && { error "Internal error: incorrect fields format"; return 1; }
                [ -z "${server_no_caption}" ] &&
                    fields_caption="${fields_caption}"$(printf "%s\011" "$2" )
                # something awful here
                if [ "$2" = "UseScript" ]; then
                    pcontent=$( printf "%s" "${prepared_db}" | cut -f "$3-" | tr '\t' ',' )
                else
                    pcontent=$( printf "%s" "${prepared_db}" | cut -f "$3" )
                fi
                shift 3
                ;;
            fname)
                [ -z "${server_no_caption}" ] &&
                    fields_caption="${fields_caption}"$(printf "Filename\011" )
                pcontent=$( printf "%s" "${prepared_db}" | cut -f 1 )
                shift 2
                ;;
            typename)
                [ -z "${server_no_caption}" ] &&
                    fields_caption="${fields_caption}"$(printf "Typename\011" )
                t=$( printf "%s\n" "${fieldslist}" | tr ' ' '\n' | tr -s '\n' |
                    sed -n "/Type/{=;q}" )
                t=$( expr $t + 1 )
                if [ -n "${fields_single_target}" ]; then
                    t=$( get_tab $t "${prepared_db}" )
                    pcontent=$( get_element 1 $(printf "%s" "${prepared_typename}" | grep " $t$" ))
                else
                    pcontent=$( printf "%s\n" "${prepared_db}" | while read line; do
                        n=$( get_tab "$t" "${line}" )
                        n=$(get_element 1 $(printf "%s\n" "${prepared_typename}" | grep " $n$" ))
                        printf "%s\n" "${n:- }"
                    done )
                fi
                shift 2
                ;;
            *)  error "Internal error: incorrect fields format"; return 1 ;;
        esac
        if [ -n "${fields_single_target}" ]; then
            fields_content="${fields_content}"$(printf "%s\011" "${pcontent:- }")
        else
            if [ -z "${fields_content}" ]; then
                fields_content="${pcontent}"
            else
                fields_content=$( pcontent=$( printf "%s" "${pcontent}" | sed 's/\\/\\\\/g' )
                    printf "%s\n" "${fields_content}" | \
                    ${AWK} ${AWKPARAMS} -v p="${pcontent}" -- '
                    BEGIN { split(p,f,"\n") } { if (f[NR]!="") a=f[NR]; else a=" "; print $0 "\011" a } ' )
            fi
        fi
    else
        {
            [ -z "${db_no_caption}" -a -n "${fields_caption}" ] && printf "%s\n" "${fields_caption}"
            printf "%s\n" "${fields_content}"
        } | if [ -z "${db_raw_fields}" ]; then column -ts "${tabchar}" ; else cat; fi
        return 0
    fi
    aux_db_fields_printer "$@"
}

aux_db_cut_fields() {
    sed ${ESED} "s| *//.*$||;s|^.*/([^:]+):|\1${tabchar}|;s/ *, */${tabchar}/g"
}

aux_db_itemset_pattern() {
    local i
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    if [ -f "${TMWW_UTILPATH}/$1.id.itemset" ]; then
        while read i; do
            check_string_chars "$i" "*[!0-9]*" "Disallowed characters in NAME $i" || return 1
            patt="${patt:+${patt}|}$i"
        done < "${TMWW_UTILPATH}/$1.id.itemset"
    elif [ -f "${TMWW_UTILPATH}/$1.name.itemset" ]; then
        while read i; do
            check_string_chars "$i" "*[!a-zA-Z]*" "Disallowed characters in NAME $i" || return 1
            patt="${patt:+${patt}|}$i"
        done < "${TMWW_UTILPATH}/$1.name.itemset"
    else
        error "No itemset file found. Aborting."
        return 1
    fi
    patt="(${patt})"
}

#
# item
#
#

aux_item_get_id_by_id() {
    printf "%s\n" "$1"
}

aux_item_get_name_by_name() {
    printf "%s\n" "$1"
}

aux_item_get_id_by_name() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!a-zA-Z]*" "Disallowed characters in NAME" || return 1
    cat ${itemfiles} | egrep -m 1 "^${csv}$1," | cut -f 1 -d ','
}

aux_item_get_name_by_id() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in ID" || return 1
    cat ${itemfiles} | grep -m 1 "^$1," | cut -f 2 -d ',' | tr -d ' '
}

aux_item_get_db_by_name() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!a-zA-Z]*" "Disallowed characters in NAME" || return 1
    res=$(cat ${itemfiles} | egrep -m 1 "^${csv}$1,")
    aux_db_print
}

aux_item_get_db_by_id() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in ID" || return 1
    res=$(cat ${itemfiles} | grep -m 1 "^$1," )
    aux_db_print
}

aux_item_fields_common() {
    local append
    if [ -n "${need_type}" ]; then
        prepared_typename=$( sed -n '/^ *equip_/{s/ *equip_//p}' "${TMWW_SERVERDBPATH}/const.txt" )
    fi
    fields_content=''; fields_caption=''; append=''
    [ -z "${db_suppress_append}" ] && append="item ID 2 item Name 3"
    aux_db_fields_printer ${compiled_fields} ${append} || return 1
}

aux_item_get_fields_by_id() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    fields_single_target=1
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in ID" || return 1
    prepared_db=$(grep -m 1 "^$1," ${itemfiles} | aux_db_cut_fields )
    aux_item_fields_common "$@" || return 1
}

aux_item_get_fields_by_name() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    fields_single_target=1
    check_string_chars "$1" "*[!a-zA-Z]*" "Disallowed characters in NAME" || return 1
    prepared_db=$(egrep -m 1 "^${csv}$1," ${itemfiles} | aux_db_cut_fields )
    aux_item_fields_common "$@" || return 1
}

func_item_get() {
    local output_format criterion
    output_format=''; criterion=''
    [ -z "$2" -a -n "$1" ] && {
        aux_item_get_id_by_name "$@" || return 1
        return 0
    }
    output_format="id"
    if [ "$1" != "by" ]; then
        case "$1" in
            id)         output_format="id"; shift ;;
            name)       output_format="name"; shift ;;
            db)
                output_format="db"
                db_command="item"
                shift
                ;;
            *)
                output_format="fields"
                aux_compile_items "$@"
                shift $?
                [ "${err_flag}" -eq 0 2>&- ] || return 1
                ;;
        esac
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    case "${criterion}" in
        id)     [ "${output_format}" = "id" ] && output_format="name" ;;
        name)   : ;;
        *)      error_incorrect; return 1; ;;
    esac
    eval aux_item_get_${output_format}_by_${criterion} \"\$@\"
    return $?
}

# names_by_N are reasonable mostly for displaying itemset from ids

aux_item_show_names_by_names() { return ; }
aux_item_show_names_by_ids() { return ; }
aux_item_show_names_by_re() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    egrep -i "^${csv}.*$1.*," ${itemfiles} |
        aux_db_cut_fields | cut -f 3
}

aux_item_show_names_by_itemset() {
    local patt
    aux_db_itemset_pattern "$@" || return 1
    [ -z "${patt}" ] && return
    if [ -f "${TMWW_UTILPATH}/$1.id.itemset" ]; then
        egrep "^${patt}," ${itemfiles}
    elif [ -f "${TMWW_UTILPATH}/$1.name.itemset" ]; then
        egrep "^${csv}${patt}," ${itemfiles}
    fi | aux_db_cut_fields | cut -f 3 | column -t
}

# ids_by_N are reasonable mostly for converting itemset

aux_item_show_ids_by_names() { return ; }
aux_item_show_ids_by_ids() { return ; }

# grep analogue
aux_item_show_ids_by_re() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    egrep -i "^${csv}.*$1.*," ${itemfiles} |
        aux_db_cut_fields | cut -f 2,3 | column -t
}

aux_item_show_ids_by_itemset() {
    local patt
    aux_db_itemset_pattern "$@" || return 1
    [ -z "${patt}" ] && return
    if [ -f "${TMWW_UTILPATH}/$1.id.itemset" ]; then
        egrep "^${patt}," ${itemfiles}
    elif [ -f "${TMWW_UTILPATH}/$1.name.itemset" ]; then
        egrep "^${csv}${patt}," ${itemfiles}
    fi | aux_db_cut_fields | cut -f 2 | column -t
}

aux_item_show_db_by_names() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!a-zA-Z]*" "Disallowed characters in NAME $i" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    res=$(cat ${itemfiles} | egrep "^${csv}${patt},")
    aux_db_print
}

aux_item_show_db_by_ids() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!0-9]*" "Disallowed characters in ID" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    res=$(cat ${itemfiles} | egrep "^${patt}," )
    aux_db_print
}

aux_item_show_db_by_re() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    res=$(cat ${itemfiles} | egrep -i "^${csv}.*$1.*," )
    aux_db_print
}

aux_item_show_db_by_itemset() {
    local patt
    aux_db_itemset_pattern "$@" || return 1
    [ -z "${patt}" ] && return
    if [ -f "${TMWW_UTILPATH}/$1.id.itemset" ]; then
        res=$(egrep -h "^${patt}," ${itemfiles} )
    elif [ -f "${TMWW_UTILPATH}/$1.name.itemset" ]; then
        res=$(egrep -h "^${csv}${patt}," ${itemfiles} )
    fi
    aux_db_print
}

aux_item_show_fields_by_ids() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!0-9]*" "Disallowed characters in ID" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    prepared_db=$(egrep "^${patt}," ${itemfiles} | aux_db_cut_fields )
    aux_item_fields_common "$@" || return 1
}

aux_item_show_fields_by_names() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!a-zA-Z]*" "Disallowed characters in NAME $i" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    prepared_db=$(egrep "^${csv}${patt}," ${itemfiles} | aux_db_cut_fields )
    aux_item_fields_common "$@" || return 1
}

aux_item_show_fields_by_re() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    prepared_db=$(egrep -i "^${csv}.*$1.*," ${itemfiles} | aux_db_cut_fields )
    aux_item_fields_common "$@" || return 1
}

aux_item_show_fields_by_itemset() {
    local patt
    aux_db_itemset_pattern "$@" || return 1
    [ -z "${patt}" ] && return
    if [ -f "${TMWW_UTILPATH}/$1.id.itemset" ]; then
        prepared_db=$(egrep "^${patt}," ${itemfiles} | aux_db_cut_fields )
    elif [ -f "${TMWW_UTILPATH}/$1.name.itemset" ]; then
        prepared_db=$(egrep "^${csv}${patt}," ${itemfiles} | aux_db_cut_fields )
    fi
    aux_item_fields_common "$@" || return 1
}

func_item_show() {
    local output_format criterion
    output_format=''; criterion=''
    output_format="db"
    db_command="item"
    if [ "$1" != "by" ]; then
        case "$1" in
            names)  output_format="names"; shift ;;
            ids)    output_format="ids"; shift ;;
            db)
                output_format="db"
                shift
                ;;
            *)
                output_format="fields"
                aux_compile_items "$@"
                shift $?
                [ "${err_flag}" -eq 0 2>&- ] || return 1
                ;;
        esac
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    case "${criterion}" in
        ids|names|re|itemset) : ;;
        *) error_incorrect; return 1; ;;
    esac
    eval aux_item_show_${output_format}_by_${criterion} \"\$@\"
    return $?
}

aux_item_mobs() {
    local f
    [ -z "${patt}" ] && return 0
    patt="(${patt})"
    f=$( printf "%s\n" "${fieldsmob}" | tr ' ' '\n' | tr -s '\n' | sed -n "/D1id/{=;q}" )
    ${AWK} ${AWKPARAMS} -F ',' -v f="$f" -v p=" *${patt} *" -- '
        /^\/\// || /^$/ {next}
        { for (i=0;i<16;i=i+2) if ($i ~ p) { print; next } }
    ' ${mobfiles} | cut -f 1,2 -d ','
}

aux_item_mobs_by_ids() {
    local patt i
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!0-9]*" "Disallowed characters in ID" || return 1
        patt="${patt:+${patt}|}$i"
    done
    aux_item_mobs
}

aux_item_mobs_by_names() {
    local patt i
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!a-zA-Z]*" "Disallowed characters in NAME $i" || return 1
        i=$( aux_item_get_id_by_name "$i" )
        patt="${patt:+${patt}|}$i"
    done
    aux_item_mobs
}

aux_item_mobs_by_re() {
    local patt i
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    patt=$( i=''; egrep -hi "^${csv}.*$1.*," ${itemfiles} | sed 's/,.*//' | while read line; do
        [ -n "$i" ] && printf "|"; printf "%s" "${line}"; i=1; done )
    aux_item_mobs
}

func_item_mobs() {
    local criterion
    criterion=''
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    case "${criterion}" in
        ids|names|re) : ;;
        *) error_incorrect; return 1; ;;
    esac
    eval aux_item_mobs_by_${criterion} \"\$@\"
    return $?
}

#
# mob
#
#

aux_mob_get_id_by_id() {
    printf "%s\n" "$1"
}

aux_mob_get_name_by_name() {
    printf "%s\n" "$1"
}

aux_mob_get_id_by_name() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!a-zA-Z]*" "Disallowed characters in NAME" || return 1
    cat ${mobfiles} | egrep -m 1 "^${csv}$1," | cut -f 1 -d ','
}

aux_mob_get_name_by_id() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in ID" || return 1
    cat ${mobfiles} | grep -m 1 "^$1," | cut -f 2 -d ',' | tr -d ' '
}

aux_mob_get_db_by_name() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!a-zA-Z]*" "Disallowed characters in NAME" || return 1
    res=$(cat ${mobfiles} | egrep -m 1 "^${csv}$1,")
    aux_db_print
}

aux_mob_get_db_by_id() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in ID" || return 1
    res=$(cat ${mobfiles} | grep -m 1 "^$1," )
    aux_db_print
}

aux_mob_fields_common() {
    local append
    fields_content=''; fields_caption=''; append=''
    [ -z "${db_suppress_append}" ] && append="mob ID 2 mob Name 3"
    aux_db_fields_printer ${compiled_fields} ${append} || return 1
}

aux_mob_get_fields_by_id() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    fields_single_target=1
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in ID" || return 1
    prepared_db=$(grep -m 1 "^$1," ${mobfiles} | aux_db_cut_fields )
    aux_mob_fields_common || return 1
}

aux_mob_get_fields_by_name() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    fields_single_target=1
    check_string_chars "$1" "*[!a-zA-Z]*" "Disallowed characters in NAME" || return 1
    prepared_db=$(egrep -m 1 "^${csv}$1," ${mobfiles} | aux_db_cut_fields )
    aux_mob_fields_common || return 1
}

func_mob_get() {
    local output_format criterion
    output_format=''; criterion=''
    [ -z "$2" -a -n "$1" ] && {
        aux_mob_get_id_by_name "$@" || return 1
        return 0
    }
    output_format="id"
    db_command="mob"
    if [ "$1" != "by" ]; then
        case "$1" in
            id)         output_format="id"; shift ;;
            name)       output_format="name"; shift ;;
            db)
                output_format="db"
                shift
                ;;
            *)
                output_format="fields"
                aux_compile_mobs "$@"
                shift $?
                [ "${err_flag}" -eq 0 2>&- ] || return 1
                ;;
        esac
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    case "${criterion}" in
        id)     [ "${output_format}" = "id" ] && output_format="name" ;;
        name)   : ;;
        *)      error_incorrect; return 1; ;;
    esac
    eval aux_mob_get_${output_format}_by_${criterion} \"\$@\"
    return $?
}

aux_mob_show_db_by_names() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!a-zA-Z]*" "Disallowed characters in NAME $i" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    res=$(cat ${mobfiles} | egrep "^${csv}${patt},")
    aux_db_print
}

aux_mob_show_db_by_ids() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!0-9]*" "Disallowed characters in ID" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    res=$(cat ${mobfiles} | egrep "^${patt}," )
    aux_db_print
}

aux_mob_show_db_by_re() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    res=$(cat ${mobfiles} | egrep -i "^${csv}.*$1.*," )
    aux_db_print
}

aux_mob_show_fields_by_ids() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!0-9]*" "Disallowed characters in ID" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    prepared_db=$(egrep "^${patt}," ${mobfiles} | aux_db_cut_fields )
    aux_mob_fields_common || return 1
}

aux_mob_show_fields_by_names() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!a-zA-Z]*" "Disallowed characters in NAME $i" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    prepared_db=$(egrep "^${csv}${patt}," ${mobfiles} | aux_db_cut_fields )
    aux_mob_fields_common || return 1
}

aux_mob_show_fields_by_re() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    prepared_db=$(egrep -i "^${csv}.*$1.*," ${mobfiles} | aux_db_cut_fields )
    aux_mob_fields_common || return 1
}

aux_mob_show_names_by_names() { return ; }
aux_mob_show_names_by_ids() { return ; }
aux_mob_show_names_by_re() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    egrep -i "^${csv}.*$1.*," ${mobfiles} |
        aux_db_cut_fields | cut -f 3
}

aux_mob_show_ids_by_names() { return ; }
aux_mob_show_ids_by_ids() { return ; }
aux_mob_show_ids_by_re() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    egrep -i "^${csv}.*$1.*," ${mobfiles} |
        aux_db_cut_fields | cut -f 2,3 | column -t
}

func_mob_show() {
    local output_format criterion
    output_format=''; criterion=''
    output_format="db"
    db_command="mob"
    if [ "$1" != "by" ]; then
        case "$1" in
            names)  output_format="names"; shift ;;
            ids)    output_format="ids"; shift ;;
            db)
                output_format="db"
                shift
                ;;
            *)
                output_format="fields"
                aux_compile_mobs "$@"
                shift $?
                [ "${err_flag}" -eq 0 2>&- ] || return 1
                ;;
        esac
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    case "${criterion}" in
        ids|names|re) : ;;
        *) error_incorrect; return 1; ;;
    esac
    eval aux_mob_show_${output_format}_by_${criterion} \"\$@\"
    return $?
}

aux_mob_drops() {
    local f1 f2
    f1=$( printf "%s\n" "${fieldsmob}" | tr ' ' '\n' | tr -s '\n' | sed -n "/D1id/{=;q}" )
    f2=$(expr ${f1} + 15 )
    aux_db_cut_fields |
    cut -f "${f1}-${f2}" | tr '\t' '\n' | while read drop; do
        read prob
        [ "${drop}" = "0" ] && continue
        printf "%3.2f%%\t%s\t%s\n" "$( echo "scale=2;${prob}/100" | bc )" \
            "${drop}" "$( aux_item_get_name_by_id ${drop} )"
    done | if [ -z "${db_raw_fields}" ]; then column -t ; else cat; fi
}

aux_mob_drops_by_id() {
    local drop prob
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in ID" || return 1
    cat ${mobfiles} | grep -m 1 "^$1," | aux_mob_drops
}

aux_mob_drops_by_name() {
    local drop prob
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    check_string_chars "$1" "*[!a-zA-Z]*" "Disallowed characters in NAME" || return 1
    cat ${mobfiles} | egrep -m 1 "^${csv}$1," | aux_mob_drops
}

func_mob_drops() {
    local criterion
    criterion=''
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    case "${criterion}" in
        id|name)    : ;;
        *)          error_incorrect; return 1; ;;
    esac
    eval aux_mob_drops_by_${criterion} \"\$@\"
    return $?
}


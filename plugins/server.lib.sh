#!/bin/sh
# tmww lib: server.lib.sh

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

# ensure player.lib.sh imported
requireplugin player.lib.sh || return 1

# WARNING:  there's no SERVERPATH default. which means if you don't set it in
#           config you'll have to regenerate all variables based on SERVERPATH
#           by hand before you call any function using them
TMWW_SERVERDB="${TMWW_SERVERDB:-${TMWW_SERVERPATH}/world/save/athena.txt}"
TMWW_SERVERACCS="${TMWW_SERVERACCS:-${TMWW_SERVERPATH}/login/save/account.txt}"
TMWW_SERVERGM="${TMWW_SERVERGM:-${TMWW_SERVERPATH}/login/save/gm_account.txt}"
TMWW_SERVERREG="${TMWW_SERVERREG:-${TMWW_SERVERPATH}/world/save/accreg.txt}"
TMWW_SERVERPARTY="${TMWW_SERVERPARTY:-${TMWW_SERVERPATH}/world/save/party.txt}"
TMWW_SERVERSTORAGE="${TMWW_SERVERSTORAGE:-${TMWW_SERVERPATH}/world/save/storage.txt}"
TMWW_SERVERSKILLDB="${TMWW_SERVERSKILLDB:-${TMWW_SERVERPATH}/world/map/db/skill_db.txt}"
# TMWW_SERVER="${TMWW_SERVER:-${TMWW_SERVERPATH}/}"

AGREP=/usr/bin/agrep

# chars allowed in query expression as field name
fieldchars="-a-zA-Z0-9_\$\#"

check_agrep() {
    if ! command -v ${AGREP} >/dev/null 2>&1 ; then
        error "agrep not found. Aborting."
        return 1
    fi
}

check_pcid() {
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in PCID" || return 1
}

check_partyid() {
    check_string_chars "$1" "*[!0-9]*" "Disallowed characters in PARTYID" || return 1
}

fieldsdb='1 1 pcid
2 1 accid
2 2 slot
3 1 charname
4 2 lvl
5 1 exp
5 2 job
5 3 gp
7 1 str
7 2 agi
7 3 vit
7 4 int
7 5 dex
7 6 luk
10 1 partyid
7 1- fstats
18 1- fskills
19 1- fvars
'

fieldsaccs='2 login
3 hash
4 date
5 g
6 counter
8 mail
11 lastip
'

fieldsvars='sgp #BankAccount
'

serverfieldsalias='pid partyid
zeny gp
agp gp sgp
stats str agi vit int dex luk
qdb pcid gp lvl exp job stats
gender g
accname login
seen counter
ip lastip
qacc login counter lastip mail date time
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

process_section "fieldsdb"
aux_conf_add_field 3 fieldsdb
process_section "fieldsaccs"
aux_conf_add_field 2 fieldsaccs
process_section "fieldsvars"
aux_conf_add_field 1 fieldsvars
process_section "serverfieldsalias"
aux_conf_add_field 1 serverfieldsalias

# space-separated list of fields to output
compiled_fields=''
# space-separated list of compiled aliases and fields to prevent deadloop/repeats
compiled_aliases=''
# comma-separated list of fields to find in accreg.txt
compiled_reg=''

# input - aliases/fields until "by" encountered
# chars allowed should be possible chars for script variable name
aux_compile_fields() {
    local i w f
    i=0 # counter of alias/fields given to compile
    for f in "$@"; do
        [ "$f" = "by" ] && return $i
        check_string_chars "$f" "*[!${fieldchars}]*" "Disallowed characters in field name" || return 1
        i=$(expr $i + 1)
        if echo "${compiled_aliases}" | grep -qw -- $f; then
            continue
        fi
        # first try alias then field
        if echo "${serverfieldsalias}" | grep -q "^$f " ; then
            aux_compile_fields $(printf "%s" "${serverfieldsalias}" | grep "^$f" | cut -d ' ' -f 2- )
        elif [ "$f" = "party" ]; then
            need_party=1
            compiled_fields="${compiled_fields} party party"
            compiled_aliases="${compiled_aliases} $f"
        elif [ "$f" = "gm" ]; then
            need_gm=1
            compiled_fields="${compiled_fields} gm gm"
            compiled_aliases="${compiled_aliases} $f"
        elif echo "${fieldsdb}" | grep -qw -- $f ; then
            need_db=1
            compiled_fields="${compiled_fields} db $f"
            compiled_aliases="${compiled_aliases} $f"
        elif echo "${fieldsaccs}" | grep -qw -- $f ; then
            need_accs=1
            compiled_fields="${compiled_fields} accs $f"
            compiled_aliases="${compiled_aliases} $f"
        elif echo "${fieldsvars}" | grep -q "^$f" ; then
            need_reg=1
            w=$(printf "%s" "${fieldsvars}" | grep "^$f" | cut -d ' ' -f 2 )
            compiled_fields="${compiled_fields} reg $f"
            compiled_aliases="${compiled_aliases} $f $w"
            w=$( sed_chars "$w" )
            compiled_reg="${compiled_reg:+${compiled_reg}|}$w"
        else
            # everything else taken as query for accreg.txt
            need_reg=1
            compiled_fields="${compiled_fields} reg $f"
            compiled_aliases="${compiled_aliases} $f"
            w=$( sed_chars "$f" )
            compiled_reg="${compiled_reg:+${compiled_reg}|}$w"
        fi
    done
}

aux_compile_wrapper() {
    local e
    # reentrant stuff
    compiled_fields=''; compiled_aliases=''; compiled_reg=''
    need_db=''; need_accs=''; need_reg=''; need_party=''; need_gm=''
    aux_compile_fields "$@"
    e=$?
    compiled_reg="(${compiled_reg})"
    return $e
}

#
# char
#
#

func_char_fuzzy() {
    local output_format
    output_format=""
    if [ -z "$2" ]; then
        output_format="chars"
    elif [ "$1" = "chars" -a -z "$3" ]; then
        shift; output_format="names"
    elif [ "$1" = "ids" -a -z "$3" ]; then
        shift; output_format="ids"
    elif [ "$1" = "pcids" -a -z "$3" ]; then
        shift; output_format="pcids"
    fi
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    if ! printf "%s" "$1" | egrep -q '^[-a-zA-Z0-9_/\., ]+$'; then
        error_incorrect; return 1; fi
    patt=$( aux_fuzzy_pattern $1 )
    if [ "$output_format" = "chars" ]; then
        cut -f 3 "${TMWW_SERVERDB}" | egrep -i -- "${patt}"
    elif [ "$output_format" = "ids" ]; then
        ${AWK} ${AWKPARAMS} -v patt="$1" -F '\t' -- ' BEGIN{patt=tolower(patt)}
            { t=tolower($3); if (t~patt)
                {split($2,id,","); print id[1], $3} }
        ' "${TMWW_SERVERDB}"
    else
        ${AWK} ${AWKPARAMS} -v patt="$1" -F '\t' -- ' BEGIN{patt=tolower(patt)}
            { t=tolower($3); if (t~patt)
                {split($2,id,","); print $1, id[1], $3} }
        ' "${TMWW_SERVERDB}"
    fi
}

func_char_agrep() {
    local output_format
    output_format=""; faultlevel=1
    check_agrep || return 1
    OPTIND=1
    while ${GETOPTS} e: opt ; do
        case $opt in
            e)  faultlevel="${OPTARG}" ;;
            *)  error_incorrect; return 1 ;;
        esac
    done
    shift $(expr $OPTIND - 1)
    if [ -z "$2" ]; then
        output_format="chars"
    elif [ "$1" = "chars" -a -z "$3" ]; then
        shift; output_format="names"
    elif [ "$1" = "ids" -a -z "$3" ]; then
        shift; output_format="ids"
    elif [ "$1" = "pcids" -a -z "$3" ]; then
        shift; output_format="pcids"
    fi
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    chname=$( sed_chars "$1" )
    # NOTE: fix agrep expression if you want faster result
    if [ "$output_format" = "chars" ]; then
        agrep -i ${faultlevel:+-$faultlevel} "^#${chname}" "${TMWW_SERVERDB}" | cut -f 3
    elif [ "$output_format" = "ids" ]; then
        agrep -i ${faultlevel:+-$faultlevel} "^#${chname}" "${TMWW_SERVERDB}" | \
            ${AWK} ${AWKPARAMS} -- '{split($2,id,","); print id[1], $3}'
    else
        agrep -i ${faultlevel:+-$faultlevel} "^#${chname}" "${TMWW_SERVERDB}" | \
            ${AWK} ${AWKPARAMS} -- '{split($2,id,","); print $1, id[1], $3}'
    fi
}

func_char_grep() {
    local output_format
    output_format=""
    if [ -z "$2" ]; then
        output_format="chars"
    elif [ "$1" = "chars" -a -z "$3" ]; then
        shift; output_format="names"
    elif [ "$1" = "ids" -a -z "$3" ]; then
        shift; output_format="ids"
    elif [ "$1" = "pcids" -a -z "$3" ]; then
        shift; output_format="pcids"
    fi
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    patt=$( sed_chars "$1" )
    if [ "$output_format" = "chars" ]; then
        cut -f 3 "${TMWW_SERVERDB}" | egrep -i -- "${patt}"
    elif [ "$output_format" = "ids" ]; then
        ${AWK} ${AWKPARAMS} -v patt="$1" -F '\t' -- ' BEGIN{patt=tolower(patt)}
            { t=tolower($3); if (t~patt)
                {split($2,id,","); print id[1], $3} }
        ' "${TMWW_SERVERDB}"
    else
        ${AWK} ${AWKPARAMS} -v patt="$1" -F '\t' -- ' BEGIN{patt=tolower(patt)}
            { t=tolower($3); if (t~patt)
                {split($2,id,","); print $1, id[1], $3} }
        ' "${TMWW_SERVERDB}"
    fi
}

# massive lookup - grep + lookup all grep matches
func_char_dig() {
    local ids
    ids=$(func_char_grep ids "$1" | cut -d ' ' -f 1)
    [ -z "${ids}" ] && return 1
    for i in ${ids} ; do
        aux_char_show_pcids_by_id $i
    done | sort -k 2,2 -t ' ' | uniq
}

#
# char get
#
#

aux_char_get_pcid_by_pcid() {
    printf "%s\n" "$1"
}

aux_char_get_char_by_char() {
    printf "%s\n" "$1"
}

aux_char_get_char_by_pcid() {
    grep -m 1 "^$1" "${TMWW_SERVERDB}" | cut -f 3
}

aux_char_get_pcid_by_char() {
    chname=$( sed_chars "$1" )
    egrep -m 1 "^${field}${field}${chname}${tabchar}" "${TMWW_SERVERDB}" | cut -f 1
}

aux_char_get_id_by_pcid() {
    grep -m 1 "^$1" "${TMWW_SERVERDB}" | cut -f 2 | cut -d ',' -f 1
}

aux_char_get_id_by_char() {
    chname=$( sed_chars "$1" )
    egrep -m 1 "^${field}${field}${chname}${tabchar}" "${TMWW_SERVERDB}" | cut -f 2 | cut -d ',' -f 1
}

# require variable "res" with db/accs lines to print
aux_char_db_print() {
    {
        [ -n "${res}" ] && {
            if [ "${output_format}" = "db" ]; then
                [ -n "${server_no_caption}" ] || \
                    printf "pcid\taccid\tcharname\tlevel\texp/gp\thp/mp\tstats\t?\t?\tpartyid\t?\t?\tlocation\tresp\t?\tinventory\t?\tskills\tvars\n"
                printf "%s\n" "${res}"
            else
                [ -n "${server_no_caption}" ] || \
                    printf "accid\tlogin\thash\tdate\tg\tcounter\t?\tmail\t?\t?\tlastip\t?\t?\n"
                printf "%s\n" "${res}"
            fi
        } | if [ -n "${server_cut_fields}" ]; then cut -f "${server_cut_fields}" ; else cat; fi
    } | if [ -z "${server_raw_fields}" ]; then column -ts "${tabchar}"  ; else cat; fi
}

aux_char_get_inventory_by_char() {
    local chname ids
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    chname=$( sed_chars "$1" )
    db_item_count=$( egrep -m 1 "^${field}${field}${chname}${tabchar}" "${TMWW_SERVERDB}" |
        cut -f 16 | tr ' ' '\n' | cut -f 2,3 -d ',')
    [ -z "${db_item_count}" ] && return
    ids=$( printf "%s" "${db_item_count}" | cut -f 1 -d ',' | tr '\n' ' ' )
    db_suppress_append="yes"
    func_item_show server_inventory by ids ${ids}
}

aux_char_get_inventory_by_pcid() {
    local ids
    db_item_count=$( grep -m 1 "^$1" "${TMWW_SERVERDB}" |
        cut -f 16 | tr ' ' '\n' | cut -f 2,3 -d ',')
    [ -z "${db_item_count}" ] && return
    ids=$( printf "%s" "${db_item_count}" | cut -f 1 -d ',' | tr '\n' ' ' )
    db_suppress_append="yes"
    func_item_show server_inventory by ids ${ids}
}

aux_char_get_db_by_char() {
    chname=$( sed_chars "$1" )
    res=$(egrep -m 1 "^${field}${field}${chname}${tabchar}" "${TMWW_SERVERDB}")
    aux_char_db_print
}

aux_char_get_db_by_pcid() {
    res=$(grep -m 1 "^$1" "${TMWW_SERVERDB}")
    aux_char_db_print
}

aux_char_get_accs_by_char() {
    id=$(aux_char_get_id_by_char "$1")
    [ -z "${id}" ] && return
    res=$(grep -m 1 "^${id}" "${TMWW_SERVERACCS}")
    aux_char_db_print
}

aux_char_get_accs_by_pcid() {
    id=$(aux_char_get_id_by_pcid "$1")
    [ -z "${id}" ] && return
    res=$(grep -m 1 "^${id}" "${TMWW_SERVERACCS}")
    aux_char_db_print
}

# args: pairs of field and field type
# example: gp db login acc mail acc #BankAccount reg
# arguments are prepared/compiled by aux_compile_wrapper
aux_char_get_fields_printer() {
    local rules pcontent f1rule f2rule cid nofield
    # printf "arg: %s\n" "$@"
    nofield=''
    if [ -n "$1" -a -n "$2" ]; then
        case "$1" in
            gm)
                [ -z "${server_no_caption}" ] &&
                    fields_caption="${fields_caption}"$(printf "%s\011" "$2" )
                if [ -n "${fields_single_target}" ]; then
                    pcontent=$( get_element 1 ${prepared_gm} )
                else
                    pcontent=$( printf "%s\n" "${prepared_db}" | cut -f 2 | cut -f 1 -d ',' |
                        while read line; do
                        cid=$(printf "%s\n" "${prepared_gm}" | sed -n "s/${line} //p")
                        printf "%s\n" "${cid:- }"
                    done )
                fi
                ;;
            db)
                if [ -n "${server_accounts_only}" -a "$2" != "accid" ]; then 
                    nofield=1
                else
                    rules=$( printf "%s\n" "${fieldsdb}" | grep -wm1 "$2" )
                    f1rule=$( get_element 1 ${rules})
                    f2rule=$( get_element 2 ${rules})
                    [ -z "${server_no_caption}" ] &&
                        fields_caption="${fields_caption}"$(printf "%s\011" "$2" )
                    pcontent=$( printf "%s" "${prepared_db}" | \
                        cut -f "${f1rule}" | cut -d ',' -f "${f2rule}" )
                fi
                ;;
            party)
                if [ -n "${server_accounts_only}" ]; then 
                    nofield=1
                else
                    [ -z "${server_no_caption}" ] &&
                        fields_caption="${fields_caption}"$(printf "%s\011" "$2" )
                    pcontent=$( printf "%s\n" "${prepared_db}" | cut -f 10 | cut -f 1 -d ',' |
                        while read line; do
                        cid=$(printf "%s\n" "${prepared_party}" | sed -n "s/^${line}${tabchar}//p")
                        printf "%s\n" "${cid:- }"
                    done )
                fi
                ;;
            accs)
                rules=$( printf "%s\n" "${fieldsaccs}" | grep -wm1 "$2" )
                f1rule=$( get_element 1 ${rules})
                [ -z "${server_no_caption}" ] &&
                    fields_caption="${fields_caption}"$(printf "%s\011" "$2" )
                if [ -n "${fields_single_target}" ]; then
                    pcontent=$( printf "%s" "${prepared_accs}" | cut -f "${f1rule}" )
                else
                    pcontent=$( printf "%s\n" "${prepared_db}" | cut -f 2 | cut -f 1 -d ',' |
                        while read line; do
                        cid=$(printf "%s\n" "${prepared_accs}" | grep -m1 "^${line}" | \
                            cut -f "${f1rule}")
                        printf "%s\n" "${cid:- }"
                    done )
                fi
                ;;
            reg)
                # f1rule keeps alias name
                f1rule=$( printf "%s\n" "${fieldsvars}" | grep -wm1 "^$2" )
                if [ -z "${f1rule}" ]; then f1rule="$2"
                else f1rule=$( get_element 2 ${f1rule}) ; fi
                # f2rule tells if we need caption (depends on field type - per account/per char)
                f2rule=''
                if [ -n "${fields_single_target}" ]; then
                    case "${f1rule}" in
                        [#]*)
                            pcontent=$( printf "%s\n" "${prepared_reg}" | \
                                grep -F "${f1rule}," | cut -f 2 | cut -d ',' -f 2 )
                            f2rule=1
                            ;;
                        *)
                            if [ -n "${server_accounts_only}" ]; then
                                nofield=1
                            else
                                pcontent=$( printf "%s\n" "${prepared_db}" | cut -f 19 | \
                                    ${AWK} ${AWKPARAMS} -v f="${f1rule}" -- '{for(i=1;i<=NF;i++) \
                                    if($i~" "f",|^"f","){sub(".*,","",$i);print $i;exit}}' )
                                f2rule=1
                            fi
                            ;;
                    esac
                else
                    case "${f1rule}" in
                        [#]*)
                            pcontent=$( printf "%s\n" "${prepared_db}" | cut -f 2 | cut -f 1 -d ',' |
                                while read line; do
                                cid=$(printf "%s\n" "${prepared_reg}" | \
                                    grep -Fm1 "${line}${tabchar}${f1rule}," | \
                                    cut -f 2 | cut -d ',' -f 2)
                                printf "%s\n" "${cid:- }"
                            done )
                            f2rule=1
                            ;;
                        *)
                            if [ -n "${server_accounts_only}" ]; then
                                nofield=1
                            else
                                pcontent=$( printf "%s\n" "${prepared_db}" | cut -f 19 | \
                                    ${AWK} ${AWKPARAMS} -v f="${f1rule}" -- '{for(i=1;i<=NF;i++) \
                                    if($i~" "f",|^"f","){sub(".*,","",$i);print $i;next};print " "}' )
                                f2rule=1
                            fi
                            ;;
                    esac
                fi
                [ -n "${server_no_caption}" -o -z "${f2rule}" ] ||
                    fields_caption="${fields_caption}"$(printf "%s\011" "$2" )
                ;;
            *)  error "Internal error: incorrect fields format"; return 1 ;;
        esac
        [ -z "${nofield}" ] && if [ -n "${fields_single_target}" ]; then
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
        shift 2
    else
        [ -n "$1" ] && { error "Internal error: incorrect fields format"; return 1; }
        {
            [ -z "${server_no_caption}" -a -n "${fields_caption}" ] && printf "%s\n" "${fields_caption}"
            printf "%s\n" "${fields_content}"
        } | if [ -z "${server_raw_fields}" ]; then column -ts "${tabchar}" ; else cat; fi
        return 0
    fi
    aux_char_get_fields_printer "$@"
}

aux_char_get_fields_by_pcid() {
    local id append need_accreg
    fields_single_target=1
    need_accreg=''
    # need_db is always needed for accid and possible reg-type fields
    prepared_db=$(grep -m 1 "^$1" "${TMWW_SERVERDB}")
    if [ -n "${need_accs}" ]; then
        id=$(aux_char_get_id_by_pcid "$1")
        prepared_accs=$(grep -m 1 "^${id}" "${TMWW_SERVERACCS}")
    fi
    if [ -n "${need_reg}" ]; then
        [ -z "${id}" ] && id=$(aux_char_get_id_by_pcid "$1")
        # check if compiled_reg has "#" signs - mean accreg.txt required
        case "${compiled_reg}" in *[#]*) need_accreg=1 ;; esac
        [ -n "${need_accreg}" ] && prepared_reg=$(egrep "^${id}${tabchar}${compiled_reg}," "${TMWW_SERVERREG}")
    fi
    if [ -n "${need_gm}" ]; then
        [ -z "${id}" ] && id=$(aux_char_get_id_by_pcid "$1")
        prepared_gm=$(grep -m 1 "^${id}" "${TMWW_SERVERGM}")
    fi
    if [ -n "${need_party}" ]; then
        prepared_party=$( printf "%s" "${prepared_db}" | \
            ${AWK} ${AWKPARAMS} -- 'BEGIN{FS=OFS="\t";i=0;m=0}
            NR==FNR{sub(",.*","",$10);ids[$10]=1;m++;next}
            {if($1 in ids) {print $1,$2; if (++i==m) exit}}' - "${TMWW_SERVERPARTY}")
    fi
    fields_content=''; fields_caption=''; append=''
    [ -z "${server_suppress_append}" ] && append="db accid db charname"
    aux_char_get_fields_printer ${compiled_fields} ${append} || return 1
}

aux_char_get_fields_by_char() {
    local chname id append ids
    fields_single_target=1
    # need_db is always needed since accids are taken from there
    chname=$( sed_chars "$1" )
    prepared_db=$(egrep -m 1 "^${field}${field}${chname}${tabchar}" "${TMWW_SERVERDB}")
    if [ -n "${need_accs}" ]; then
        id=$(aux_char_get_id_by_char "$1")
        prepared_accs=$(grep -m 1 "^${id}" "${TMWW_SERVERACCS}")
    fi
    if [ -n "${need_reg}" ]; then
        [ -z "${id}" ] && id=$(aux_char_get_id_by_char "$1")
        # check if compiled_reg has "#" signs - mean accreg.txt required
        case "${compiled_reg}" in *[#]*) need_accreg=1 ;; esac
        [ -n "${need_accreg}" ] && prepared_reg=$(egrep "^${id}${tabchar}${compiled_reg}," "${TMWW_SERVERREG}")
    fi
    if [ -n "${need_gm}" ]; then
        [ -z "${id}" ] && id=$(aux_char_get_id_by_char "$1")
        prepared_gm=$(grep -m 1 "^${id}" "${TMWW_SERVERGM}")
    fi
    if [ -n "${need_party}" ]; then
        prepared_party=$( printf "%s" "${prepared_db}" | \
            ${AWK} ${AWKPARAMS} -- 'BEGIN{FS=OFS="\t";i=0;m=0}
            NR==FNR{sub(",.*","",$10);ids[$10]=1;m++;next}
            {if($1 in ids) {print $1,$2; if (++i==m) exit}}' - "${TMWW_SERVERPARTY}")
    fi
    fields_content=''; fields_caption=''; append=''
    [ -z "${server_suppress_append}" ] && append="db accid db charname"
    aux_char_get_fields_printer ${compiled_fields} ${append} || return 1
}

aux_char_parse_skilldb() {
    sed '\|^ *//|d;s| *//.*$||;s/^ *\([0-9][0-9]*\).*, *\(.*$\)/\1 \2/' "${TMWW_SERVERSKILLDB}"
}

# takes input as 1 line of stdin
aux_char_get_skills() {
    # mawk param -W interactive switches RS back to newline
    cut -f 18 | $AWK -v sdb="$(aux_char_parse_skilldb)" -- '
            BEGIN { FS=","; RS=" "; split(sdb,slines,"\n")
                for (i in slines)
                    { split(slines[i],s," "); gsub("_"," ",s[2]); skills["s" s[1]] = s[2] } }
            "s" $1 in skills { print skills["s" $1], "(#" $1 "):" , $2 }
        '
}

aux_char_get_skills_by_pcid() {
    grep -m 1 "^$1" "${TMWW_SERVERDB}" | aux_char_get_skills
}

aux_char_get_skills_by_char() {
    local chname
    chname=$( sed_chars "$1" )
    egrep -m 1 "^${field}${field}${chname}${tabchar}" "${TMWW_SERVERDB}" | aux_char_get_skills
}

aux_char_get_vars_by_pcid() {
    local id
    prepared_db=$(grep -m 1 "^$1" "${TMWW_SERVERDB}")
    id=$( printf "%s" "${prepared_db}" | cut -f 2 | cut -d ',' -f 1 )

    # per account vars
    grep "^${id}" "${TMWW_SERVERREG}"
    # per char vars
    printf "%s" "${prepared_db}" | cut -f 19 | tr ' ' '\n'
}

aux_char_get_vars_by_char() {
    local chname id
    chname=$( sed_chars "$1" )
    prepared_db=$(egrep -m 1 "^${field}${field}${chname}${tabchar}" "${TMWW_SERVERDB}")
    id=$( printf "%s" "${prepared_db}" | cut -f 2 | cut -d ',' -f 1 )

    # per account vars
    grep "^${id}" "${TMWW_SERVERREG}"
    # per char vars
    printf "%s" "${prepared_db}" | cut -f 19 | tr ' ' '\n'
}

func_char_get() {
    local output_format criterion
    [ -z "$2" -a -n "$1" ] && {
        aux_char_get_id_by_char "$1" || return 1
        return
    }
    output_format="id"
    if [ "$1" != "by" ]; then
        case "$1" in
            inventory)
                requireplugin db.lib.sh || return 1
                output_format="inventory"
                shift
                ;;
            id)         output_format="id"; shift ;;
            pcid)       output_format="pcid"; shift ;;
            char)       output_format="char"; shift ;;
            accs)       output_format="accs"; shift ;;
            db)         output_format="db"; shift ;;
            vars)       output_format="vars"; shift ;;
            skills)     output_format="skills"; shift ;;
            # everything else counted as "field"
            *)
                output_format="fields"
                aux_compile_wrapper "$@"
                shift $?
                [ "${err_flag}" -eq 0 2>&- ] || return 1
                ;;
        esac
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    case "${criterion}" in
        char)   : ;;
        pcid)   check_pcid "$1" || return 1 ;;
        *)      error_incorrect; return 1; ;;
    esac
    eval aux_char_get_${output_format}_by_${criterion} \"\$@\"
    return $?
}

#
# char show
#
#

# chars are not sorted within account... have to search whole file
# args:
# 1 -- id expression, e.g. "2123123" or "2123123|2123124"
aux_char_show_simple() {
    ${AWK} ${AWKPARAMS} -v i="$1" -- '
        BEGIN { FS="\t"; c=0; split(i,ids,"|"); for (i in ids) n++ ; m=n*9 }
        { for (i in ids) if ($2 ~ ids[i] ",") { print; if (++c==m) exit } }
        ' "${TMWW_SERVERDB}"
}

aux_char_show_ids_by_id() {
    aux_char_show_simple "$1" |
        ${AWK} ${AWKPARAMS} -F '\t' -- '{split($2,id,","); print id[1], $3}'
}

aux_char_show_pcids_by_id() {
    aux_char_show_simple "$1" |
        ${AWK} ${AWKPARAMS} -F '\t' -- '{split($2,id,","); print $1, id[1], $3}'
}

aux_char_show_chars_by_id() {
    aux_char_show_simple "$1" | cut -f 3
}

aux_char_show_ids_by_pcid() {
    id=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${id}" ] && return 1
    aux_char_show_simple "${id}" |
        ${AWK} ${AWKPARAMS} -F '\t' -- '{split($2,id,","); print id[1], $3}'
}

aux_char_show_pcids_by_pcid() {
    id=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${id}" ] && return 1
    aux_char_show_simple "${id}" |
        ${AWK} ${AWKPARAMS} -F '\t' -- '{split($2,id,","); print $1, id[1], $3}'
}

aux_char_show_chars_by_pcid() {
    id=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${id}" ] && return 1
    aux_char_show_simple "${id}" | cut -f 3
}

aux_char_show_ids_by_char() {
    id=$( aux_char_get_id_by_char "$1" )
    [ -z "${id}" ] && return 1
    aux_char_show_simple "${id}" |
        ${AWK} ${AWKPARAMS} -F '\t' -- '{split($2,id,","); print id[1], $3}'
}

aux_char_show_pcids_by_char() {
    id=$( aux_char_get_id_by_char "$1" )
    [ -z "${id}" ] && return 1
    aux_char_show_simple "${id}" |
        ${AWK} ${AWKPARAMS} -F '\t' -- '{split($2,id,","); print $1, id[1], $3}'
}

aux_char_show_chars_by_char() {
    id=$( aux_char_get_id_by_char "$1" )
    [ -z "${id}" ] && return 1
    aux_char_show_simple "${id}" | cut -f 3
}

# only per-account vars
aux_char_show_vars_by_id() {
    grep "^$1" "${TMWW_SERVERREG}"
}

# only per-account vars
aux_char_show_vars_by_pcid() {
    local id
    id=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${id}" ] && return 1

    # per account vars
    grep "^${id}" "${TMWW_SERVERREG}"
}

# only per-account vars
aux_char_show_vars_by_char() {
    local id
    id=$( aux_char_get_id_by_char "$1" )
    [ -z "${id}" ] && return 1

    # per account vars
    grep "^${id}" "${TMWW_SERVERREG}"
}

aux_char_show_db_by_id() {
    res=$( aux_char_show_simple "$1" )
    aux_char_db_print
}

aux_char_show_db_by_pcid() {
    local id
    id=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${id}" ] && return 1
    res=$( aux_char_show_simple "${id}" )
    aux_char_db_print
}

aux_char_show_db_by_char() {
    local id
    id=$( aux_char_get_id_by_char "$1" )
    [ -z "${id}" ] && return 1
    res=$( aux_char_show_simple "${id}" )
    aux_char_db_print
}

aux_char_show_accs_by_id() {
    res=$(grep -m 1 "^${id}" "${TMWW_SERVERACCS}")
    aux_char_db_print
}

aux_char_show_accs_by_pcid() {
    local id
    id=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${id}" ] && return 1
    res=$(grep -m 1 "^${id}" "${TMWW_SERVERACCS}")
    aux_char_db_print
}

aux_char_show_accs_by_char() {
    local id
    id=$( aux_char_get_id_by_char "$1" )
    [ -z "${id}" ] && return 1
    res=$(grep -m 1 "^${id}" "${TMWW_SERVERACCS}")
    aux_char_db_print
}

# common part of aux_char_show_fields_by_{id|pcid|char}
# require $id
aux_char_show_fields() {
    local append need_accreg
    # need_db is always needed for accid and possible reg-type fields
    prepared_db=$( aux_char_show_simple "${id}" | \
        if [ -n "${server_accounts_only}" ]; then head -n 1
        else cat; fi )
    [ -z "${prepared_db}" ] && return 1
    fields_single_target=''
    need_accreg=''
    if [ -n "${need_accs}" ]; then
        prepared_accs=$(grep -m 1 "^${id}" "${TMWW_SERVERACCS}")
    fi
    if [ -n "${need_reg}" ]; then
        # check if compiled_reg has "#" signs - mean accreg.txt required
        case "${compiled_reg}" in *[#]*) need_accreg=1 ;; esac
        [ -n "${need_accreg}" ] && prepared_reg=$(egrep "^${id}${tabchar}${compiled_reg}," "${TMWW_SERVERREG}")
    fi
    if [ -n "${need_gm}" ]; then
        prepared_gm=$(grep -m 1 "^${id}" "${TMWW_SERVERGM}")
    fi
    if [ -n "${need_party}" ]; then
        prepared_party=$( printf "%s" "${prepared_db}" | \
            ${AWK} ${AWKPARAMS} -- 'BEGIN{FS=OFS="\t";i=0;m=0}
            NR==FNR{sub(",.*","",$10);ids[$10]=1;m++;next}
            {if($1 in ids) {print $1,$2; if (++i==m) exit}}' - "${TMWW_SERVERPARTY}")
    fi
    fields_content=''; fields_caption=''; append=''
    [ -z "${server_suppress_append}" ] && append="db accid db charname"
    aux_char_get_fields_printer ${compiled_fields} ${append} || return 1

}

aux_char_show_fields_by_id() {
    local id
    id="$1"
    aux_char_show_fields || return 1
}

aux_char_show_fields_by_pcid() {
    local id
    id=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${id}" ] && return 1
    aux_char_show_fields || return 1
}

aux_char_show_fields_by_char() {
    local id
    id=$( aux_char_get_id_by_char "$1" )
    [ -z "${id}" ] && return 1
    aux_char_show_fields || return 1
}

aux_char_show_storage_by_id() {
    local ids
    db_item_count=$( grep -m 1 "^$1," "${TMWW_SERVERSTORAGE}" |
        cut -f 2 | tr ' ' '\n' | cut -f 2,3 -d ',')
    [ -z "${db_item_count}" ] && return
    ids=$( printf "%s" "${db_item_count}" | cut -f 1 -d ',' | tr '\n' ' ' )
    db_suppress_append="yes"
    func_item_show server_storage by ids ${ids}
}

aux_char_show_storage_by_pcid() {
    local chid ids
    chid=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${chid}" ] && return
    aux_char_show_storage_by_id "${chid}"
}

aux_char_show_storage_by_char() {
    local chid ids
    chid=$( aux_char_get_id_by_char "$1" )
    [ -z "${chid}" ] && return
    aux_char_show_storage_by_id "${chid}"
}

func_char_show() {
    local output_format criterion
    [ -z "$2" -a -n "$1" ] && {
        aux_char_show_ids_by_char "$1" || return 1
        return 0
    }
    output_format="ids"
    if [ "$1" != "by" ]; then
        case "$1" in
            storage)
                requireplugin db.lib.sh || return 1
                output_format="storage"
                shift
                ;;
            ids)        output_format="ids"; shift ;;
            pcids)      output_format="pcids"; shift ;;
            chars)      output_format="chars"; shift ;;
            accs)       output_format="accs"; shift ;;
            db)         output_format="db"; shift ;;
            vars)       output_format="vars"; shift ;;
            # everything else counted as "field"
            *)
                output_format="fields"
                aux_compile_wrapper "$@"
                shift $?
                [ "${err_flag}" -eq 0 2>&- ] || return 1
                ;;
        esac
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    case "${criterion}" in
        char)   : ;;
        pcid)   check_pcid "$1" || return 1 ;;
        id)     check_id "$1" || return 1 ;;
        *)      error_incorrect; return 1; ;;
    esac
    eval aux_char_show_${output_format}_by_${criterion} \"\$@\"
    return $?
}

#
# char summary
#
#

aux_char_summary_exp_by_id() {
    [ -f "${TMWW_UTILPATH}/exp_per_level" ] || return
    aux_char_show_simple "$1" | cut -f 4,5 |
        ${AWK} -F '\t' -- '
            BEGIN { s=0 }
            NR==FNR { lexp[NR+1]=lexp[NR]+$1; next }
            { split($1,clvl,","); split($2,cexp,","); s+=cexp[1] + lexp[clvl[2]]}
            END { print s }
        ' "${TMWW_UTILPATH}/exp_per_level" -
}

aux_char_summary_exp_by_pcid() {
    local chid
    chid=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${chid}" ] && return
    aux_char_summary_exp_by_id "${chid}"
}

aux_char_summary_exp_by_char() {
    local chid
    chid=$( aux_char_get_id_by_char "$1" )
    [ -z "${chid}" ] && return
    aux_char_summary_exp_by_id "${chid}"
}

aux_char_summary_bp_by_id() {
    aux_char_show_simple "$1" | cut -f 19 | tr ' ' '\n' |
        grep BOSS_POINTS | cut -f 2 -d ',' | awk_sum
}

aux_char_summary_bp_by_pcid() {
    local chid
    chid=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${chid}" ] && return
    aux_char_summary_bp_by_id "${chid}"
}

aux_char_summary_bp_by_char() {
    local chid
    chid=$( aux_char_get_id_by_char "$1" )
    [ -z "${chid}" ] && return
    aux_char_summary_bp_by_id "${chid}"
}

aux_char_summary_gp_by_id() {
    {
        sed ${ESED} -n "/^$1${tabchar}#BankAccount,/{s/.*,//p;q}" "${TMWW_SERVERREG}"
        aux_char_show_simple "$1" | cut -f 5 | cut -f 3 -d ','
    } | awk_sum
}

aux_char_summary_gp_by_pcid() {
    local chid
    chid=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${chid}" ] && return
    aux_char_summary_gp_by_id "${chid}"
}

aux_char_summary_gp_by_char() {
    local chid
    chid=$( aux_char_get_id_by_char "$1" )
    [ -z "${chid}" ] && return
    aux_char_summary_gp_by_id "${chid}"
}

aux_char_summary_items_by_id() {
    local ids
    db_item_count=$(
        {
            grep -m 1 "^$1," "${TMWW_SERVERSTORAGE}" |
                cut -f 2 | tr ' ' '\n' | cut -f 2,3 -d ','
            aux_char_show_simple "$1" |
                cut -f 16 | tr ' ' '\n' | cut -f 2,3 -d ','
        } | ${AWK} ${AWKPARAMS} -F ',' -- '
        { s[$1]=s[$1]+$2} END {for (i in s) print i "," s[i]} '
    )
    [ -z "${db_item_count}" ] && return
    ids=$( printf "%s" "${db_item_count}" | cut -f 1 -d ',' | tr '\n' ' ' )
    db_suppress_append="yes"; db_raw_fields="${server_raw_fields}"
    func_item_show server_storage by ids ${ids}
}

aux_char_summary_items_by_pcid() {
    local chid
    chid=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${chid}" ] && return
    aux_char_summary_items_by_id "${chid}"
}

aux_char_summary_items_by_char() {
    local chid
    chid=$( aux_char_get_id_by_char "$1" )
    [ -z "${chid}" ] && return
    aux_char_summary_items_by_id "${chid}"
}

func_char_summary() {
    local output_format criterion
    output_format="gp"
    if [ "$1" != "by" ]; then
        case "$1" in
            items) requireplugin db.lib.sh || return 1 ;;
            gp|bp|exp) : ;;
            *) error_incorrect; return 1 ;;
        esac
        output_format="$1"
        shift
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    case "${criterion}" in
        char)   : ;;
        pcid)   check_pcid "$1" || return 1 ;;
        id)     check_id "$1" || return 1 ;;
        *)      error_incorrect; return 1 ;;
    esac
    eval aux_char_summary_${output_format}_by_${criterion} \"\$@\"
    return $?
}

#
# party
#
#

func_party_fuzzy() {
    local patt
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    if ! printf "%s" "$1" | egrep -q '^[-a-zA-Z0-9_/\., ]+$'; then
        error_incorrect; return 1; fi
    patt=$( aux_fuzzy_pattern $1 )
    cut -f 2 "${TMWW_SERVERPARTY}" | egrep -i -- "${patt}"
}

func_party_agrep() {
    local patt
    faultlevel=1
    check_agrep || return 1
    OPTIND=1
    while ${GETOPTS} e: opt ; do
        case $opt in
            e)  faultlevel="${OPTARG}" ;;
            *)  error_incorrect; return 1 ;;
        esac
    done
    shift $(expr $OPTIND - 1)
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    chname=$( sed_chars "$1" )
    cut -f 2 "${TMWW_SERVERPARTY}" | agrep -i ${faultlevel:+-$faultlevel} "${chname}"
}

func_party_grep() {
    local patt
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    patt=$( sed_chars "$1" )
    cut -f 2 "${TMWW_SERVERPARTY}" | egrep -i -- "${patt}"
}

# massive lookup - grep + lookup all grep matches
func_party_dig() {
    local line
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    ${AWK} ${AWKPARAMS} -v patt="$1" -F '\t' -- ' BEGIN{patt=tolower(patt)}
        { t=tolower($2); if (t~patt)
            for (i=4;i<NF;i+=2) { split($i,id,","); printf "%s %-24s -- %s\n",id[1],$(i+1),$2 } }
    ' "${TMWW_SERVERPARTY}"
}

aux_party_get_by_pcid() {
    local result
    result=$(egrep -m 1 "^$1" "${TMWW_SERVERDB}" | cut -f 10 | cut -f 1 -d ',' )
    [ -z "${result}" -o "${result}" = "0" ] && return
    grep -m 1 "^${result}" "${TMWW_SERVERPARTY}" | cut -f 2
}

aux_party_get_by_char() {
    local result
    chname=$( sed_chars "$1" )
    result=$(egrep -m 1 "^${field}${field}${chname}${tabchar}" "${TMWW_SERVERDB}" | cut -f 10 | cut -f 1 -d ',' )
    [ -z "${result}" -o "${result}" = "0" ] && return
    grep -m 1 "^${result}" "${TMWW_SERVERPARTY}" | cut -f 2
}

aux_party_get_by_partyid() {
    grep -m 1 "^$1" "${TMWW_SERVERPARTY}" | cut -f 2
}

func_party_get() {
    local criterion
    [ -z "$2" -a -n "$1" ] && {
        aux_party_get_by_char "$1" || return 1
        return
    }
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    case "${criterion}" in
        char)       : ;;
        pcid)       check_pcid "$1" || return 1 ;;
        partyid)    check_partyid "$1" || return 1 ;;
        *)          error_incorrect; return 1; ;;
    esac
    eval aux_party_get_by_${criterion} \"\$@\"
    return $?
}

aux_party_show_pcids() {
    local chname
    chname=$( sed_chars "$1" )
    egrep -m 1 "^${field}${field}${chname}${tabchar}" "${TMWW_SERVERDB}" |
        ${AWK} -F '\t' -- '{split($2,id,","); print $1,id[1],$3}'
}

aux_party_show_pcids_by_partyid() {
    local line
    aux_party_show_chars_by_partyid "$1" | while read -r line; do
        aux_party_show_pcids "${line}"
    done
}

aux_party_show_pcids_by_pcid() {
    local line
    aux_party_show_chars_by_pcid "$1" | while read -r line; do
        aux_party_show_pcids "${line}"
    done
}

aux_party_show_pcids_by_char() {
    local line
    aux_party_show_chars_by_char "$1" | while read -r line; do
        aux_party_show_pcids "${line}"
    done
}

aux_party_show_pcids_by_party() {
    local line
    aux_party_show_chars_by_party "$1" | while read -r line; do
        aux_party_show_pcids "${line}"
    done
}

aux_party_show_chars_by_partyid() {
    ${AWK} ${AWKPARAMS} -v patt="$1" -F '\t' -- '
        $1==patt { for (i=4;i<NF;i+=2) print $(i+1) ; exit }
    ' "${TMWW_SERVERPARTY}"
}

aux_party_show_ids_by_partyid() {
    ${AWK} ${AWKPARAMS} -v patt="$1" -F '\t' -- '
        $1==patt { for (i=4;i<NF;i+=2) { split($i,id,","); print id[1],$(i+1) } ; exit }
    ' "${TMWW_SERVERPARTY}"
}

aux_party_show_chars_by_party() {
    ${AWK} ${AWKPARAMS} -v patt="$1" -F '\t' -- '
        $2==patt { for (i=4;i<NF;i+=2) print $(i+1) ; exit }
    ' "${TMWW_SERVERPARTY}"
}

aux_party_show_ids_by_party() {
    ${AWK} ${AWKPARAMS} -v patt="$1" -F '\t' -- '
        $2==patt { for (i=4;i<NF;i+=2) { split($i,id,","); print id[1],$(i+1) } ; exit }
    ' "${TMWW_SERVERPARTY}"
}

aux_party_show_chars_by_pcid() {
    local party
    party=$(aux_party_get_by_pcid "$1")
    [ -z "${party}" ] && return
    ${AWK} ${AWKPARAMS} -v patt="${party}" -F '\t' -- '
        $2==patt { for (i=4;i<NF;i+=2) print $(i+1) ; exit }
    ' "${TMWW_SERVERPARTY}"
}

aux_party_show_ids_by_pcid() {
    local party
    party=$(aux_party_get_by_pcid "$1")
    [ -z "${party}" ] && return
    ${AWK} ${AWKPARAMS} -v patt="${party}" -F '\t' -- '
        $2==patt { for (i=4;i<NF;i+=2) { split($i,id,","); print id[1],$(i+1) } ; exit }
    ' "${TMWW_SERVERPARTY}"
}

aux_party_show_chars_by_char() {
    local party
    party=$(aux_party_get_by_char "$1")
    [ -z "${party}" ] && return
    ${AWK} ${AWKPARAMS} -v patt="${party}" -F '\t' -- '
        $2==patt { for (i=4;i<NF;i+=2) print $(i+1) ; exit }
    ' "${TMWW_SERVERPARTY}"
}

aux_party_show_ids_by_char() {
    local party
    party=$(aux_party_get_by_char "$1")
    [ -z "${party}" ] && return
    ${AWK} ${AWKPARAMS} -v patt="${party}" -F '\t' -- '
        $2==patt { for (i=4;i<NF;i+=2) { split($i,id,","); print id[1],$(i+1) } ; exit }
    ' "${TMWW_SERVERPARTY}"
}

aux_party_show_players() {
    local id player
    while read -r line; do
        id=${line%${line#???????}}
        player="$( aux_player_get_by_id ${id} )"
        # alternate output format
        # printf "%s [ %-24s ] %s\n" "${id}" "$( aux_player_get_by_id ${id} )" "${line#????????}"
        if [ -z "${player}" ]; then
            printf "%s\n" "${line}"
        else
            printf "%-32s -- %s\n" "${line}" "${player}"
        fi
    done
}

aux_party_show_players_by_party() {
    aux_party_show_ids_by_party "$1" | aux_party_show_players
}

aux_party_show_players_by_char() {
    aux_party_show_ids_by_char "$1" | aux_party_show_players
}

aux_party_show_players_by_pcid() {
    aux_party_show_ids_by_pcid "$1" | aux_party_show_players
}

aux_party_show_players_by_partyid() {
    aux_party_show_ids_by_pcid "$1" | aux_party_show_players
}

func_party_show() {
    local output_format critetion
    [ -z "$2" -a ! -z "$1" ] && {
        check_player "$1" || return 1
        aux_party_show_ids_by_char "$1"
        return
    }
    output_format="chars"
    if [ "$1" != "by" ]; then
        case "$1" in
            pcids|chars|ids|players) : ;;
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
        partyid)    check_partyid "$1" || return 1 ;;
        party)      : ;;
        char)       : ;;
        pcid)       check_pcid "$1" || return 1 ;;
        *)          error_incorrect; return 1 ;;
    esac
    eval aux_party_show_${output_format}_by_${criterion} \"\$1\"
    return $?
}

#
# player fixed functions
#
#

aux_player_get_by_pcid() {
    local result
    result=$( aux_char_get_id_by_pcid "$1" )
    [ -z "${result}" ] && return 1
    aux_player_get_by_id "${result}"
}

func_player_get() {
    local criterion
    [ -z "$2" -a -n "$1" ] && {
        aux_player_get_by_char "$1" || return 1
        return
    }
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    case "${criterion}" in
        char)   : ;;
        pcid)   check_pcid "$1" || return 1 ;;
        id)     check_id "$1" || return 1 ;;
        *)      error_incorrect; return 1; ;;
    esac
    eval aux_player_get_by_${criterion} \"\$@\"
    return $?
}

aux_player_show_pcids_by_pcid() {
    local result
    result=$( aux_player_get_by_pcid "$1" )
    [ -z "${result}" ] && return 1
    aux_player_show_pcids_by_player "$1"
}

aux_player_show_pcids_by_char() {
    local result
    result=$( aux_player_get_by_char "$1" )
    [ -z "${result}" ] && return 1
    aux_player_show_pcids_by_player "$1"
}

aux_player_show_pcids_by_id() {
    local result
    result=$( aux_player_get_by_id "$1" )
    [ -z "${result}" ] && return 1
    aux_player_show_pcids_by_player "$1"
}

aux_player_show_pcids_by_player() {
    # unresolved alts are skipped and should be resolved in order to be displayed
    func_player_ids "$1" | while read line; do
        aux_char_show_pcids_by_id "${line}"
    done
}

aux_player_show_pcids_by_pcid() {
    local result
    result=$( aux_player_get_by_pcid "$1" )
    [ -z "${result}" ] && return 1
    aux_player_show_pcids_by_player "${result}"
}

aux_player_show_chars_by_pcid() {
    local result
    result=$( aux_player_get_by_pcid "$1" )
    [ -z "${result}" ] && return 1
    aux_player_show_chars_by_player "${result}"
}

aux_player_show_ids_by_pcid() {
    local result
    result=$( aux_player_get_by_pcid "$1" )
    [ -z "${result}" ] && return 1
    aux_player_show_ids_by_player "${result}"
}

aux_player_show_parties_by_pcid() {
    local result
    result=$( aux_player_get_by_id "$1" )
    [ -z "${result}" ] && return 1
    aux_player_show_parties_by_player "${result}"
}

func_player_show() {
    local output_format critetion
    [ -z "$2" -a ! -z "$1" ] && {
        check_player "$1" || return 1
        aux_player_show_ids_by_player "$1"
        return
    }
    output_format="chars"
    if [ "$1" != "by" ]; then
        case "$1" in
            pcids|chars|ids|parties) : ;;
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
        player)     check_player "$1" || return 1 ;;
        pcid)       check_pcid "$1" || return 1 ;;
        id)         check_id "$1" || return 1 ;;
        char)       : ;;
        *)          error_incorrect; return 1 ;;
    esac
    eval aux_player_show_${output_format}_by_${criterion} \"\$1\"
    return $?
}

#
# player summary
#
#

aux_player_summary_exp() {
    local i ids
    ids=$(aux_player_ids "$1" | tr '\n' '|' )
    [ "${ids}" = "|" ] && return
    ids="(${ids%|})"
    aux_char_show_simple "${ids}" | cut -f 4,5 |
        ${AWK} -F '\t' -- '
            BEGIN { s=0 }
            NR==FNR { lexp[NR+1]=lexp[NR]+$1; next }
            { split($1,clvl,","); split($2,cexp,","); s+=cexp[1] + lexp[clvl[2]]}
            END { print s }
        ' "${TMWW_UTILPATH}/exp_per_level" -
}

aux_player_summary_exp_by_player() {
    aux_player_summary_exp "$1"
}

aux_player_summary_exp_by_id() {
    local plname
    [ -f "${TMWW_UTILPATH}/exp_per_level" ] || return
    plname=$(aux_player_get_by_id "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_exp_by_id "$1" || return 1
    else
        aux_player_summary_exp "$1"
    fi
}

aux_player_summary_exp_by_pcid() {
    local plname
    [ -f "${TMWW_UTILPATH}/exp_per_level" ] || return
    plname=$(aux_player_get_by_pcid "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_exp_by_pcid "$1" || return 1
    else
        aux_player_summary_exp "$1"
    fi
}

aux_player_summary_exp_by_char() {
    local plname
    [ -f "${TMWW_UTILPATH}/exp_per_level" ] || return
    plname=$(aux_player_get_by_char "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_exp_by_char "$1" || return 1
    else
        aux_player_summary_exp "$1"
    fi
}

aux_player_summary_bp() {
    local i ids
    ids=$(aux_player_ids "$1" | tr '\n' '|' )
    [ "${ids}" = "|" ] && return
    ids="(${ids%|})"
    aux_char_show_simple "${ids}" | cut -f 19 | tr ' ' '\n' |
        grep BOSS_POINTS | cut -f 2 -d ',' | awk_sum
}

aux_player_summary_bp_by_player() {
    aux_player_summary_bp "$1"
}

aux_player_summary_bp_by_id() {
    local plname
    plname=$(aux_player_get_by_id "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_bp_by_id "$1" || return 1
    else
        aux_player_summary_bp "$1"
    fi
}

aux_player_summary_bp_by_pcid() {
    local plname
    plname=$(aux_player_get_by_pcid "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_bp_by_pcid "$1" || return 1
    else
        aux_player_summary_bp "$1"
    fi
}

aux_player_summary_bp_by_char() {
    local plname
    plname=$(aux_player_get_by_char "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_bp_by_char "$1" || return 1
    else
        aux_player_summary_bp "$1"
    fi
}

aux_player_summary_gp() {
    local i ids
    ids=$(aux_player_ids "$1")
    [ -z "${ids}" ] && return
    ids=$(aux_player_ids "$1" | tr '\n' '|' )
    [ "${ids}" = "|" ] && return
    ids="(${ids%|})"
    {
        sed ${ESED} -n "/^${ids}${tabchar}#BankAccount,/{s/.*,//p;q}" "${TMWW_SERVERREG}"
        aux_char_show_simple "$i" | cut -f 5 | cut -f 3 -d ','
    } | awk_sum
}

aux_player_summary_gp_by_player() {
    aux_player_summary_gp "$1"
}

aux_player_summary_gp_by_id() {
    local plname
    plname=$(aux_player_get_by_id "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_gp_by_id "$1" || return 1
    else
        aux_player_summary_gp "$1"
    fi
}

aux_player_summary_gp_by_pcid() {
    local plname
    plname=$(aux_player_get_by_pcid "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_gp_by_pcid "$1" || return 1
    else
        aux_player_summary_gp "$1"
    fi
}

aux_player_summary_gp_by_char() {
    local plname
    plname=$(aux_player_get_by_char "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_gp_by_char "$1" || return 1
    else
        aux_player_summary_gp "$1"
    fi
}

aux_player_summary_items() {
    local ids itemids
    ids=$(aux_player_ids "$1" | tr '\n' '|' )
    [ "${ids}" = "|" ] && return
    ids="(${ids%|})"
    db_item_count=$(
        {
            grep -m 1 "^${ids}," "${TMWW_SERVERSTORAGE}" |
                cut -f 2 | tr ' ' '\n' | cut -f 2,3 -d ','
            aux_char_show_simple "${ids}" |
                cut -f 16 | tr ' ' '\n' | cut -f 2,3 -d ','
        } | ${AWK} ${AWKPARAMS} -F ',' -- '
        { s[$1]=s[$1]+$2} END {for (i in s) print i "," s[i]}'
    )
    [ -z "${db_item_count}" ] && return
    itemids=$( printf "%s" "${db_item_count}" | cut -f 1 -d ',' | tr '\n' ' ' )
    db_suppress_append="yes"; db_raw_fields="${server_raw_fields}"
    func_item_show server_storage by ids ${itemids}
}

aux_player_summary_items_by_player() {
    aux_player_summary_items "$1"
}

aux_player_summary_items_by_id() {
    local plname
    plname=$(aux_player_get_by_id "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_items_by_id "$1" || return 1
    else
        aux_player_summary_items "$1"
    fi
}

aux_player_summary_items_by_pcid() {
    local plname
    plname=$(aux_player_get_by_pcid "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_items_by_pcid "$1" || return 1
    else
        aux_player_summary_items "$1"
    fi
}

aux_player_summary_items_by_char() {
    local plname
    plname=$(aux_player_get_by_char "$1")
    if [ -z "${plname}" ]; then
        aux_char_summary_items_by_char "$1" || return 1
    else
        aux_player_summary_items "$1"
    fi
}

func_player_summary() {
    local output_format criterion
    output_format="ids"
    if [ "$1" != "by" ]; then
        case "$1" in
            items) requireplugin db.lib.sh || return 1 ;;
            gp|bp|exp) : ;;
            *) error_incorrect; return 1 ;;
        esac
        output_format="$1"
        shift
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    case "${criterion}" in
        char)   : ;;
        pcid)   check_pcid "$1" || return 1 ;;
        id)     check_id "$1" || return 1 ;;
        player) check_player "$1" || return 1 ;;
        *)      error_incorrect; return 1; ;;
    esac
    eval aux_player_summary_${output_format}_by_${criterion} \"\$@\"
    return $?
}

#
# select
#
#

# args: csv item slot descriptors from inventory/storage
# require $patt
aux_select_matched_items() {
    local name id i
    for i in "$@"; do
        id=$( get_comma 2 "$i" )
        # skip item if not in match list
        printf "%s" "${id}" | egrep -q "^${patt}$" || continue
        if [ -n "${select_add_name}" ]; then
            name=$( aux_item_get_name_by_id "${id}" )
            if [ -n "${select_add_id}" ]; then
                printf "%s (%s)\n" "${name}" "${id}"
            else
                printf "%s\n" "${name}"
            fi
        else
            printf "%s\n" "${id}"
        fi
    done
}

# require "$patt"
aux_select_inventory() {
    local line match chid chname chinfo
    cat "${TMWW_SERVERDB}" | while read line; do
        printf "%s\n" "${line}" | cut -f 16 | tr ' ' '\n' |
            egrep -q "^${csv}${patt}," && printf "%s\n" "${line}"
    done | while read match; do
        chname=$( printf "%s" "${match}" | cut -f 3)
        chid=$( printf "%s" "${match}" | cut -f 2 | cut -f 1 -d ',' )
        printf "inventory of \"%s\"; " "${chname}"

        if [ -z "${select_no_resolve}" ]; then
            plresult=$( aux_player_get_by_char "${chname}" )
            if [ -n "${plresult}" ]; then
                accounts=$( func_player_ids "${plresult}" | \
                    ${AWK} ${AWKPARAMS} 'BEGIN{s=0}{s+=1}END{print s}')
                printf "playerdb alias: %s; %s known accounts; " "${plresult}" "${accounts}"
            fi
        fi
        printf "%s: " "${chid}"
        aux_char_show_chars_by_id "${chid}" | make_csv
        if [ -n "${select_single_line}" ]; then printf "; "
        else printf "\n"; fi

        if [ -z "${select_add_name}" -a -z "${select_add_id}" ]; then continue; fi
        
        items=$(aux_select_matched_items $(printf "${match}" | cut -f 16) | make_csv)
        printf "match: %s\n" "${items}"
    done
}

aux_select_storage() {
    local line match chid plresult accounts
    cat "${TMWW_SERVERSTORAGE}" | while read line; do
        printf "%s\n" "${line}" | cut -f 2 | tr ' ' '\n' |
            egrep -q "^${csv}${patt}," && printf "%s\n" "${line}"
    done | while read match; do
        chid=$( printf "%s" "${match}" | cut -f 1 | cut -f 1 -d ',' )
        printf "storage of \"%s\"; " "${chid}"
        
        if [ -z "${select_no_resolve}" ]; then
            plresult=$( aux_player_get_by_id "${chid}" )
            if [ -n "${plresult}" ]; then
                accounts=$( func_player_ids "${plresult}" | \
                    ${AWK} ${AWKPARAMS} 'BEGIN{s=0}{s+=1}END{print s}')
                printf "playerdb alias: %s; %s known accounts; " "${plresult}" "${accounts}"
            fi
        fi
        printf "%s: " "${chid}"
        aux_char_show_chars_by_id "${chid}" | make_csv
        if [ -n "${select_single_line}" ]; then printf "; "
        else printf "\n"; fi

        [ -z "${select_add_name}" -a -z "${select_add_id}" ] && continue

        items=$(aux_select_matched_items $(printf "${match}" | cut -f 2))
        printf "match: %s\n" "${items}"
    done
}

aux_select_by_names() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!a-zA-Z]*" "Disallowed characters in NAME $i" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    # converting pattern to item ids
    patt=$( egrep "^${csv}${patt}," ${itemfiles} | aux_db_cut_fields | cut -f 2 )
    [ -z "${patt}" ] && return
    patt=$(printf "%s" "${patt}" | tr '\n' '|' )
    patt="(${patt%|})"
    aux_select_inventory
    aux_select_storage
}

aux_select_by_ids() {
    local patt
    [ -z "$1" ] && { error_missing; return 1; }
    patt=''
    for i in "$@" ; do
        check_string_chars "$i" "*[!0-9]*" "Disallowed characters in ID" || return 1
        patt="${patt:+${patt}|}$i"
    done
    patt="(${patt})"
    aux_select_inventory
    aux_select_storage
}

aux_select_by_re() {
    local patt
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    patt=$( egrep -i "^${csv}.*$1.*," ${itemfiles} |
        aux_db_cut_fields | cut -f 2 )
    [ -z "${patt}" ] && return
    patt=$(printf "%s" "${patt}" | tr '\n' '|' )
    patt="(${patt%|})"
    aux_select_inventory
    aux_select_storage
}

aux_select_by_itemsets() {
    local patt allpatt iglob iset i
    [ -z "$1" ] && { error_missing; return 1; }
    allpatt=''
    # for each glob expression
    for iglob in "$@" ; do
        # expand glob
        for iset in ${TMWW_UTILPATH}/${iglob}*.itemset ; do
            patt=''
            case "${iset}" in
                *.id.itemset)
                    while read i; do
                        check_string_chars "$i" "*[!0-9]*" "Disallowed characters in NAME $i" || return 1
                        patt="${patt:+${patt}${nl}}$i"
                    done < "${iset}"
                    ;;
                *.name.itemset)
                    while read i; do
                        check_string_chars "$i" "*[!a-zA-Z]*" "Disallowed characters in NAME $i" || return 1
                        patt="${patt:+${patt}|}$i"
                    done < "${iset}"
                    if [ -n "${patt}" ]; then
                        # converting names pattern to ids pattern
                        patt=$( egrep "^${csv}(${patt})," ${itemfiles} | aux_db_cut_fields | cut -f 2 )
                    fi
                    ;;
            esac
            [ -z "${patt}" ] || allpatt="${allpatt:+${allpatt}${nl}}${patt}"
        done
    done
    patt=$( printf "%s" "${allpatt}" | sort -u | tr '\n' '|' )
    patt="(${patt%|})"
    [ "${patt}" = "()" ] && return
    aux_select_inventory
    aux_select_storage
}

aux_select_opts() {
    while ${GETOPTS} nics opt; do
        case "${opt}" in
            # suppress player resolution (only per account info)
            c) select_no_resolve="yes" ;;
            # include matched item ids
            i) select_add_id="yes" ;;
            # include matched item names
            n) select_add_name="yes" ;;
            # single line output (don't split inventory/storage and match lines)
            s) select_single_line="yes" ;;
            *) error_incorrect; return 1 ;;
        esac
    done
}

func_select() {
    local criterion select_no_resolve select_add_id select_add_name select_single_line
    requireplugin db.lib.sh || return 1
    aux_select_opts "$@"
    shift $( expr $OPTIND - 1 )
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    case "${criterion}" in
        ids|names|re|itemsets) : ;;
        *) error_incorrect; return 1 ;;
    esac
    eval aux_select_by_${criterion} \"\$@\"
    return $?
}


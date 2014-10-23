#!/bin/sh
# tmww lib: alts.lib.sh

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

charconflicts="${TMWW_ALTSPATH}/char_conflicts.log"
partyconflicts="${TMWW_ALTSPATH}/party_conflicts.log"
chardb="${TMWW_ALTSPATH}/dbchars.txt"
partydb="${TMWW_ALTSPATH}/dbparty.txt"
# separate temp files in case of lockfile timeout
# using PRIVTMP here to avoid endless chmod to ensure multiuser support
chardbtmp=${TMWW_PRIVTMP}/chardb.temp
chardbtmp2=${TMWW_PRIVTMP}/chardb.temp2
partydbtmp=${TMWW_PRIVTMP}/partydb.temp
partydbtmp2=${TMWW_PRIVTMP}/partydb.temp2

AGREP=$(command -v agrep 2>&-)

check_agrep() {
    if [ -z "${AGREP}" ]; then
        error "agrep not found. Aborting."
        return 1
    fi
}

#
# char
#
#

# write duplicate entries to charconflicts log
# removes all found duplicates
# args:
# 1 -- accid
# 2 -- charname
aux_char_conflicts() {
    chname=$( sed_chars "$2" )
    # double escaping: awk param, regex pattern
    chnameescaped=$( printf "%s" "${chname}" | sed 's/\\/\\\\/g' )
    chescaped=$( printf "%s" "$2" | sed 's/\\/\\\\/g' )
    ${AWK} ${AWKPARAMS} -v chname="${chnameescaped}" -v chline="$1 ${chescaped}" -v rundate="$(date -Ru)" \
        -v charconflicts="${charconflicts}" -- '
        function is_empty(checked_array,    checked_index) {
            for (checked_index in checked_array) return 0; return 1 }
        $0 ~ "^....... " chname "$" {
            # print "debug chname " chname " chline " chline " 0 " $0 >> charconflicts
            if ( $0 != chline )
                a [ NR ] = $0
            next
        }
        { print }
        END {
            if ( ! is_empty(a) ) {
                print "replacing collision chars; " rundate >> charconflicts
                for ( i in a ) print a[i] >> charconflicts
            }
        }
    ' "${chardbtmp}" > "${chardbtmp2}"
}

func_char_add() {
    if [ "$1" = "id" ]; then
        if [ ! -z "$2" ]; then
            accid="$2"
        else error_missing; return 1; fi
    else error_incorrect; return 1; fi
    if [ "$3" = "char" ]; then
        if [ ! -z "$4" ]; then
            charname="$4"
        else error_missing; return 1; fi
    else error_incorrect; return 1; fi
    [ -z "$5" ] || { error_toomuch; return 1; }
    set_db_lock
    cp -f "${chardb}" "${chardbtmp}" >/dev/null 2>&1
    # check for collisions
    aux_char_conflicts "${accid}" "${charname}"
    printf "%s %s\n" "${accid}" "${charname}" >> "${chardbtmp2}"
    sort -n "${chardbtmp2}" | uniq > "${chardbtmp}"
    store_shared "${chardbtmp}" "${chardb}"
    unset_db_lock
}

aux_char_resolve() {
    check_jq || return 2
    set_db_lock
    cp -f "${playerdb}" "${playerdbtmp}" >/dev/null 2>&1
    # replace alt for account in all records
    # user player resolve for all alts on record
    # or player sanitize to detect collisions
    ${JQ} -c -M --arg alt "$4" --arg accid "$2" \
        "if (has(\"alts\") and ((.alts|map(.==\$alt)|contains([true])))) then \
        ((.accounts|=.+[\$accid])|(.alts|=.-[\$alt])) else . end" \
            "${playerdbtmp}" > "${playerdbtmp2}" 2>&-
    if [ "$?" -eq 0 ]; then
        store_shared "${playerdbtmp2}" "${playerdb}"
    else
        error "Error occured. Contact db owner to check consistency."
    fi
    unset_db_lock
}

# substitute charname for account in all matched records
# args: id 123 char asd
func_char_resolve() {
    func_char_add "$@"
    [ "$err_flag" -eq 1 ] && return 1
    aux_char_resolve "$@"
}

func_char_fuzzy() {
    local output_format
    output_format=""
    if [ -z "$2" ]; then
        output_format="chars"
    elif [ "$1" = "chars" -a -z "$3" ]; then
        shift; output_format="chars"
    elif [ "$1" = "ids" -a -z "$3" ]; then
        shift; output_format="ids"
    fi
    [ -z "$2" -a ! -z "$1" ] || { error_incorrect; return 1; }
    if ! printf "%s" "$1" | egrep -q '^[-a-zA-Z0-9_/\., ]+$'; then
        error_incorrect; return 1; fi
    patt=$( aux_fuzzy_pattern $1 )
    if [ "$output_format" = "chars" ]; then
        sed ${ESED} -n "h;s/^.{8}//
            /${patt}/{x;s/^.{8}//p}" "${chardb}"
    else
        sed ${ESED} -n "h;s/^.{8}//
            /${patt}/{x;p}" "${chardb}"
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
        shift; output_format="chars"
    elif [ "$1" = "ids" -a -z "$3" ]; then
        shift; output_format="ids"
    fi
    [ -z "$2" -a ! -z "$1" ] || { error_missing; return 1; }

    if [ "$output_format" = "chars" ]; then
        agrep -i ${faultlevel:+-$faultlevel} "^[0-9]* #$1" "${charsdb}" | sed 's/^.\{8\}//g'
    else
        agrep -i ${faultlevel:+-$faultlevel} "^[0-9]* #$1" "${chardb}"
    fi
}

func_char_grep() {
    local output_format
    output_format=""
    if [ -z "$2" ]; then
        output_format="chars"
    elif [ "$1" = "chars" -a -z "$3" ]; then
        shift; output_format="chars"
    elif [ "$1" = "ids" -a -z "$3" ]; then
        shift; output_format="ids"
    fi
    [ -z "$2" -a ! -z "$1" ] || { error_incorrect; return 1; }
    patt=$(printf "%s" "$1" | sed "y/${ucase}/${lcase}/")
    if [ "$output_format" = "chars" ]; then
        sed ${ESED} -n "h;y/${ucase}/${lcase}/;s/^.{8}//
            /${patt}/{x;s/^.{8}//p}" "${chardb}"
    else
        sed ${ESED} -n "h;y/${ucase}/${lcase}/;s/^.{8}//
            /${patt}/{x;p}" "${chardb}"
    fi
}

# args:
# 1 -- charname
func_char_get() {
    if ! [ -z "$2" -a ! -z "$1" ]; then
        if [ "$1" = "id" -a "$2" = "by" -a "$3" = "char" ]; then
            shift 3
        elif [ "$1" = "by" -a "$2" = "char" ]; then
            shift 2
        else error_incorrect; return 1; fi
        [ -z "$2" -a ! -z "$1" ] || { error_incorrect; return 1; }
    fi
    chname=$( sed_chars "$1" )
    sed ${ESED} -n "/^.{8}${chname}$/{s/^(.{7}).*$/\1/p;q}" "${chardb}"
}

aux_char_show_ids_by_id() {
    ${AWK} ${AWKPARAMS} -- "
    BEGIN { matched = 0 }
    { if ( \$1 == \"$1\" ) { print; matched = 1; }
      else { if ( matched == 1 ) exit ; } }
    " "${chardb}"
}

aux_char_show_chars_by_id() {
    aux_char_show_ids_by_id "$1" | sed 's/^.\{8\}//'
}

# there's obvious way to flood it just by recreating char on free account slot
# multiple times
aux_char_show_ids_by_char() {
    ${AWK} ${AWKPARAMS} -- "
    BEGIN { matched = 0; maxchars = 30 ; charcount = \"\"
        prev_id = \"\" ; split(\"\", charalts) }
    {
        if ( prev_id != \$1 ) {
            if ( matched == 1 ) exit
            split(\"\",charalts)
            charalts [ charcount = 1 ] = \$0
        }
        else {
            if ( charcount > maxchars ) {
                if ( matched == 1 ) exit
                next
            }
            charalts [ ++charcount ] = \$0
        }
        prev_id = \$1
        if ( \"$1\" == substr(\$0,9) ) matched = 1
    }
    END {
        if ( matched == 1 ) {
            for ( i in charalts ) print charalts[i]
        }
    }
    " "${chardb}"
}

aux_char_show_chars_by_char() {
    aux_char_show_ids_by_char "$1" | sed 's/^.\{8\}//'
}

aux_char_show_parties() {
    local party
    while read line; do
        party=$( func_party_get "${line#????????}" )
        if [ -z "${party}" ]; then
            printf "%s\n" "${line}"
        else
            printf "%-32s -- %s\n" "${line}" "${party}"
        fi
    done
}

aux_char_show_parties_by_id() {
    aux_char_show_ids_by_id "$1" | aux_char_show_parties
}

aux_char_show_parties_by_char() {
    aux_char_show_ids_by_char "$1" | aux_char_show_parties
}

func_char_show() {
    local output_format criterion
    [ -z "$2" -a ! -z "$1" ] && {
        aux_char_show_chars_by_char "$@"
        return
    }
    output_format="chars"
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
    [ -z "$2" ] && { error_missing; return 1; }
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    case "${criterion}" in
        char)   : ;;
        id)     check_id "$1" || return 1 ;;
        *)      error_incorrect; return 1; ;;
    esac
    eval aux_char_show_${output_format}_by_${criterion} \"\$@\"
    return $?
}

# massive lookup - grep + lookup all grep matches
func_char_dig() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    for i in $(func_char_grep ids "$1" | cut -d ' ' -f 1); do
        func_char_show ids by id "$i"; done | sort | uniq
}

# remove oldest collided ids
# expects prepared chardbtmp and locked db
# args -- no
aux_char_sanitize() {
    # sort by charname, remove older entries, sort back
    sort -k 2 "${chardbtmp}" | ${AWK} ${AWKPARAMS} -- "
        BEGIN { prev = \"\" }
        function is_empty(checked_array,    checked_index) {
            for (checked_index in checked_array) return 0; return 1 }
        /^$/ { next }
        {
            if ( substr(\$0,8) != substr(prev,8) )
                print prev
            else
                a [ NR ] = prev
            prev = \$0
        }
        END {
            print prev
            if ( ! is_empty(a) ) {
                for ( i in a ) print a[i] >> \"${charconflicts}\"
            }
        }
    " | sort -n > "${chardbtmp2}"
    store_shared "${chardbtmp2}" "${chardb}"
}

# args: -- no
func_char_sanitize() {
    [ -n "$1" ] && { error_toomuch; return 1; }
    set_db_lock
    cp -f "${chardb}" "${chardbtmp}" >/dev/null 2>&1
    echo "sanitation on $(date -Ru)" >> "${charconflicts}"
    aux_char_sanitize
    unset_db_lock
}

# args:
# 1 -- file with chars
func_char_merge() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    set_db_lock
    # merge files, remove duplicates and newlines
    sort -n "$1" "${chardb}" | uniq > "${chardbtmp}"
    echo "merging $1; $(date -Ru)" >> "${charconflicts}"
    aux_char_sanitize
    unset_db_lock
}

#
# party
#
#

# write duplicate entries to partyconflicts log
# args:
# 1 -- partyname
# 2 -- charname
aux_party_conflicts() {
    chparty=$( printf "%s\t%s" "$1" "$2" | sed 's/\\/\\\\/g' )
    # double escaping: awk param, regex pattern
    chname=$( sed_chars "$2" )
    chescaped=$( printf "%s" "${chname}" | sed 's/\\/\\\\/g' )
    ${AWK} ${AWKPARAMS} -F "" -v rundate="$(date -Ru)" -v partyconflicts="${partyconflicts}" \
        -v chparty="${chparty}" -v chname="${chescaped}" -- '
        function is_empty(checked_array,    checked_index) {
            for (checked_index in checked_array) return 0; return 1 }
        $0 ~ "\t" chname "$" {
            if ( $0 != chparty )
                a [ NR ] = $0
            next
        }
        { print }
        END {
            if ( ! is_empty(a) ) {
                print "replacing collision chars; " rundate >> partyconflicts
                for ( i in a ) print a[i] >> partyconflicts
            }
        }
    ' "${partydbtmp}" > "${partydbtmp2}"
}

func_party_add(){
    if [ "$1" = "party" ]; then
        if [ ! -z "$2" ]; then
            partyname=$2
        else error_missing; return 1; fi
    else error_incorrect; return 1; fi
    if [ "$3" = "char" ]; then
        if [ ! -z "$4" ]; then
            charname=$4
        else error_missing; return 1; fi
    else error_incorrect; return 1; fi
    [ -z "$5" ] || { error_toomuch; return 1; }
    set_db_lock
    cp -f "${partydb}" "${partydbtmp}" >/dev/null 2>&1
    aux_party_conflicts "$partyname" "$charname"
    printf "%s\t%s\n" "${partyname}" "${charname}" >> "${partydbtmp2}"
    # i hope you have your aenglesk
    LC_COLLATE=en_US.UTF-8 sort "${partydbtmp2}" | uniq > "${partydbtmp}"
    store_shared "${partydbtmp}" "${partydb}"
    unset_db_lock
}

# args: -- no
aux_party_sanitize() {
    a=$(printf "\\t")
    sort -t "$a" -k 2 "${partydbtmp}" | ${AWK} ${AWKPARAMS} -- '
        BEGIN { FS="\t"; prev = ""; prevchar=""; dup = 0 }
        /^$/ { next }
        {
            if ( $2 == prevchar ) {
                print prev; dup++
            } else {
                if ( dup != 0) print prev
                dup = 0
            }
            prev = $0; prevchar=$2
        }
        END { if ( dup != 0) print prev }
    '
}

# print to stdout colliding chars, no actions on db performed
# args: -- no
func_party_sanitize() {
    [ -z "$1" ] || { error_toomuch; return 1; }
    cp -f "${partydb}" "${partydbtmp}" >/dev/null 2>&1
    [ -s "${partydbtmp}" ] && aux_party_sanitize
}

func_party_fuzzy() {
    [ -z "$2" -a ! -z "$1" ] || { error_incorrect; return 1; }
    if ! printf "%s" "$1" | egrep -q '^[-a-zA-Z0-9_/\., ]+$'; then
        error_incorrect; return 1; fi
    patt=$( aux_fuzzy_pattern $1 )
    sed ${ESED} -n "/${patt}.*${tabchar}/{s/${tabchar}.*$//p}" "${partydb}" | uniq
}

func_party_agrep() {
    check_agrep || return 1
    faultlevel=1
    OPTIND=1
    while ${GETOPTS} e: opt ; do
        case $opt in
            e)  faultlevel="${OPTARG}" ;;
            *)  error_incorrect; return 1 ;;
        esac
    done
    shift $(expr $OPTIND - 1)
    [ -z "$2" -a ! -z "$1" ] || { error_missing; return 1; }

    agrep -i ${faultlevel:+-$faultlevel} "^#$1${tabchar}" "${partydb}" | sed "s/${tabchar}.*$//g" | uniq
}

func_party_grep() {
    [ -z "$2" -a ! -z "$1" ] || { error_incorrect; return 1; }
    patt=$( sed_chars "$1" | sed "y/${ucase}/${lcase}/")
    sed ${ESED} -n "h;y/${ucase}/${lcase}/;
        /${patt}.*${tabchar}/{x;s/${tabchar}.*$//p}" "${partydb}" | uniq
}

func_party_dig() {
    [ -z "$2" -a ! -z "$1" ] || { error_incorrect; return 1; }
    patt=$( sed_chars "$1" | sed "y/${ucase}/${lcase}/")
    sed ${ESED} -n "h;y/${ucase}/${lcase}/;
        /${patt}.*${tabchar}/{x;s/${tabchar}/ /p}" "${partydb}"
}

func_party_get() {
    local chname
    if ! [ -z "$2" -a ! -z "$1" ]; then
        if [ "$1" = "by" -a "$2" = "char" ]; then
            shift 2
        else error_incorrect; return 1; fi
        [ -z "$2" -a ! -z "$1" ] || { error_incorrect; return 1; }
    fi
    chname=$( sed_chars "$1" )
    sed ${ESED} -n "/${tabchar}${chname}$/{s/${tabchar}.*$//p;q}" "${partydb}"
}

aux_party_show_chars_by_party() {
    local chparty
    chparty=$( printf "%s" "$1" | sed 's/\\/\\\\/g' )
    ${AWK} ${AWKPARAMS} -v party="${chparty}" -- '
    BEGIN { matched = 0; FS = "\t" }
    { if ( $1 == party ) { print $2; matched = 1; }
      else { if ( matched == 1 ) exit ; } }
    ' "${partydb}"
}

aux_party_show_ids_by_party() {
    aux_partydb_chars_by_party "$1" | while read charname; do
        printf "%s %s\n" "$(func_char_get "$charname")" "$charname"
    done
}

# there's obvious way to flood it just by recreating char on free account slot
# multiple times
aux_party_show_chars_by_char() {
    local chname
    chname=$( printf "%s" "$1" | sed 's/\\/\\\\/g' )
    ${AWK} ${AWKPARAMS} -v char="${chname}" -- '
    BEGIN { matched = 0; maxchars = 15 ; charcount = ""
        prev_party = "" ; split("", charalts); FS="\t" }
    {
        if ( prev_party != $1 ) {
            if ( matched == 1 ) exit
            split("",charalts)
            charalts [ charcount = 1 ] = $2
        }
        else {
            if ( charcount > maxchars ) {
                if ( matched == 1 ) exit
                next
            }
            charalts [ ++charcount ] = $2
        }
        prev_party = $1
        if ( $2 == char ) matched = 1
    }
    END {
        if ( matched == 1 ) {
            for ( i in charalts ) print charalts[i]
        }
    }
    ' "${partydb}"
}

aux_party_show_ids_by_char() {
    aux_partydb_chars_by_char "$1" | while read -r charname; do
        printf "%s %s\n" "$(func_char_get "$charname")" "$charname"
    done
}

aux_party_show_players() {
    local id player
    while read -r line; do
        id=${line%${line#???????}}
        # prevent errors in case char somehow has party but not know accid
        case "${id}" in
            *[!0-9]*)   player="" ;;
            *)          player="$( aux_player_get_accid ${id} )" ;;
        esac
        # alternate output format
        # printf "%s [ %-24s ] %s\n" "${id}" "$( aux_player_get_accid ${id} )" "${line#????????}"
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

func_party_show() {
    local output_format criterion
    output_format=""; criterion=""
    [ -z "$2" -a -n "$1" ] && {
        aux_party_show_ids_by_char "$1"
        return
    }
    output_format="chars"
    if [ "$1" != "by" ]; then
        case "$1" in
            chars|ids|players) : ;;
            *) error_incorrect; return 1 ;;
        esac
        output_format="$1"
        shift
    fi
    [ "$1" != "by" ] && { error_incorrect; return 1; }
    shift
    [ -z "$1" ] && { error_missing; return 1; }
    criterion="$1"; shift
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    case "${criterion}" in
        char|party)  : ;;
        *)          error_incorrect; return 1; ;;
    esac
    eval aux_party_show_${output_format}_by_${criterion} \"\$@\"
    return $?
}

# only merge files with duplicated removed, all collisions stay
# args:
# 1 -- merge file
func_party_merge() {
    set_db_lock
    cp -f "${partydb}" "${partydbtmp}" >/dev/null 2>&1
    echo "merging $1; $(date -Ru)" >> "${partyconflicts}"
    LC_COLLATE="en_US.UTF-8" sort "${partydbtmp}" "$1" | uniq > "${partydbtmp2}"
    store_shared "${partydbtmp2}" "${partydb}"
    unset_db_lock
}


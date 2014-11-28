#!/bin/sh
# tmww lib: list.lib.sh

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

# feel free to override with server plugin in config
requireplugin alts.lib.sh || return 1

TMWW_LISTCOMPPATH="${TMWW_LISTCOMPPATH:-${TMWW_PRIVTMP}/lists}"
TMWW_LISTCOMPPATH="${TMWW_LISTCOMPPATH}/${servername}"
TMWW_UPLISTPATH="${TMWW_UPLISTPATH:-${TMWW_PRIVTMP}/uplist}"
TMWW_UPLISTPATH="${TMWW_UPLISTPATH}/${servername}"

#
# code
#
#

trim_head() { printf "%s" "${1#"${1%%[! ]*}"}"; }
trim_tail() { printf "%s" "${1%"${1##[! ]*}"}"; }

aux_list_include() {
    result=$( printf "%s\n%s\n" "${result}" "${res}" | ${AWK} -- '
        { if (!($0 in a)) a[$0] = 1 }
        END { for (i in a) print i }
    ')
}

aux_list_exclude() {
    result=$( printf "%s\n-\n%s\n" "${result}" "${res}" | ${AWK} -- '
        /^-/ {sep=1; next}
        { if (sep) delete a[$0] ; else a[$0] = 1 }
        END { for (i in a) print i }
    ')
}

# internal
# stdio -- list file
aux_list_process() {
    while read -r line; do
        excl=''
        arg="${line}"
        case "${line}" in
            "##"*) continue ;;
            "#"*) line="${line#[#] }"
                arg=$( trim_head "${line}" )
                dir="${arg%% *}"
                arg=$( trim_head "${arg#* }" )
                case "${dir}" in
                    exclude)
                        excl=1
                        dir="${arg%% *}"
                        arg=$( trim_head "${arg#* }" )
                        ;;
                esac
                ;;
            '') continue ;;
            *)  dir="${defdir}" ;;
        esac
        arg=$( trim_tail $( trim_head "${arg}" ) )
        case "${dir}" in
            char) res="${arg}" ;;
            chars) res=$( aux_char_show_chars_by_char "${arg}" )
                if [ -z "${res}" ]; then
                    res="${arg}"
                elif [ -n "${list_install}" ]; then
                    id=$( func_char_get "${arg}" )
                    echo "${id}" >> "${idfile}"
                fi
                ;;
            id) res=$( aux_char_show_chars_by_id "${arg}" )
                if [ -n "${list_install}" ]; then
                    echo "${arg}" >> "${idfile}"
                fi
                ;;
            player) res=$( aux_player_show_chars_by_player "${arg}" )
                if [ -n "${list_install}" ]; then
                    id=$( aux_player_ids "${arg}" )
                    [ -n "${id}" ] && printf "%s\n" "${id}" >> "${idfile}"
                    echo "${arg}" >> "${playerfile}"
                fi
                ;;
            list)   res=$( aux_list_compile "${arg}" ) ;;
            rlist)  res=$( aux_list_compile "${TMWW_ROLE:+${TMWW_ROLE}/}${arg}" ) ;;
            *)      continue ;;
        esac
        [ -z "${res}" ] && continue
        # printf >&2 "DEBUG dir %s excl %s arg %s\n" "${dir}" "${excl:-no}" "${arg}"
        if [ -z "${excl}" ]; then
            aux_list_include
        else
            aux_list_exclude
        fi
    done
}

# args:
# 1 -- .list file
aux_list_compile() {
    local defdir result listfile res excl id
    if printf "%s\n" "${compiled_lists}" | grep -qw -- "$1"; then
        return 0
    fi
    compiled_lists="${compiled_lists} $1"
    result= # recursion level result
    res= # list line result for exclude/include
    listfile="${TMWW_LISTPATH}/$1"
    [ -f "${listfile}" ] || return 1
    case "$1" in
        *.list)     defdir="char" ;;
        *.clist)    defdir="chars" ;;
        *.alist)    defdir="id" ;;
        *.plist)    defdir="player" ;;
        *)          error "Unknown list format: $1, can't compile."; return 1 ;;
    esac
    aux_list_process < "${listfile}"
    if [ -f "${listfile}.fixes" ]; then
        aux_list_process < "${listfile}.fixes"
    fi
    printf "%s\n" "${result}"
}

aux_list_prepare() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    compiled_lists=
    # replacing / in path to .
    listcompfile=$( printf "%s\n" "$1" | sed 's|/|.|g' )
    upfile="${TMWW_UPLISTPATH}/${listcompfile}.updated"
    idfile="${TMWW_UPLISTPATH}/${listcompfile}.ids"
    playerfile="${TMWW_UPLISTPATH}/${listcompfile}.players"
    listcompfile="${TMWW_LISTCOMPPATH}/${listcompfile}"
    [ ! -f "${listcompfile}" -o -n "${force_recompile}" -o -f "${upfile}" -o \
        "${TMWW_LISTPATH}/$1" -nt "${listcompfile}" ] || return 0
    check_dir "${TMWW_LISTCOMPPATH}"
    if [ -n "${list_install}" ]; then
        check_dir "${TMWW_UPLISTPATH}"
        : > "${idfile}"
        : > "${playerfile}"
    fi
    verbose "Recompiling list $1"
    aux_list_compile "$1" > "${listcompfile}"
    if [ -n "${list_install}" ]; then
        [ -s "${idfile}" ] || rm -f "${idfile}"
        [ -s "${playerfile}" ] || rm -f "${playerfile}"
    fi
    rm -f "${upfile}"
}

# args:
# 1 -- list name
func_list_compile() {
    local compiled_lists listcompfile list_install idfile playerfile upfile
    list_install=
    aux_list_prepare "$@"
}

# args:
# 1 -- list name
func_list_install() {
    local compiled_lists listcompfile list_install idfile playerfile upfile
    list_install=1
    aux_list_prepare "$@"
}

# args:
# 1 -- id
func_list_update_ids() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    for i in "${TMWW_UPLISTPATH}"/*.ids ; do
        if grep -F "$1" "$i" ; then
            touch "${i%.ids}.updated"
        fi
    done
}

# args:
# 1 -- player
func_list_update_players() {
    [ -n "$2" ] && { error_toomuch; return 1; }
    [ -z "$1" ] && { error_missing; return 1; }
    for i in "${TMWW_UPLISTPATH}"/*.players ; do
        if grep -F "$1" "$i" ; then
            touch "${i%.players}.updated"
        fi
    done
}

func_list() {
    local subcommand force_recompile
    force_recompile=
    OPTIND=1
    while ${GETOPTS} f opt; do
        case "${opt}" in
            f) force_recompile=1 ;;
            *) error_incorrect; return 1 ;;
        esac
    done
    shift $(( ${OPTIND} - 1 ))
    [ -z "$1" ] && { error_missing; return 1; }
    subcommand="$1"
    shift 1
    case "${subcommand}" in
        compile) func_list_compile "$@" ;;
        install) func_list_install "$@" ;;
        update)
            [ -z "$1" ] && { error_missing; return 1; }
            subcommand="$1"
            shift 1
            case "${subcommand}" in
                ids)        func_list_update_ids ;;
                players)    func_list_update_players ;;
                *)          error_incorrect; return 1 ;;
            esac
            ;;
        *) error_incorrect; return 1 ;;
    esac
}


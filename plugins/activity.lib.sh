#!/bin/sh
# tmww lib: activity.lib.sh

# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

# check if not run from tmww
if [ "$TMWW_PLUGINS" != "yes" ] ; then
    echo >&2 "This script is tmww lib and not intended for manual run."
    exit 1
fi

TMWW_VERSIONREPORT="${TMWW_VERSIONREPORT:-${HOME}/log/tmww}"
# sparkchars should be 6 or 7
TMWW_SPARKCHARS="${TMWW_SPARKCHARS:-6}"
# split stat line by 10 chars with space
TMWW_STATSPLIT="no"
interval_day_limit=150
interval_month_limit=60
# idle limit - max difference between time records: should reset online marks
# that mean if player was online with any of it's chars and difference between
# recorded online marks exceeds idle limit online presence will be resetted
# interval in minutes; default is 120
internal_activity_idle_limit=100

set_pattern_lock() {
    activity_patt_file=$( mktemp --tmpdir="${TMWW_PRIVTMP}" )
    trap_add activity "rm -rf '${activity_patt_file}' >/dev/null 2>&1" 
}
unset_pattern_lock() {
    rm -rf "${activity_patt_file}" >/dev/null 2>&1
}

#
# export
#
#

aux_client_chars() {
    case "${client_method}" in
        accid)
            requireplugin alts.plugin || return 1
            func_char_show by id "${client_value}" || return 1
            ;;
        charname)
            printf "%s\n" "${client_value}"
            ;;
        accbychar)
            requireplugin alts.plugin || return 1
            func_char_show "${client_value}" || return 1
            ;;
        player)
            requireplugin alts.plugin || return 1
            func_player_show by player "${client_value}" || return 1
    esac
}

# with -m setting should be called with from* variables set to unrealistic low date
aux_interval_month() {
    while [ "${interval_month}" -gt 0 ]; do
        check_month=$( printf "%s-%s/*.yml " "${calcyear}" "${printmonth}" )
        [ -d "${TMWW_VERSIONREPORT}/${servername}/${calcyear}-${printmonth}" ] && printf "%s " "${check_month}"
        # compare year/month
        [ ${from_year}${from_month} -ge ${calcyear}${printmonth} ] && return
        # decrement month
        if [ "${calcmonth}" -gt 1 ]; then
            calcmonth=$(( ${calcmonth} - 1 ))
            printmonth=$(printf "%02u" "${calcmonth}" )
        else
            calcyear=$(( ${calcyear} - 1 ))
            calcmonth=12; printmonth=12
        fi
        interval_month=$(( ${interval_month} - 1 ))
    done
}

# with -d setting should be called with from* variables set to unrealistic low date
aux_interval_day() {
    while [ "${interval_day}" -gt 0 ]; do
        check_day=$( printf "%s-%s/%s.yml " "${calcyear}" "${printmonth}" "${printday}" )
        [ -f "${TMWW_VERSIONREPORT}/${servername}/"${check_day} ] && printf "%s " "${check_day}"
        # compare year/month
        [ ${from_year}${from_month}${from_day} -ge ${calcyear}${printmonth}${printday} ] && return
        # decrement day
        if [ "${calcday}" -gt 1 ]; then
                calcday=$(( ${calcday} - 1 ))
                printday=$(printf "%02u" "${calcday}" )
        else 
            if [ "${calcmonth}" -gt 1 ]; then
                calcmonth=$(( ${calcmonth} - 1 ))
                printmonth=$(printf "%02u" "${calcmonth}" )
            else
                calcyear=$(( ${calcyear} - 1 ))
                calcmonth=12; printmonth=12
            fi
            # calcday=31; printday=31
            calcday=$(date -d "${calcyear}/${calcmonth}/1+1month-1day" "+%d")
            printday="${calcday}"
        fi
        interval_day=$(( ${interval_day} - 1 ))
    done
}

# here goes huge and ugly part
# - taking too much days/months can probably exceed command line limit
#   just for safety added limitations
aux_form_interval() {
    if [ ! -z "${interval_month}" ]; then
        if [ "${interval_month}" -gt 1 ]; then
            [ "${interval_month}" -gt "${interval_month_limit}" ] && \
                { error "Try less months. Aborting."; return 1; }
            calcmonth="$(date -u +%_m)"; printmonth=$( printf "%02u" "${calcmonth}")
            calcyear="$(date -u +%Y)"
            from_year=1; from_month=1; from_day=1
            interval=$(aux_interval_month)
        else
            check_month="$(date -u +%Y-%m)"
            [ ! -d "${TMWW_VERSIONREPORT}/${servername}/${check_month}" ] && return 1
            interval="$(date -u +%Y-%m)/*.yml"
        fi
    elif [ ! -z "${interval_day}" ]; then
        if [ "${interval_day}" -gt 1 ]; then
            [ "${interval_day}" -gt "${interval_day_limit}" ] && \
                { error "Try less days. Aborting."; return 1; }
            calcday="$(date -u +%_d)"; printday=$( printf "%02u" "${calcday}")
            calcmonth="$(date -u +%_m)"; printmonth=$( printf "%02u" "${calcmonth}")
            calcyear="$(date -u +%Y)"
            from_year=1; from_month=1; from_day=1
            interval=$(aux_interval_day)
        else
            interval="$(date -u +%Y-%m/%d).yml"
            if [ ! -f "${TMWW_VERSIONREPORT}/${servername}/${interval}" ]; then return 1; fi
        fi
    else
        # from/to interval
        # validate dates
        # dates should be yyyy-mm[-dd] and from/to of similar format
        from_year=$( get_dash 1 "${interval_from}" )
        from_month=$( get_dash 2 "${interval_from}" )
        from_day=$( get_dash 3 "${interval_from}" )
        [ -z "${from_year}" -o -z "${from_month}" ] && { error_date; return 1; }
        case "${from_year}" in *[!0-9]*) error_date; return 1; ;; esac
        case "${from_month}" in *[!0-9]*) error_date; return 1; ;; esac
        date_with_day=''
        if [ ! -z "${from_day}" ]; then
            case "${from_day}" in *[!0-9]*) error_date; return 1; ;; esac
            date_with_day="yes"
        fi
        if [ -z "${interval_to}" ]; then
            calcday="$(date -u +%_d)"
            calcmonth="$(date -u +%_m)"
            calcyear="$(date -u +%Y)"
        else
            strip_zero() { printf "%s" "${1#0}" ; }
            calcyear=$(strip_zero $( get_dash 1 "${interval_to}"))
            calcmonth=$(strip_zero $( get_dash 2 "${interval_to}"))
            calcday=$(strip_zero $( get_dash 3 "${interval_to}"))
            case "${calcyear}" in *[!0-9]*) error_date; return 1; ;; esac
            case "${calcmonth}" in *[!0-9]*) error_date; return 1; ;; esac
            [ ! -z "${date_with_day}" -a -z "${calcday}" -o -z "${date_with_day}" -a ! -z "${calcday}" ] && {
                error "Incorrect from/to date pair. Aborting."; return 1; }
            case "${calcday}" in *[!0-9]*) error_date; return 1; ;; esac
        fi
        printday=$( printf "%02u" "${calcday}"); printmonth=$( printf "%02u" "${calcmonth}")
        # form interval
        if [ "${date_with_day}" ]; then
            interval_day=${interval_day_limit}
            interval=$(aux_interval_day)
        else
            interval_month=${interval_month_limit}
            interval=$(aux_interval_month)
        fi
    fi
}

# credits https://github.com/holman/spark
spark() {
    local step numbers min=1000000000000 max=0
    [ -z "${minspark}" ] || min="${minspark}"
    [ -z "${maxspark}" ] || max="${maxspark}"

    ticks="▁ ▂ ▃ ▄ ▅ ▆ ▇ █"

    for n in "$@"; do
        n=${n%.*}
        [ $n -ne -1 ] && {
            [ $n -lt ${min} ] && min=$n
            [ $n -gt ${max} ] && max=$n
        }
        numbers=${numbers}${numbers:+ }$n
    done

    step=$(( (( ${max} - ${min} ) << 8 ) / ${TMWW_SPARKCHARS} - 1 ))
    [ "${step}" -lt 1 ] && step=1

    aux_get_tick() { eval printf \"\%s\" \$$(( $1 + 2 )); }
    
    for n in ${numbers}; do
        [ "$n" -lt 0 ] && { printf "-"; continue; }
        [ "$n" -eq 0 ] && { printf "."; continue; }
        aux_get_tick $(( (($n-${min})<<8)/${step} )) ${ticks}
    done
    normalspark=''
}


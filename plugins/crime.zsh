# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

_tmww_plugin_crime() {
    _tmww_servername
    _arguments \
        '-u[mirror GM logs folder]' \
        '-m[cut readable messages]' \
        '-r[parse logs for ban/block records]' \
        '-f[fill up player records with ban/block results]' \
        '-b[GM stats for bans (cumulative with -B)]' \
        '-B[GM stats for blocks (cumulative with -b)]'
}


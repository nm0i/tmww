# this file is part of tmww - the mana world watcher
# willee, 2012-2014
# GPL v3

alias ta1="tmww -a accsniffer default start"
alias ta0="tmww -a accsniffer default stop"
alias tas="tmww -a accsniffer default status"

_tmww_plugin_accsniffer() {
    _arguments \
        ':accsniffer command:(start stop status)'
}


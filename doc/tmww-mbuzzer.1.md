Name
----
mbuzzer - bot suit notification interface

Usage
-----

    -t STRING   -- send event of STRING type
    -f FILE     -- send file as event
    -b STRING   -- send speach to festival
    -i          -- ignore abandoned socket
    -n STRING   -- send notification string
    { start | status | stop } -- operate listening server

Description
-----------

mbuzzer depends on socat and jq.

mbuzzer does not rely on tmww to work. "start"/"stop" options control listening
server. This way you can pass sound/popup notifications from remote box.

With -t , -f or -b mbuzzer simply writes JSON line to unix domain socket.

Notification line may take several special sequences (same as tmww-notify(1) ):

%t  notification title
%b  message body

Bugs
----

Cannot get socat to work properly:

    # faulty
    $ ( socat 'unix-listen:test.sock,reuseaddr,fork' - | while read line; do echo 123 $line; done )&
    $ for i in $(seq 1 10); do echo $i; sleep 1; done | socat - 'unix-connect:test.sock'
    # desired
    $ socat 'unix-listen:test.sock,reuseaddr,fork' - | while read line; do echo 123 $line; done
    $ for i in $(seq 1 10); do echo $i; sleep 1; done | socat - 'unix-connect:test.sock'

Example
-------

.asoundrc

Example .asoundrc taken using alsaequal (based on source from
http://mpd.wikia.com/wiki/Alsa):

    # the sound card
    pcm.real {
        type hw
        card 0
        device 0
    }

    # the ipc stuff is needed for permissions, etc.
    pcm.dmixer {
        type dmix
        ipc_key 1024
        ipc_perm 0666
        slave.pcm "real"
        slave {
            period_time 0
            period_size 1024
            buffer_size 8192
            rate 44100  
        }
        bindings {
            0 0
            1 1 
        }
    }

    ctl.dmixer {
        type hw
        card 0
    }

    ctl.equal {
        type equal
    }

    pcm.plugequal {
        type equal
        slave.pcm "plug:dmixer"
    }

    pcm.preequal {
        type plug
        slave.pcm "plugequal"
    }

    # software volume
    pcm.softvol {
        type softvol
    #   slave.pcm "preequal"
        slave.pcm "dmixer"
        control {
            name "Software"
            card 0
        }
    }

    # mana volume control
    pcm.manavol {
        type softvol
        slave.pcm "dmixer"
        control {
            name "Mana"
            card 0
        }
    }

    # ctrl for mpd volume
    ctl.manavol {
        type hw
        card 0
    }

    # music volume control
    pcm.musicvol {
        type softvol
        slave.pcm "preequal"
    #   slave.pcm "dmixer"
        control {
            name "Music"
            card 0
      }
    }

    # ctrl for music volume
    ctl.musicvol {
        type hw
        card 0
    }

    # input
    pcm.input {
        type dsnoop
        ipc_key 3129398
        ipc_key_add_uid false
        ipc_perm 0660
        slave.pcm "810"
    }

    # duplex device
    pcm.duplex {
        type asym
        playback.pcm "softvol"
        capture.pcm "input"
    }

    # default device
    pcm.!default {
        type route
        slave {
            pcm "duplex"
            channels 2
        }
        ttable {
            0.0 1
            1.1 1
        }
    }

.festivalrc

Looks like something is lacking in shown .asoundrc so:

    (Parameter.set 'Audio_Command "aplay -Dplug:default -q -f S16_LE -r $SR $FILE")

Example
-------
See example_config.conf in distribution.

Copyright
---------
TEMPLATE(COPYRIGHT)

Authors
-------
TEMPLATE(AUTHORS)

See also
--------
tmww(1), tmww-plugin(7), tmww-mbuzzer(1), socat(1), dunst(1)


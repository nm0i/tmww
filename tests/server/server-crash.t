server.plugin escape codes tests as of 2014-10-16
=================================================

call from distribution path with:
$ LC_ALL=C PATH="./bin:${PATH}" build-aux/shtest -E 'DIRCONFIG="tests/confserver"' tests/db.t

Safety test. This file should not be deleted with tests:

    $ echo safety test file > st

Tests
-----

code for pretty printer of get/show differ a bit

    $ tmww char -s1 get sgp q1 by char mage
    sgp  login                          mail                           lvl  gp  lastip     g  accid    charname
         "n\n\\n\011/\"${USER}\${USER}  'n\n\\n\011/\'${USER}\${USER}  109  43  127.0.0.1  M  2000000  mage
    $ tmww char -s1 show sgp q1 by id 2000000
    sgp  login                          mail                           lvl  gp      lastip     g  accid    charname
         "n\n\\n\011/\"${USER}\${USER}  'n\n\\n\011/\'${USER}\${USER}  100  999982  127.0.0.1  M  2000000  "n\n\\n\011/\"${USER}\${USER}
         "n\n\\n\011/\"${USER}\${USER}  'n\n\\n\011/\'${USER}\${USER}  109  43      127.0.0.1  M  2000000  mage
         "n\n\\n\011/\"${USER}\${USER}  'n\n\\n\011/\'${USER}\${USER}  99   999966  127.0.0.1  M  2000000  mmadmin
    $ tmww char -s1 get sgp q1 by char user1c1
    sgp  login                   mail                    lvl  gp  lastip     g  accid    charname
         "!@#$%^&*  ()~_+[]\"{}  '!@#$%^&*  ()~_+[]\'{}  91   50  127.0.0.1  M  2000001  user1c1
    $ tmww char -s1 show sgp q1 by id 2000001
    sgp  login                   mail                    lvl  gp  lastip     g  accid    charname
         "!@#$%^&*  ()~_+[]\"{}  '!@#$%^&*  ()~_+[]\'{}  91   50  127.0.0.1  M  2000001  user1c1
         "!@#$%^&*  ()~_+[]\"{}  '!@#$%^&*  ()~_+[]\'{}  1    50  127.0.0.1  M  2000001  user1c3
         "!@#$%^&*  ()~_+[]\"{}  '!@#$%^&*  ()~_+[]\'{}  1    50  127.0.0.1  M  2000001  "!@#$%^&*  ()~_+[]\"{}
    $ tmww char -s1 show sgp q1 by id 2000002
    sgp  login                                                     mail                                                    lvl  gp  lastip     g  accid    charname
         "$(date)\$(date)\\$(date)\"$(rm st)\$(rm st)\\$(rm st) \  '$(date)\$(date)\\$(date)\'$(rm st)\$(rm st)\\$(rm st)  255  25  127.0.0.1  M  2000002  "$(date)\$(date)\\$(date)\"$(rm st)\$(rm st)\\$(rm st) \
    $ tmww char -s1 get sgp q1 by char user3c1
    sgp  login                 mail                  lvl  gp  lastip     g  accid    charname
    29   ":(){:|:&};:\";rm st  ':(){:|:&};:\';rm st  91   50  127.0.0.1  M  2000003  user3c1
    $ tmww char -s1 show sgp q1 by id 2000003
    sgp  login                 mail                  lvl  gp  lastip     g  accid    charname
    29   ":(){:|:&};:\";rm st  ':(){:|:&};:\';rm st  91   50  127.0.0.1  M  2000003  user3c1
    29   ":(){:|:&};:\";rm st  ':(){:|:&};:\';rm st  11   44  127.0.0.1  M  2000003  ":(){:|:&};:\";rm st

checking safetytest file

    $ [ -f st ] || return 83
    $ rm st


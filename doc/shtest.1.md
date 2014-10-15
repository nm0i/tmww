Name
----
shtest - run command line tests

Synopsis
--------

shtest [-qrbefCdxh] [-s EXPR] [-E ENV] [-i INDENT] TEST+

Description
-----------

shtest is cli-programs testing script which executes commands from test file
and compares with model output.

Options
-------

-s EXPR     shell expression which will get test command piped to
            e.g. 'zsh -c "emulate sh;sh"' or 'bash --posix'; default is "/bin/sh"
-q          quite test; exit code set to number of failed tests
            default is verbose output
-r          refill all tests output (like cram -iy)
-c          clear all model output from test (higher priority than -r)
-i INDENT   indent (default is 4)
-b          fail test on unhandled error code
-e          keep default environment (don't inherit LC_ALL and PATH from shell)
-E ENV      set custom environment prefix for each call
-f          force tests ignoring faults
-C          do not colorize diff
-d          discard commands stderr
-x          show which commands are executed
-h          this help

Environment
-----------

LC_ALL  default is C
PATH    by default PATH isn't passed

With -e option environment string is concatenated with -E argument value.

Format
------

Any line not starting with indent is ignored. Any indented line without context is ignored.

Special meaning indented lines are:

<indent> % CMD  auxiliary command to execute (output/exit code isn't checked), no multiline commands
<indent> $ CMD  command to execute
<indent> > CMD  continuation of command
<indent> ? NUM  expected exit code NUM
<indent> STR    model output - compared until not-output line encountered or EOF

Exit status
-----------

0       normal exit
>0      number of tests passed before fail
80      normal interrupt from test
81      unhandled exit code from test
82      shtest error (mkdir faults and so on)
>82     user defined error

Authors
-------

willee <v4r@trioptimum.com>, 2014

Licensed under GPLv3 or later.
For full license see COPYING file in program's distribution.

See also
--------

cram https://bitheap.org/cram/


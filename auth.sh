#!/usr/bin/expect -f

set force_conservative 0  ;# set to 1 to force conservative mode even if
                          ;# script wasn't run conservatively originally
if {$force_conservative} {
        set send_slow {1 .1}
        proc send {ignore arg} {
                sleep .1
                exp_send -s -- $arg
        }
}

set timeout -1
spawn sudo cyberghostvpn --setup
match_max 100000
expect -exact "Setup account ...\r
Enter CyberGhost username and press \[ENTER\]: "
send -- "$::env(ACC)\r"
expect -exact "$::env(ACC)\r
Enter CyberGhost password and press \[ENTER\]: "
send -- "$::env(PASS)\r"
expect eof
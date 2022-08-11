#!/bin/bash

# output be like
# 23:49:51 [================>....] 84.6% finish=123.9min speed=99017K/sec
# 23:54:53 [=================>...] 85.1% finish=113.5min speed=104050K/sec
# 23:59:55 [=================>...] 85.7% finish=125.5min speed=90458K/sec
# 00:04:57 [=================>...] 86.3% finish=116.2min speed=93676K/sec
# 
#...last line updated every second, then newline every 10min by default

# this should be different per watch type tbh
sleeptime=1
limitm=${3:-10}  # limit in minutes
limit=$((limitm*60/$sleeptime)) # calculate how many round we need to meet uhe limit

tally=$((limit-1))	# tally is internal counting
count=-1                # count is a limit before stopping. -1=unlimited


# TODO
# * the "while true" loop should be the outer wrap, so the sleep logic is shared, not duplicated. Then run the "case" logic within each loop (ick, but better)
# ...outside = case ... means duplicated code
# ...outside = loop ... means duplicated "run case statement"
# * refactor to use `sleepenh` for improved timing accuracy

case $1 in
    mdadm)
        while true ; do 
            status=$(awk '/finish/ {print $1,$4,$6,$7}' < /proc/mdstat )
            echo -n "$(date +%T) $status "
            # TODO: check if it's done and if so, break the loop and exit
            [ -z "$status" ] && echo "" && break
            sleep $sleeptime
            tally=$((tally+1))
            [ $tally -ge $limit ] && echo "" && tally=0
            [ $tally -eq $count ] && echo "" && break
            tput cub 80 # I get issues on screen if I use $COLUMNS :(
        done
        ;;
    uptime)
        while true ; do 
            status=$(uptime)
            echo -n "$status "
            # TODO: check if it's done and if so, break the loop and exit
            [ -z "$status" ] && echo "" && break
            sleep $sleeptime
            tally=$((tally+1))
            [ $tally -ge $limit ] && echo "" && tally=0
            [ $tally -eq $count ] && echo "" && break
            tput cub 80 # I get issues on screen if I use $COLUMNS :(
        done
        ;;
    df)
        sleeptime=10    # with df, we only update every 10sec
        limit=$((limitm*60/$sleeptime)) # calculate how many round we need to meet uhe limit
        echo $limit
        filter=${2:-/home}
        echo "$(date +%T) $(df -BG | head -1 | cut -c 11- )"
        while true ; do 
            status=$(df -BG | grep -m 1 $filter | cut -c 11- | tr -d "\n")
            echo -n "$(date +%T) $status "
            # TODO: check if it's done and if so, break the loop and exit
            [ -z "$status" ] && echo "" && break
            tally=$((tally+1))
            [ $tally -ge $limit ] && echo "" && tally=0
            [ $tally -eq $count ] && echo "" && break
            sleep $sleeptime
            tput cub 80 # I get issues on screen if I use $COLUMNS :(
        done
        ;;
esac

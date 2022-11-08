#!/bin/bash

# these should be different per watch type tbh
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
# output be like
#00:44:54 [==================>..] 94.4% 95918K/sec fin=75min = Nov09 01:59:54   
#00:54:58 [===================>.] 95.1% 103751K/sec fin=60min = Nov09 01:54:58  
#01:05:03 [===================>.] 95.9% 96878K/sec fin=54min = Nov09 01:59:03   
#01:15:08 [===================>.] 96.6% 98187K/sec fin=43min = Nov09 01:58:08   
#01:25:13 [===================>.] 97.3% 98362K/sec fin=34min = Nov09 01:59:13   
#01:35:18 [===================>.] 98.1% 97589K/sec fin=24min = Nov09 01:59:18   
#01:45:22 [===================>.] 98.8% 80597K/sec fin=18min = Nov09 02:03:22   
#01:55:27 [===================>.] 99.5% 86027K/sec fin=7min = Nov09 02:02:27    
#02:03:44  = Nov09 02:03:44 ==>.] 99.9% 66800K/sec fin=0min = Nov09 02:03:43    
#...last line updated every second, then newline every 10min by default
        while true ; do 
            status=$(awk '/finish/ { 
                gsub(/speed=/,"",$7)
                gsub(/\..min/,"min",$6)
                gsub(/finish=/,"",$6)
                {print $1,$4,$7,"eta="$6}
            } ' < /proc/mdstat )
            # TODO: consider obtaining only the very key info, and generating 100% own output format:
            # - current bar graph is one char per 5%, but box drawing characters allows for 100 tickmarks in only 10 characters width, or 0.5% resolution at current width
            # - % count could be overlaid on the graph
            # - graph could even be 50char width at 2% resolution and purely colourised. See internode era internet graph for earlier implementation of idea (myinternode.sh -v) (dynamic width?!)
            # - give speed in M/sec not K/sec
            # - improve ETA format (min away, hours away, end time)
            # the "finish" time is munged above so it can be used in date below
            # ...note, the final line (that has no "finish" match) should also render sanely pls
            echo -n "$(date +%T) $status = $(date -d "now +${status##*=}" +"%b%d %T") "
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

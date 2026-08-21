#!/bin/bash

# these should be different per watch type tbh
sleeptime=1
limitm=${3:-10}  # limit in minutes
limit=$((limitm*60/$sleeptime)) # calculate how many round we need to meet uhe limit

tally=$((limit-1))      # tally is internal counting. Starts high to force early newline
count=-1                # count is a limit before stopping. -1=unlimited


# TODO
# * the "while true" loop should be the outer wrap, so the sleep logic is shared, not duplicated. Then run the "case" logic within each loop (ick, but better)
# ...outside = case ... means duplicated code
# ...outside = loop ... means duplicated "run case statement"
# * refactor to use `sleepenh` for improved timing accuracy
#   # or use multiples of diff between start runtime and each loop, via calls to `date` ??

case $1 in
    mdadm-new)
        sleeptime=2
        limitm=${3:-10}  # limit in minutes
        limit=$((limitm*60/$sleeptime)) # calculate how many round we need to meet uhe limit

        tally=$((limit-1))      # tally is internal counting. Starts high to force early newline
        count=-1                # count is a limit before stopping. -1=unlimited
        # TODO: merge with mdadm/mdadm-old?
            # This version obtains the very key info, and generating 100% own output format:
            # - OG bar graph is one char per 5%, but box drawing characters allows for 0.25% resolution in 50 chars
            # - stats/info overlaid on the graph
        blkbg=$(tput setab 15)
        whtbg=$(tput setab 15)
        whtfg=$(tput setaf 15)
        redfg=$(tput setaf 9)
        ylwbg=$(tput setab 11)
        ylwfg=$(tput setaf 11)
        blkfg=$(tput setaf 0)
        rev=$(tput rev)
        rset=$(tput sgr0)
        cub200=$(tput cub 200)

        bar=$ylwbg$ylwfg
        barwords=$ylwbg$blkfg
        while true ; do
            mdparsed=$(awk '
                /^md/ {md=$1}
                /finish/ { 
                  gsub(/%/,"",$4)       # s/%//g on percentage
                  gsub(/finish=/,"",$6) # drop "finish=" before eta
                  gsub(/\min/,"",$6)    # capture the numeric float of eta
                  gsub(/speed=/,"",$7)  # drop "speed=" before speed
                  gsub(/K.sec/,"",$7)   # drop units (K/sec) after speed
                  {printf "%s pctdone: %s tfrrateM/s: %.0f etamin: %.0f\n", md, $4, $7/1024, $6}
            } ' < /proc/mdstat)
                    # output be like this for parsing:
                        # md3 pctdone: 67.5 tfrrateM/s: 104 etamin: 789
            # note: we keep the provided pct because it truncates (always round down) which makes more sense at the 99.9% stage
            # but take the eta and tfs speeds rounded (sometimes up)
            
            # nothing found to show? then we finish up
            [ -z "$mdparsed" ] && echo "" && break

            echo "$mdparsed" | while read md pcttag pct ratetag rate etatag eta ; do
                pctint="${pct%.*}" # truncate pct to integer
                pctdec="${pct#*.}" # decimal component of pct
                etad=$(($eta/1440))  # integer days of the eta
                etadm=$(($eta%1440)) # leftover min
                etah=$(printf "%02d" $(($etadm/60))) # integer hours 
                etam=$(printf "%02d" $(($etadm%60))) # integer min leftover
                tgtdate=$(date -d "now +$eta min" +"%d%b %T")

                # template with dates and bar borders
                printf "${rset}%8s [ %49s] %14s " "$(date +%T)" " " "$tgtdate"

                # generate empty bar
                printf "%s" $cub200    # move to start of line
                tput cuf 10     # move to start of bar
                barlength=$(((pctint/2)))

                # only draw the empty bar on a new line
                if [ "$refresh" == false ] ; then
                    tput cuf $barlength
                else        # full redraw of the bar
                    printf "${bar}%${barlength}s${rset}" ">"
                fi

                # replace end of inverted bar with shading
                a="░" ;     b="▒" ;     c="▓" ;     d="█"
                case $barlength in
                    0) 
                        tput cub 1
                        ;;
                    1) 
                        tput cub 1
                        printf "${ylwbg}${ylwfg}$d${rset}${ylwfg}"
                        ;;
                    2)
                        tput cub 2
                        printf "${ylwbg}${ylwfg}$c$d${rset}${ylwfg}"
                        ;;
                    3)
                        tput cub 3
                        printf "${ylwbg}${ylwfg}$b$c$d${rset}${ylwfg}"
                        ;;
                    *)
                        tput cub 4
                        printf "${ylwbg}${ylwfg}$a$b$c$d${rset}${ylwfg}"
                        ;;
                esac

                # add extra fractional bar length
                # TODO: this is in white for first <2%
                #   and doesn;t work at all for <0.2% where a full 2% block is shown instead (it's the ">" and is in yellow) and text is white
                [ $pctint -lt 2 ] && tput cub 1 && printf "[${ylwfg}"    # this should fix the first 2% bar

                if [ $((pctint%2)) -eq 0 ] ; then # even
                    case $pctdec in
                        0|1) printf " " ;;
                        2|3|4) printf "▏" ;;
                        5|6) printf "▎" ;;
                        7|8|9) printf "▍" ;;
                    esac
                else        #  odd
                    case $pctdec in
                        0|1) printf "▌" ;;
                        2|3|4) printf "▋" ;;
                        5|6) printf "▊" ;;
                        7|8|9) printf "▉" ;;
                    esac
                fi

                # now let's overlay details
                #tput cub 200        # move to start of line
                printf "%s" $cub200    # move to start of line
                tput cuf 10         # move to start of bar
                if [ $pctint -lt 20 ] ; then
                    tput cuf 9
                    # TODO: this is a bit flickery. can it be improved?
                    printf  " %-9s %-9s %-9s %-9s " "$md" "${pct}%" "${rate}M/s" "${etad}d${etah}h${etam}m" 
                elif [ $pctint -ge 20 ] && [ $pctint -lt 40 ] ; then
                    printf "${barwords} %-8s ${rset}" "$md"
                    #tput cub 200    # move to start of line
                    printf "%s" $cub200    # move to start of line
                    tput cuf 29     # move right some
                    printf "${ylwfg} %-9s %-9s %-9s" "${pct}%" "${rate}M/s" "${etad}d${etah}h${etam}m" 
                elif [ $pctint -ge 40 ] && [ $pctint -lt 60 ] ; then
                    printf "${barwords} %-8s %-9s${rset}" "$md" "${pct}%"
                    #tput cub 200    # move to start of line
                    printf "%s" $cub200    # move to start of line
                    tput cuf 39     # move right some
                    printf "${ylwfg} %-9s %-9s" "${rate}M/s" "${etad}d${etah}h${etam}m" 
                elif [ $pctint -ge 60 ] && [ $pctint -lt 80 ] ; then
                    printf "${barwords} %-8s %-9s %-8s${rset}" "$md" "${pct}%" "${rate}M/s"
                    #tput cub 200    # move to start of line
                    printf "%s" $cub200    # move to start of line
                    tput cuf 49     # move right some
                    printf "${ylwfg} %-9s" "${etad}d${etah}h${etam}m" 
                else
                    printf "${barwords} %-8s %-9s %-9s %-9s${rset}" "$md" "${pct}%" "${rate}M/s" "${etad}d${etah}h${etam}m"
                    #tput cub 200    # move to start of line
                    printf "%s" $cub200    # move to start of line
                    tput cuf $(((pctint/2)+11))     # move right some
                    if [ $pctint -lt 98 ] ; then
                        remain=$(echo ".........." | cut -c 1-$(((50-(pctint/2)-1))))
                        printf "%s" ${remain}
                    fi
                fi
                # finally, move to the end
                tput cuf 100 # move to end
                printf "${rset}"    #
#                tput cub 3 # move back      # debug
#                printf "%s" "$barlength"    # debug
            done

            ## Unicode notes
            # - glowing trail     " ░▒▓█" (4 char) with a lead of the partials via BLOCK 
            #   ▏▎▍▌▋▊▉█  <-- 8 partials
            # other unicode to consider... themes?
            # #   - pointed?       ████🭬
            # #   - pointed trail? ░▒▓█🭬
            # ㎧ - this is metres per second, but could use for Meg/sec in a pinch - saves 2 char width
            
            sleep $sleeptime
            tally=$((tally+1))
            [ $tally -ge $limit ] && echo "" && refresh=true && tally=0
            [ $tally -eq $count ] && echo "" && break
            tput cub 80 # I get issues on screen if I use $COLUMNS :(
        done
    ;;


    mdadm|mdadm-old)
            # mdadm-new and mdadm-old explicitely denote two styles
            # "mdadm" is whatever is default of those
# output be like
#03:33:59 [===================>.] 97.8% 79763K/sec eta=70min = Aug17 04:43:59 
#03:44:06 [===================>.] 98.1% 77538K/sec eta=62min = Aug17 04:46:06 
#03:54:14 [===================>.] 98.4% 73605K/sec eta=55min = Aug17 04:49:14 
#04:04:22 [===================>.] 98.7% 70948K/sec eta=47min = Aug17 04:51:22 
#04:14:30 [===================>.] 98.9% 74283K/sec eta=35min = Aug17 04:49:30 
#04:24:38 [===================>.] 99.2% 66304K/sec eta=28min = Aug17 04:52:38 
#04:34:46 [===================>.] 99.5% 73502K/sec eta=15min = Aug17 04:49:46 
#04:44:54 [===================>.] 99.8% 69637K/sec eta=5min = Aug17 04:49:54  
#04:50:03  = Aug17 04:50:03 ==>.] 99.9% 74219K/sec eta=0min = Aug17 04:50:02 
#...last line updated every second, then newline every 10min by default
        while true ; do 
            status=$(awk '/finish/ { 
                gsub(/speed=/,"",$7)
                gsub(/\..min/,"min",$6)
                gsub(/finish=/,"",$6)
                {print $1,$4,$7,"eta="$6}
            } ' < /proc/mdstat )
#04:14:30 [===================>.] 98.9% 74283K/sec eta=35min = Aug17 04:49:30 
#1234567890123456789012345678901234567890123456789012345678901234567890123456789
#         1         2         3         4         5         6         7         

# 2% per char but we can use box drawing to have .25% steps (8 horizontal steps within a single character width)
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
            status=$(df -BM | grep -m 1 $filter | cut -c 11- | tr -d "\n")
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
    du)
        sleeptime=60
        tstamp=$(sleepenh 0)
        limit=$((limitm*60/$sleeptime)) # calculate how many round we need to meet the limit
        tally=$((limit-1))	# tally is internal counting. Starts high to force early newline
        echo "# Refresh/$sleeptime sec, newline/$limit min. Ends on sustained 0M/min changerate"
        filter=${2:-.}
#        echo "$(date +%FT%T) $(du -BM -c $filter | tail -1 ) $filter "
        while true ; do 
            tally=$((tally+1))
            [ ! -d "$filter" ] && echo "" && break
            duout=$(du -BM -c "$filter" 2>/dev/null | tail -1 | tr -d -c "0-9")
            status="${duout}M $filter"
            echo -e -n "\r$(tput el)$(date +%FT%T) $status "
            [ -n "$sizeref" ] && echo -n "(changing at $(echo "scale=1;((($duout-$sizeref)/$tally))" | bc)M/min)"
            # TODO: check if it's done and if so, break the loop and exit
            [ -z "$duout" ] && echo "" && break
            [ $tally -eq $count ] && echo "" && break
            [ $tally -ge $limit ] && [ -n "$sizeref" ] && [ $duout -eq $sizeref ] && echo "" && break
            [ $tally -ge $limit ] && echo "" && sizeref=$duout && tally=0
            tstamp=$(sleepenh $tstamp $sleeptime)
        done


esac

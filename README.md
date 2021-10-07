# watchline

A simpler "watch". Instead of running fullscreen on it's periodic running, it outputs a single line, overwriting the previous, but newlining occasionally to provide history as well. 

Also, rather than running an arbitrary command, it runs builtin options. 
These are:
* mdadm - from an earlier watch_mdadm. This outputs the single line of a rebuild from /proc/mdadm and quits when there is none
* df - this watches a single mountpoint (given as $2, default: /home). Useful if you're filling/clearing a disk

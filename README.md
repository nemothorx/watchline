# watchline

A simpler "watch". Instead of running fullscreen on it's periodic running, it outputs a single line, overwriting the previous, but newlining occasionally to provide history as well. 

Also, rather than running an arbitrary command, it runs builtin subcommands. 
These are:
* mdstat - generates a bar graph from the rebuild information in /proc/mdstat. This quits when there is no active rebuild.
  * also mdstat-old - from an earlier standalone `watch_mdadm` and reuses elements of /proc/mdstat without parsing
* df - this watches a single mountpoint (given as $2, default: /home). Useful if you're filling/clearing a disk
* du - this watches a path (given as $2, default "."). Ends automatically when the date of change is a sustained zero
* uptime - simply run `uptime` forever

AMXX -- BrainBread Stats
=====================

This plugin will save all of your stats to a MySQL server, which multiple servers can use w/o needing to copy players.lvl.

Created by: Johan Eherndahl -- [BrainBread 2 Dev Team](http://bb.brainbread2.eu/)  
Special thanks: Noname -- [Asd2Bam](http://asd2bam.org/)  

How it Works
-----------

Simply copy the `bb_stats.amxx` to your plugins folder and add `bb_stats.amxx` under `configs/plugins.ini` file.  

Now open `configs/sql.cfg` and add the new commands:  
`bb_host			"127.0.0.1"`  
`bb_user			"root"`  
`bb_pass			""`  
`bb_type			"mysql"`  
`bb_dbname			"my_database"`  
`bb_table			"bb_stats"`  
`bb_rank_table			"bb_stats_rank"`  

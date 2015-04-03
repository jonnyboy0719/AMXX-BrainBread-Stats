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

Database setup
-----------

Since version 2.6, all the sql is under `web/database.sql` since the string were to long for AMXX compiler. Simple copy paste it to your PhpMyAdmin, 
or any SQL Manager that you have installed, into its query, and hit run. But make sure its inside a database, else it will throw errors!

Web GUI
-----------

Make sure you install the web gui on your apache folder (you can find all files under `web/` folder) and not copying it to your actual brainbread server!  
You also need to make sure to setup the configurations on the config.php.

Web GUI Demo
-----------

If you want to see how the Web GUI looks like, you can do so by going to our official BrainBread Stats page for our server!  
Demo: [Click here!](http://brainbread2.eu/bb_stats/)

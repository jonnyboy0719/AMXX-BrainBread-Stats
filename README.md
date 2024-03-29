AMXX -- BrainBread Stats
=====================

This plugin will save all of your stats to a MySQL server, which multiple servers can use w/o needing to copy players.lvl.

Created by: Johan Eherndahl -- [Reperio Studios](https://reperio-studios.eu/)  
Special thanks: Noname -- [Asd2Bam](http://asd2bam.org/)  


Commands
-----------
`/bbhelp` - Prints all the available commands on the console  
`/reset` - To reset your skills  
`/fullreset` - To reset your level, skills and experience back to 0 (can't be undone!)  
`/autoload` - Autoloads your points on connection  
`/loadpoints` - To load your points  
`/bbstats or /version` - To show the correction  
`/top10` - Shows the top10 players  
`/rank` - Shows your rank  
`/web` - Shows webstats url  

Server Commands
-----------
`bb_ranking` - This will enable ranking, or simply disable it.  
`bb_gameinfo` - This will enable GameInformation to be overwritten.  
`bb_filerewrite` - This will re-write the player data file if sv_savexp is not on 0  
`bb_webstats_url` - This will display the webstats  

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

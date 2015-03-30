//=============================================================================
//
// This plugin has been created from scratch by Johan "JonnyBoy0719" Ehrendahl.
// Special thanks to noname from asd2bam for helping me with the EXP bug!
//
// Plugin released: 2015-01-06
//
//=============================================================================

#include <amxmodx>
#include <amxmisc>
#include <geoip>
#include <brainbread>
#include <fakemeta>
#include <sqlx>

#define PLUGIN	"BrainBread STATS"
#define AUTHOR	"BrainBread 2 Dev Team"
#define VERSION	"2.5"

new lastfrags[33]
new lastDeadflag[33]
new bool:LoadStatsForPlayer[33];
new bool:LoadStatsForPlayerDone[33];
new bool:HasSpawned[33];
new bool:AutoLoad[33];
new bool:LoadMyPointsOnce[33];
new bool:LoadMyPoints[33];
new bool:enable_ranking=false;
new rank_max = 0
new get_sql_lvl
new Handle:g_hTuple;
new mysqlx_host, mysqlx_user, mysqlx_db, mysqlx_pass, mysqlx_type;
new setranking, rank_name[185], ply_rank, top_rank;

// Need to re-write this so it will read the %s
new const szTables[][] = 
{
	"CREATE TABLE IF NOT EXISTS `bb_stats` (  `authid` varchar(32) NOT NULL,  `name` text,  `exp` text,  `lvl` int(11) DEFAULT NULL,  `skill_hp` int(11) DEFAULT NULL,  `skill_skill` int(11) DEFAULT NULL,  `skill_speed` int(11) DEFAULT NULL,  `points` int(11) DEFAULT NULL,  `autoload` int(11) DEFAULT NULL,  `date` int(11) DEFAULT '1112214021',  `online` varchar(50) DEFAULT 'false',  `country` varchar(50) DEFAULT NULL,  PRIMARY KEY (`authid`)) ENGINE=MyISAM DEFAULT CHARSET=latin1;",
	"CREATE TABLE IF NOT EXISTS `bb_stats_rank` ( `id` bigint(20) NOT NULL DEFAULT '0', `lvl` int(11) DEFAULT NULL, `title` text NOT NULL, PRIMARY KEY (`id`) ) ENGINE=MyISAM DEFAULT CHARSET=latin1;"
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar("bbstats_version", VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	set_cvar_string("bbstats_version", VERSION)

	register_forward(FM_PlayerPreThink,"PluginThink")
	register_forward(FM_GetGameDescription,"GameInformation")  
	set_task(1.0,"PluginThinkLoop",0,"",0,"b")
	set_task(30.0,"PluginAdverts",0,"",0,"b")

	mysqlx_host = register_cvar ("bb_host", "127.0.0.1"); // The host from the db
	mysqlx_user = register_cvar ("bb_user", "root"); // The username from the db login
	mysqlx_pass = register_cvar ("bb_pass", ""); // The password from the db password
	mysqlx_type = register_cvar ("bb_type", "mysql"); // The password from the db type
	mysqlx_db = register_cvar ("bb_dbname", "my_database"); // The database name 
	register_cvar ("bb_table", "bb_stats"); // The table where it will save the information
	register_cvar ("bb_rank_table", "bb_stats_rank"); // The table where it will save the information
	register_cvar ("bb_filerewrite", "0"); // This will re-write the player data file if sv_savexp is not on 0
	register_cvar ("bb_gameinfo", "1"); // This will enable GameInformation to be overwritten.
	register_cvar ("bb_webstats_url", "mysite.net"); // This will display the webstats
	setranking = register_cvar ("bb_ranking", "1"); // This will enable ranking, or simply disable it.

	// Client commands
	register_clcmd("reset", "ResetSkills")
	register_clcmd("autoload", "AutoLoadSkills")
	register_clcmd("loadpoints", "LoadPoints")
	register_clcmd("bbhelp", "BBHelp")
	register_clcmd("bbstats", "StatsVersion")

	register_clcmd("say","hook_say")
	register_clcmd("say_team","hook_say")

	CreateTables()
	PlayerDataFile()
}

public GameInformation()
{
	new bb_getinfo = get_cvar_num ( "bb_gameinfo" )
	if (bb_getinfo>=1)
	{
		new gameinfo[55]
		format( gameinfo, 54, "BrainBread v1.2 || SQL STATS %s", VERSION )
		forward_return( FMV_STRING, gameinfo )
		return FMRES_SUPERCEDE;
	}
	return PLUGIN_HANDLED
}  

public ResetSkills(id)
{
	// Lets get the player's skills and points
	new hps, skill, speed, points;
	hps = bb_get_user_hps(id);
	skill = bb_get_user_skill(id);
	speed = bb_get_user_speed(id);
	points = bb_get_user_points(id);

	// Now, lets convert them into points!
	bb_set_user_points(id, points+(hps+speed+skill));

	// Lets print to the client's chat, so we know we made this action
	new GetPoints = points+(hps+speed+skill)
	client_print ( id, print_chat, "You skills have been reset, and turned them into %d point(s).", GetPoints ) 

	// Now the last bit, lets reset the skills
	bb_set_user_hps(id, 0);
	bb_set_user_skill(id, 0);
	bb_set_user_speed(id, 0);

	return PLUGIN_HANDLED
}

public AutoLoadSkills(id)
{
	new auth[33];
	get_user_authid( id, auth, 32);
	ChangeAutoLoad(id, auth)
	return PLUGIN_HANDLED
}

public LoadPoints(id)
{
	LoadMyPoints[id] = true;
	new auth[33];
	get_user_authid( id, auth, 32);
	LoadLevel(id, auth)
	return PLUGIN_HANDLED
}

public StatsVersion(id)
{
	new Float:SetTime = 8.0
	set_hudmessage(85, 255, 0, 0.02, 0.73, 0, 6.0, SetTime, 0.5, 0.15, -1)
	show_hudmessage(id, "This server is running BB Stats Version %s", VERSION)
	return PLUGIN_HANDLED
}

public ShowWebStats(id)
{
	new WEBPLACE[585]
	get_cvar_string("bb_webstats_url",WEBPLACE,584)
	new Float:SetTime = 8.0
	set_hudmessage(85, 255, 0, 0.02, 0.73, 0, 6.0, SetTime, 0.5, 0.15, -1)
	show_hudmessage(id, "Webstats URL: %s", WEBPLACE )
	client_print ( id, print_chat, "You can visit the webstats at: %s", WEBPLACE )
	return PLUGIN_HANDLED
}

public ShowMyRank(id)
{
	new Position = GetPosition(id);
	ply_rank = Position;
	new auth[33];
	get_user_authid( id, auth, 32);
	LoadLevel(id, auth, false)
	client_print ( id, print_chat, "you are on rank %d of %d with the title: ^"%s^"", ply_rank, top_rank, rank_name )
	return PLUGIN_HANDLED
}

public BBHelp(id, ShowCommands)
{
	// Chat Print
	if ( ShowCommands)
	{
		client_print ( id, print_chat, "The commands have been printed on your console." )
		// Console Print
		client_print ( id, print_console, "==----------[[ BB STATS ]]--------------==" )
		client_print ( id, print_console, "/bbhelp		--		Shows this information" )
		client_print ( id, print_console, "/reset		--		To reset your skills" )
		client_print ( id, print_console, "/autoload	--		Autoloads your points on connection" )
		client_print ( id, print_console, "/loadpoints	--		To load your points" )
		client_print ( id, print_console, "/bbstats		--		Shows current version (%s)", VERSION )
		if ( enable_ranking )
		{
			client_print ( id, print_console, "==----------[[ BB RANKING ]]-------------==" )
			client_print ( id, print_console, "/top10		--		Shows the top10 players" )
			client_print ( id, print_console, "/rank		--		Shows your rank" )
			client_print ( id, print_console, "/web			--		Shows webstats url" )
		}
		client_print ( id, print_console, "==--------------------------------------==" )
	}
	else
	{
		if ( enable_ranking )
			client_print ( id, print_chat, "Available commands: /bbhelp /reset /autoload /loadpoints /rank /top10", VERSION )
		else
			client_print ( id, print_chat, "Available commands: /bbhelp /reset /autoload /loadpoints", VERSION )
	}
	return PLUGIN_HANDLED
}

public hook_say(id)
{
	new said[32]
	read_argv(1, said, 31)
	remove_quotes(said)

	if (equali(said[0], "/reset"))
	{
		ResetSkills(id)
	}
	else if (equali(said[0], "/autoload"))
	{
		AutoLoadSkills(id)
	}
	else if (equali(said[0], "/loadpoints"))
	{
		LoadPoints(id)
	}
	else if (equali(said[0], "/bbhelp"))
	{
		BBHelp(id,true)
	}
	else if (equali(said[0], "/bbstats") || equali(said[0], "/version"))
	{
		StatsVersion(id)
	}

	if ( enable_ranking )
	{
		if (equali(said[0], "/top10"))
		{
			ShowTop10(id)
		}
		else if (equali(said[0], "/rank"))
		{
			ShowMyRank(id)
		}
		else if (equali(said[0], "/web"))
		{
			ShowWebStats(id)
		}
	}

	return PLUGIN_CONTINUE
}

public ShowTop10(id)
{
	static getnum

	// Lets not bug the top10 by adding more when we write /top10
	getnum = 0

	new menuBody[215]
	new len = format(menuBody, 214, "\yBB Stats -- Top10^n\w^n")

	new error[128], errno
	new Handle:info = MySQLx_Init()
	new Handle:sql = SQL_Connect(info, errno, error, 127)

	if (sql == Empty_Handle)
	{
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
	}

	new table[32], name[33]

	get_cvar_string("bb_table", table, 31)

	new Handle:query = SQL_PrepareQuery(sql, "SELECT `name` FROM `%s` ORDER BY `exp` + 0 DESC LIMIT 10", table)

	// This is a pretty basic code, get all people from the database.
	if (!SQL_Execute(query))
	{
		server_print("GetPosition not loaded")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		while (SQL_MoreResults(query))
		{
			SQL_ReadResult(query, 0, name, 32)
			len += format(menuBody[len], 214-len, "#\%d. %s^n", ++getnum, name)

			SQL_NextRow(query);
		}
	}
	SQL_FreeHandle(query);
	SQL_FreeHandle(sql);
	SQL_FreeHandle(info);

	show_menu(id, getnum, menuBody)

	return PLUGIN_CONTINUE;
}

public PluginThinkLoop()
{
	new iPlayers[32],iNum
	get_players(iPlayers,iNum)
	for(new i=0;i<iNum;i++)
	{
		new id=iPlayers[i]
		if(is_user_connected(id))
		{
			if(get_user_frags(id)>lastfrags[id])
			{
				lastfrags[id]=get_user_frags(id)
				
				new auth[33];
				get_user_authid( id, auth, 32);
				SaveLevel(id, auth)
			}
			if (LoadStatsForPlayer[id])
			{
				new auth[33];
				get_user_authid( id, auth, 32);
				LoadLevel(id, auth)
				StatsVersion(id)
				if( setranking )
					ShowStatsOnSpawn(id)
			}
		}
	}

	if ( setranking >= 1 )
	{
		enable_ranking = true;
	}
	else
	{
		enable_ranking = false;
	}
}

public PluginAdverts()
{
	new iPlayers[32],iNum
	get_players(iPlayers,iNum)
	for(new i=0;i<iNum;i++)
	{
		new id=iPlayers[i]
		if(is_user_connected(id))
		{
			new GetRandom = random_num(0, 4)

			switch (GetRandom)
			{
				case 0:
				{
					new Float:SetTime = 8.0
					set_hudmessage(85, 255, 0, 0.02, 0.73, 0, 6.0, SetTime, 0.5, 0.15, -1)
					show_hudmessage(id, "[BB STATS] Want to see what commands you can write? write /bbhelp")
				}
				case 1:
				{
					new Float:SetTime = 6.0
					set_hudmessage(85, 255, 0, 0.02, 0.73, 0, 6.0, SetTime, 0.5, 0.15, -1)
					show_hudmessage(id, "[BB STATS] Want to reset your points? write /reset")
				}
				case 2:
				{
					new Float:SetTime = 8.0
					set_hudmessage(85, 255, 0, 0.02, 0.73, 0, 6.0, SetTime, 0.5, 0.15, -1)
					show_hudmessage(id, "[BB STATS] This server is using BrainBread Stats Version %s by JonnyBoy0719", VERSION)
				}
				
				default:
				{
				}
			}
		}
	}
}

public PlayerDataFile()
{
	new filename[256]
	new player_data[64]
	new bb_filerewrite = get_cvar_num ( "bb_filerewrite" )
	get_cvar_string("sv_playerinfofile",player_data,63)
	format( filename, 255, "%s", player_data )
	if (file_exists(filename) && bb_filerewrite == 0)
	{
		log_amx("Player Data file was found, please set sv_savexp to ^"0^" to make sure it doesn't read %s. The players will not load their SQL stats until the file is removed/renamed, to override this, enable bb_filerewrite.", filename)
	}
}

// ============================================================//
//                          [~ Saving datas ~]			       //
// ============================================================//
stock Handle:MySQLx_Init(timeout = 0)
{
	static szHost[64], szUser[32], szPass[32], szDB[128];
	static get_type[12], set_type[12];
	
	get_pcvar_string( mysqlx_host, szHost, 63 );
	get_pcvar_string( mysqlx_user, szUser, 31 );
	get_pcvar_string( mysqlx_type, set_type, 11);
	get_pcvar_string( mysqlx_pass, szPass, 31 );
	get_pcvar_string( mysqlx_db, szDB, 127 );
	
	SQL_GetAffinity(get_type, 12);
	
	if (!equali(get_type, set_type))
	{
		if (!SQL_SetAffinity(set_type))
		{
			log_amx("Failed to set affinity from %s to %s.", get_type, set_type);
		}
	}
	
	g_hTuple = SQL_MakeDbTuple( szHost, szUser, szPass, szDB );
	
	return SQL_MakeDbTuple( szHost, szUser, szPass, szDB, timeout );
}
public CreateTables()
{
	new error[128], errno

	new Handle:info = MySQLx_Init()
	new Handle:sql = SQL_Connect(info, errno, error, 127)

	if (sql == Empty_Handle)
	{
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
	}

	for ( new i = 0; i < sizeof szTables; i++ )
	{
		SQL_ThreadQuery( g_hTuple, "QueryCreateTable", szTables[i]);
	}

	return PLUGIN_HANDLED;
}
public QueryCreateTable( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iDataSize, Float:fQueueTime ) 
{ 
	if( iFailState == TQUERY_CONNECT_FAILED 
	|| iFailState == TQUERY_QUERY_FAILED ) 
	{ 
		log_amx( "%s", szError ); 
		
		return;
	} 
}

public client_connect(id)
{
	LoadStatsForPlayer[id] = false;
	LoadStatsForPlayerDone[id] = false;
	LoadMyPoints[id] = false;
	HasSpawned[id] = false;
	LoadMyPointsOnce[id] = false;
	// Connected
	new players[32],num,i;
	get_players(players, num)
	for (i=0; i<num; i++)
	{
		if (is_user_connected(players[i]) && !is_user_bot(players[i]))
		{
			new plyname[32], auth[33]
			get_user_authid(id, auth, 32)
			get_user_name(id, plyname, 31)

			if (is_user_admin(players[i]))
			{
				client_print ( players[i], print_chat, "Player %s <^"%s^"> has joined the game", plyname, auth )
			}
			else
			{
				client_print ( players[i], print_chat, "Player %s has joined the game", plyname )
			}
		}
	}
}

public PluginThink(id)
{
	new deadflag=pev(id,pev_deadflag)
	if(!deadflag&&lastDeadflag[id])
	{
		OnPlayerSpawn(id)
	}
	lastDeadflag[id]=deadflag
}

public OnPlayerSpawn(id) {
	if(!LoadStatsForPlayerDone[id])
	{
		HelpOnConnect(id)
		new auth[33];
		get_user_authid( id, auth, 32);
		CreateStats(id, auth)
	}
} 

public HelpOnConnect(id)
{
	new hostname[101], plyname[32]
	get_user_name(0,hostname,100)
	get_user_name(id, plyname, 31)

	if ( enable_ranking )
	{
		new Position = GetPosition(id);
		ply_rank = Position;
		client_print ( id, print_chat, "Welcome %s to %s! You are on rank %d.", plyname, hostname, ply_rank  )
	}
	else
		client_print ( id, print_chat, "Welcome %s to %s!", plyname, hostname )

	BBHelp(id,false)
}

public ShowStatsOnSpawn(id)
{
	new players[32],num,i;
	get_players(players, num)
	for (i=0; i<num; i++)
	{
		if (is_user_connected(players[i]) && !is_user_bot(players[i]))
		{
			new plyname[32]
			get_user_name(id, plyname, 31)
			client_print ( players[i], print_chat, "%s is %s. Ranked %d of %d.", plyname, rank_name, ply_rank, top_rank )
		}
	}
}

public client_disconnect(id)
{
	if(HasSpawned[id])
	{
		new auth[33];
		get_user_authid( id, auth, 32);
		SaveLevel(id, auth)
		SaveDate(auth);
		UpdateConnection(id, auth,false);
		HasSpawned[id] = false;
	}
	LoadStatsForPlayer[id] = false;
	LoadStatsForPlayerDone[id] = false;
	LoadMyPoints[id] = false;
	LoadMyPointsOnce[id] = false;
	// Disconnected
	new players[32],num,i;
	get_players(players, num)
	for (i=0; i<num; i++)
	{
		if (is_user_connected(players[i]) && !is_user_bot(players[i]))
		{
			new plyname[32], auth[33]
			get_user_authid(id, auth, 32)
			get_user_name(id, plyname, 31)

			if (is_user_admin(players[i]))
			{
				client_print ( players[i], print_chat, "Player %s <^"%s^"> has left the game", plyname, auth )
			}
			else
			{
				client_print ( players[i], print_chat, "Player %s has left the game", plyname )
			}
		}
	}
}

SaveLevel(id, auth[])
{ 
	new error[128], errno

	new Handle:info = MySQLx_Init()
	new Handle:sql = SQL_Connect(info, errno, error, 127)

	if (sql == Empty_Handle)
	{
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
	}

	new table[32]

	get_cvar_string("bb_table", table, 31)

	new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE (`authid` = '%s')", table, auth)

	if (!SQL_Execute(query))
	{
		server_print("query not saved")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		new hps, skill, level, speed, points;
		hps = bb_get_user_hps(id);
		skill = bb_get_user_skill(id);
		level = bb_get_user_level(id);
		speed = bb_get_user_speed(id);
		points = bb_get_user_points(id);
		new Float:GetEXP = bb_get_user_exp(id)
/*
		server_print("Saved stats:")
		server_print("ID: %s", id)
		server_print("LVL: %d", level)
		server_print("EXP: %f", GetEXP)
		server_print("HPS: %d", hps)
		server_print("SKILL: %d", skill)
		server_print("SPEED: %d", speed)
		server_print("POINTS: %d", points)
*/
		new plyname[32]
		get_user_name(id,plyname,31)
		SQL_QueryAndIgnore(sql, "UPDATE `%s` SET `exp` = %i, `lvl` = %d, `skill_hp` = %d, `skill_skill` = %d, `skill_speed` = %d, `points` = %d WHERE `authid` = '%s';", table, floatround(GetEXP), level, hps, skill, speed, points, auth )
	}

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}

UpdateConnection(client, auth[],IsOnline=true)
{
	new error[128], errno
	new countrycode[3]
	new ip[33][32]

	new Handle:info = MySQLx_Init()
	new Handle:sql = SQL_Connect(info, errno, error, 127)

	if (sql == Empty_Handle)
	{
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
	}

	if(IsOnline)
	{
		get_user_ip(client,ip[client],31)
		geoip_code2(ip[client],countrycode)
	}

	new table[32]

	get_cvar_string("bb_table", table, 31)

	new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE (`authid` = '%s')", table, auth)

	if (!SQL_Execute(query))
	{
		server_print("query not saved")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		if (IsOnline)
			SQL_QueryAndIgnore(sql, "UPDATE `%s` SET `online` = 'true',`country` = '%s' WHERE `authid` = '%s';", table, countrycode, auth )
		else
			SQL_QueryAndIgnore(sql, "UPDATE `%s` SET `online` = 'false' WHERE `authid` = '%s';", table, auth )
	}

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}

SaveDate(auth[])
{
	new error[128], errno

	new Handle:info = MySQLx_Init()
	new Handle:sql = SQL_Connect(info, errno, error, 127)

	if (sql == Empty_Handle)
	{
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
	}

	new table[32]

	get_cvar_string("bb_table", table, 31)

	new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE (`authid` = '%s')", table, auth)

	if (!SQL_Execute(query))
	{
		server_print("query not saved")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		SQL_QueryAndIgnore(sql, "UPDATE `%s` SET `date` = UNIX_TIMESTAMP(NOW()) WHERE `authid` = '%s';", table, auth )
	}

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}

ChangeAutoLoad(id, auth[])
{ 
	new error[128], errno

	new Handle:info = MySQLx_Init()
	new Handle:sql = SQL_Connect(info, errno, error, 127)

	if (sql == Empty_Handle)
	{
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
	}

	new table[32], sql_autload, AutoLoadStatus[32]
	
	if (AutoLoad[id])
	{
		sql_autload = 0;
		AutoLoad[id] = false;
		AutoLoadStatus = "disabled";
	}
	else
	{
		sql_autload = 1;
		AutoLoad[id] = true;
		AutoLoadStatus = "Enabled";
	}

	client_print ( id, print_chat, "You now have Skills AutoLoad %s.", AutoLoadStatus )

	get_cvar_string("bb_table", table, 31)

	new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE (`authid` = '%s')", table, auth)

	if (!SQL_Execute(query))
	{
		server_print("query not saved")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		SQL_QueryAndIgnore(sql, "UPDATE `%s` SET `autoload` = %d WHERE `authid`='%s';", table, sql_autload, auth )
	}

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}

LoadLevel(id, auth[], LoadMyStats = true)
{
	// This will fix some minor bugs when joining.
	rank_max = 0
	new error[128], errno
	new filename[256]
	new player_data[64]
	new bb_filerewrite = get_cvar_num ( "bb_filerewrite" )
	get_cvar_string("sv_playerinfofile",player_data,63)

	format( filename, 255, "%s", player_data )

	if (file_exists(filename) && bb_filerewrite == 0)
	{
		log_amx("<^"%s^"> from %s has been converted to the SQL.", auth, filename)
		SaveLevel(id, auth)
		LoadStatsForPlayer[id] = false;
		LoadStatsForPlayerDone[id] = true;
		HasSpawned[id] = true;
	}
	else
	{
		new Handle:info = MySQLx_Init()
		new Handle:sql = SQL_Connect(info, errno, error, 127)

		if (sql == Empty_Handle)
		{
			server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
		}

		new table[32], table2[32]

		get_cvar_string("bb_table", table, 31)
		get_cvar_string("bb_rank_table", table2, 31)

		new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE (`authid` = '%s')", table, auth)
		new Handle:query_g = SQL_PrepareQuery(sql, "SELECT `authid` FROM `%s`", table)

		// This is a pretty basic code, get all people from the database.
		if (!SQL_Execute(query_g))
		{
			server_print("query not loaded")
			SQL_QueryError(query_g, error, 127)
			server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
		} else {
			while (SQL_MoreResults(query_g))
			{
				rank_max++;
				SQL_NextRow(query_g);
			}
		}
		SQL_FreeHandle(query_g);

		if (!SQL_Execute(query))
		{
			server_print("query not loaded")
			SQL_QueryError(query, error, 127)
			server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
		} else {
			server_print("loaded stats for:^nID: ^"%s^"", auth)

			LoadStatsForPlayer[id] = false;
			LoadStatsForPlayerDone[id] = true;
			HasSpawned[id] = true;

			new hps, skill, lvl, speed, points, exp, autoload;
			exp = SQL_FieldNameToNum(query, "exp");
			lvl = SQL_FieldNameToNum(query, "lvl");
			hps = SQL_FieldNameToNum(query, "skill_hp");
			skill = SQL_FieldNameToNum(query, "skill_skill");
			speed = SQL_FieldNameToNum(query, "skill_speed");
			points = SQL_FieldNameToNum(query, "points");
			autoload = SQL_FieldNameToNum(query, "autoload");

			new sql_lvl, sql_exp, sql_hps, sql_skill, sql_speed, sql_points, sql_autoload;

			while (SQL_MoreResults(query))
			{
				sql_lvl = SQL_ReadResult(query, lvl);
				sql_exp = SQL_ReadResult(query, exp);
				sql_hps = SQL_ReadResult(query, hps);
				sql_skill = SQL_ReadResult(query, skill);
				sql_speed = SQL_ReadResult(query, speed);
				sql_points = SQL_ReadResult(query, points);
				sql_autoload = SQL_ReadResult(query, autoload);
				get_sql_lvl = sql_lvl

				if (LoadMyStats)
				{
					// The player stats, only shows on the console once.
					//*
					server_print("-------")
					server_print("LVL: %d", sql_lvl);
					server_print("EXP: %f", float(sql_exp));
					server_print("HPS: %d", sql_hps);
					server_print("SKILL: %d", sql_skill);
					server_print("SPEED: %d", sql_speed);
					server_print("POINTS: %d", sql_points);
					server_print("AUTOLOAD: %d", sql_autoload);
					server_print("-------")
					//*/
					SaveDate(auth);
					UpdateConnection(id, auth);

					// We don't want to make this exploitable, so if autoload is enabled, you can't die again, and if its disabled, or if you write /loadpoints.
					if(sql_autoload == 1 || LoadMyPoints[id])
					{
						AutoLoad[id] = true;
						if(!LoadMyPointsOnce[id])
							fakedamage(id, "Z0mbeh", 999999.0, DMG_BULLET);
						if (LoadMyPoints[id])
						{
							LoadMyPoints[id] = false;
							LoadMyPointsOnce[id] = true;
						}
						if (sql_autoload == 1)
							LoadMyPointsOnce[id] = true;
					}
					else
						AutoLoad[id] = false;

					bb_set_user_level(id, sql_lvl);
					bb_set_user_exp(id, float(sql_exp));
					bb_set_user_hps(id, sql_hps);
					bb_set_user_skill(id, sql_skill);
					bb_set_user_speed(id, sql_speed);
					bb_set_user_points(id, sql_points);
				}

				SQL_NextRow(query);
			}
		}

		// This will read the player LVL and then give him the title he needs
		new Handle:query2 = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE `lvl` <= (%d) and `lvl` ORDER BY abs(`lvl` - %d) LIMIT 1", table2, get_sql_lvl, get_sql_lvl)
		if (!SQL_Execute(query2))
		{
			server_print("query not loaded")
			SQL_QueryError(query2, error, 127)
			server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
		} else {
			while (SQL_MoreResults(query2))
			{
				// Not the best code, this needs improvements...
				new ranktitle[185]
				SQL_ReadResult(query2, 1, ranktitle, 31)
				// This only gets the max players on the database
				top_rank = rank_max
				// This reads the players EXP, and then checks with other players EXP to get the players rank
				new Position = GetPosition(id);
				ply_rank = Position
				// Gets your current title of your level
				rank_name = ranktitle
				SQL_NextRow(query2);
			}
		}

		SQL_FreeHandle(query2);
		SQL_FreeHandle(query);
		SQL_FreeHandle(sql);
		SQL_FreeHandle(info);
	}
}

GetPosition(id)
{
	static Position;

	// If used, lets reset it
	Position = 0;

	new error[128], errno
	new Handle:info = MySQLx_Init()
	new Handle:sql = SQL_Connect(info, errno, error, 127)

	if (sql == Empty_Handle)
	{
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
	}

	new table[32]

	get_cvar_string("bb_table", table, 31)

	new Handle:query = SQL_PrepareQuery(sql, "SELECT `authid` FROM `%s` ORDER BY `exp` + 0 DESC", table)

	// This is a pretty basic code, get all people from the database.
	if (!SQL_Execute(query))
	{
		server_print("GetPosition not loaded")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		while (SQL_MoreResults(query))
		{
			Position++
			new authid[33]
			SQL_ReadResult(query, 0, authid, 32)
			new auth_self[33];
			get_user_authid(id, auth_self, 32);
			if (equal(auth_self, authid))
				return Position;
			SQL_NextRow(query);
		}
	}
	SQL_FreeHandle(query);
	SQL_FreeHandle(sql);
	SQL_FreeHandle(info);
	return 0;
}

CreateStats(id, auth[])
{
	new error[128], errno

	new Handle:info = MySQLx_Init()
	new Handle:sql = SQL_Connect(info, errno, error, 127)

	if (sql == Empty_Handle)
	{
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
	}

	new table[32]

	get_cvar_string("bb_table", table, 31)

	new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE (`authid` = '%s')", table, auth)

	if (!SQL_Execute(query))
	{
		server_print("query not saved")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else if (SQL_NumResults(query)) {
		// If we already created one, lets continnue
		LoadStatsForPlayer[id] = true;
	} else {
		console_print(id, "Adding to database:^nID: ^"%s^"", auth)
		server_print("Adding to database:^nID: ^"%s^"", auth)

		new plyname[32]
		get_user_name(id,plyname,31)

		SQL_QueryAndIgnore(sql, "INSERT INTO `%s` (`authid`, `name`, `lvl`, `skill_hp`, `skill_skill`, `skill_speed`, `points`) VALUES ('%s', '%s' 0, 0, 0, 0, 0)", table, auth, plyname)
		LoadStatsForPlayer[id] = true;
	}

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}
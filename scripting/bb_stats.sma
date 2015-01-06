#include <amxmodx>
#include <brainbread>
#include <fakemeta>
#include <sqlx>
#include <engine_stocks>

#define PLUGIN	"BrainBread STATS"
#define AUTHOR	"BrainBread 2 Dev Team"
#define VERSION	"1.2"

new lastfrags[33]
new lastDeadflag[33]
new bool:LoadStatsForPlayer[33];
new bool:LoadStatsForPlayerDone[33];
new bool:HasSpawned[33];
new bool:AutoLoad[33];
new bool:LoadMyPoints[33];

new Handle:g_hTuple;
new mysqlx_host, mysqlx_user, mysqlx_db, mysqlx_pass, mysqlx_type;

// Need to re-write this so it will read the %s
new const szTables[][] = 
{
	"CREATE TABLE IF NOT EXISTS `bb_stats` ( `authid` varchar(32) NOT NULL, `exp` TEXT DEFAULT NULL, `lvl` int(11) DEFAULT NULL, `skill_hp` int(11) DEFAULT NULL, `skill_skill` int(11) DEFAULT NULL, `skill_speed` int(11) DEFAULT NULL, `points` int(11) DEFAULT NULL, `autoload` int(11) DEFAULT NULL, PRIMARY KEY (`authid`) ) ENGINE=MyISAM DEFAULT CHARSET=latin1;"
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar("bbstats_version", VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	set_cvar_string("bbstats_version", VERSION)

	register_forward(FM_PlayerPreThink,"PluginThink")
	set_task(1.0,"PluginThinkLoop",0,"",0,"b")

	mysqlx_host = register_cvar ("bb_host", "127.0.0.1"); // The host from the db
	mysqlx_user = register_cvar ("bb_user", "root"); // The username from the db login
	mysqlx_pass = register_cvar ("bb_pass", ""); // The password from the db password
	mysqlx_type = register_cvar ("bb_type", "mysql"); // The password from the db type
	mysqlx_db = register_cvar ("bb_dbname", "my_database"); // The database name 
	register_cvar ("bb_table", "bb_stats"); // The table where it will save the information
	register_cvar ("bb_filerewrite", "0"); // This will re-write the player data file if sv_savexp is not on 0
	
	// Client commands
	register_clcmd("reset", "ResetSkills")
	register_clcmd("autoload", "AutoLoadSkills")
	register_clcmd("loadpoints", "LoadPoints")
	register_clcmd("say","hook_say")
	register_clcmd("say_team","hook_say")

	CreateTables()
	PlayerDataFile()
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
	
	return PLUGIN_CONTINUE
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
		new auth[33];
		get_user_authid( id, auth, 32);
		CreateStats(id, auth)
	}
} 

public client_disconnect(id)
{
	if(HasSpawned[id])
	{
		new auth[33];
		get_user_authid( id, auth, 32);
		SaveLevel(id, auth)
		HasSpawned[id] = false;
	}
	LoadStatsForPlayer[id] = false;
	LoadStatsForPlayerDone[id] = false;
	LoadMyPoints[id] = false;
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
		new hps, skill, level, speed, points, sql_autload;
		hps = bb_get_user_hps(id);
		skill = bb_get_user_skill(id);
		level = bb_get_user_level(id);
		speed = bb_get_user_speed(id);
		points = bb_get_user_points(id);
		new Float:GetEXP = bb_get_user_exp(id)

		if (AutoLoad[id])
		{
			sql_autload = 1;
		}
		else
		{
			sql_autload = 0;
		}
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
		SQL_QueryAndIgnore(sql, "REPLACE INTO `%s` (`authid`, `exp`, `lvl`, `skill_hp`, `skill_skill`, `skill_speed`, `points`, `autoload`) VALUES ('%s', %i, %d, %d, %d, %d, %d, %d);", table, auth, floatround(GetEXP), level, hps, skill, speed, points, sql_autload )
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

	new table[32], sql_autload
	
	if (AutoLoad[id])
	{
		sql_autload = 0;
		AutoLoad[id] = false;
	}
	else
	{
		sql_autload = 1;
		AutoLoad[id] = true;
	}

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

LoadLevel(id, auth[])
{
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
	}
	else
	{
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
			server_print("loaded stats for:^nID: ^"%s^"", auth)
			
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
				LoadStatsForPlayer[id] = false;
				LoadStatsForPlayerDone[id] = true;
				HasSpawned[id] = true;

				sql_lvl = SQL_ReadResult(query, lvl);
				sql_exp = SQL_ReadResult(query, exp);
				sql_hps = SQL_ReadResult(query, hps);
				sql_skill = SQL_ReadResult(query, skill);
				sql_speed = SQL_ReadResult(query, speed);
				sql_points = SQL_ReadResult(query, points);
				sql_autoload = SQL_ReadResult(query, autoload);

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

				if(sql_autoload == 1 || LoadMyPoints[id])
				{
					fakedamage(id, "Z0mbeh", 999999.0, DMG_BULLET);
					AutoLoad[id] = true;
					if (LoadMyPoints[id])
						LoadMyPoints[id] = false;
				}
				else
					AutoLoad[id] = false;

				bb_set_user_level(id, sql_lvl);
				bb_set_user_exp(id, float(sql_exp));
				bb_set_user_hps(id, sql_hps);
				bb_set_user_skill(id, sql_skill);
				bb_set_user_speed(id, sql_speed);
				bb_set_user_points(id, sql_points);

				SQL_NextRow(query);
			}
		}

		SQL_FreeHandle(query);
		SQL_FreeHandle(sql);
		SQL_FreeHandle(info);
	}
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

		SQL_QueryAndIgnore(sql, "INSERT INTO `%s` (`authid`, `lvl`, `skill_hp`, `skill_skill`, `skill_speed`, `points`) VALUES ('%s', 0, 0, 0, 0, 0)", table, auth)
		LoadStatsForPlayer[id] = true;
	}

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}
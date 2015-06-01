//=============================================================================
//
// This plugin has been created from scratch by Johan "JonnyBoy0719" Ehrendahl.
// Special thanks to noname from asd2bam for helping me with the EXP bug!
//
// Plugin released: 2015-01-06
//
//=============================================================================

//------------------
//	Include Files
//------------------

#include <amxmodx>
#include <amxmisc>
#include <geoip>
#include <brainbread>
#include <fakemeta>
#include <sqlx>
#include <fun>

//------------------
//	Defines
//------------------

#define PLUGIN	"BrainBread STATS"
#define AUTHOR	"Reperio Studios"
#define VERSION	"3.0"

//------------------
//	Handles & more
//------------------

new const lvlupsnd[] = "sound/misc/levelup.wav" 
new lastfrags[33]
new lastDeadflag[33]
new bool:LoadStatsForPlayer[33]
new bool:LoadStatsForPlayerDone[33]
new bool:HasSpawned[33]
new bool:AutoLoad[33]
new bool:LoadMyPointsOnce[33]
new bool:LoadMyPoints[33]
new bool:enable_ranking=false
new g_oldangles[33][3]
new rank_max = 0
new get_sql_lvl[33]
// Global stuff
new gb_sql_kills,gb_sql_kills_player,gb_sql_gametime
new mysqlx_host, mysqlx_user, mysqlx_db, mysqlx_pass, mysqlx_type
new setranking, rank_name[185], ply_rank, top_rank

//------------------
//	plugin_init()
//------------------

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar("bbstats_version", VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	
	set_cvar_string("bbstats_version", VERSION)

	register_forward(FM_PlayerPreThink,"PluginThink")
	register_forward(FM_GetGameDescription,"GameInformation")
	
	register_event("DeathMsg", "EVENT_PlayerDeath", "a")

	set_task(1.0,"CheckGameTime",_,_,_,"b")
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
	register_clcmd("fullreset", "FullReset")
	register_clcmd("autoload", "AutoLoadSkills")
	register_clcmd("loadpoints", "LoadPoints")
	register_clcmd("bbhelp", "BBHelp")
	register_clcmd("bbstats", "StatsVersion")

	register_clcmd("say","hook_say")
	register_clcmd("say_team","hook_say")

	PlayerDataFile()
}

//------------------
//	plugin_precache()
//------------------

public plugin_precache()
{
	precache_sound("misc/levelup.wav")
}

//------------------
//	EVENT_PlayerDeath()
//------------------

public EVENT_PlayerDeath()
{
	new killer = read_data(1);	// Killer
	new victim = read_data(2);	// Victim
//	new weapon = read_data(3);	// Weapon (doesn't work on BrainBread)

	if (killer == victim)
		return;
	
	// If the ID is 65, then its the zombie.
	// If the ID is 0, then its the server.
	if (victim == 0 || victim == 65)
		return;
	if (killer == 0 || killer == 65)
		return;
	
	// If its a player we are killing, and not a zombie
	if (!is_user_bot(victim) && !is_user_hltv(victim) || is_user_alive(killer) && !is_user_bot(killer) && !is_user_hltv(killer))
	{
		new auth[33];
		get_user_authid( killer, auth, 32);
		SaveLevel(killer, auth);
		SaveKills(auth,"human_player");
	}
}

//------------------
//	GameInformation()
//------------------

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

//------------------
//	ResetSkills()
//------------------

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

//------------------
//	FullReset()
//------------------

public FullReset(id)
{
	// Lets print the old stats
	new hps, skill, level, speed, points;
	hps = bb_get_user_hps(id);
	skill = bb_get_user_skill(id);
	level = bb_get_user_level(id);
	speed = bb_get_user_speed(id);
	points = bb_get_user_points(id);
	new Float:exp = bb_get_user_exp(id)

	client_print ( id, print_console, "==----------[[ ORIGINAL STATS ]]--------------==" )
	client_print ( id, print_console, "LEVEL: %d", level )
	client_print ( id, print_console, "EXP: %f", exp )
	client_print ( id, print_console, "HPS: %d", hps )
	client_print ( id, print_console, "SKILL: %d", skill )
	client_print ( id, print_console, "SPEED: %d", speed )
	client_print ( id, print_console, "POINTS: %d", points )
	client_print ( id, print_console, "==----------[[ ORIGINAL STATS ]]--------------==" )

	// Now lets reset everything!
	bb_set_user_points(id, 0);
	bb_set_user_hps(id, 0);
	bb_set_user_skill(id, 0);
	bb_set_user_speed(id, 0);
	bb_set_user_level(id, 0);
	bb_set_user_exp(id, 0.0);

	// Lets print to the client's chat, so we know we made this action
	client_print ( id, print_chat, "You have made a full reset of your skills, if this was a mistake, check the console for the original stats." ) 

	return PLUGIN_HANDLED
}

//------------------
//	AutoLoadSkills()
//------------------

public AutoLoadSkills(id)
{
	new auth[33];
	get_user_authid( id, auth, 32);
	ChangeAutoLoad(id, auth)
	return PLUGIN_HANDLED
}

//------------------
//	LoadPoints()
//------------------

public LoadPoints(id)
{
	LoadMyPoints[id] = true;
	new auth[33];
	get_user_authid( id, auth, 32);
	LoadLevel(id, auth)
	return PLUGIN_HANDLED
}

//------------------
//	StatsVersion()
//------------------

public StatsVersion(id)
{
	new Float:SetTime = 8.0
	set_hudmessage(85, 255, 0, 0.02, 0.73, 0, 6.0, SetTime, 0.5, 0.15, -1)
	show_hudmessage(id, "This server is running BB Stats Version %s", VERSION)
	return PLUGIN_HANDLED
}

//------------------
//	ShowWebStats()
//------------------

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

//------------------
//	AnnounceNewLevel()
//------------------

public AnnounceNewLevel(id, newlvl)
{
	new Position = GetPosition(id);
	ply_rank = Position;
	// Lets call the GetCurrentRankTitle(id) to make sure we get the title for the player
	GetCurrentRankTitle(id);

	new players[32],num,i;
	get_players(players, num)
	for (i=0; i<num; i++)
	{
		if (is_user_connected(players[i]) && !is_user_bot(players[i]))
		{
			new plyname[32], auth[33]
			
			get_user_authid(id, auth, 32)
			get_user_name(id, plyname, 31)
			
			new Float:SetTime = 10.0
			set_hudmessage(85, 255, 0, 0.02, 0.73, 0, 6.0, SetTime, 0.5, 0.15, -1)
			client_cmd( players[i] , "spk ^"%s^"", lvlupsnd ) 
			
			show_hudmessage ( players[i], "%s has leveled up to %d! Rank: %d of %d with the title: ^"%s^"", plyname, newlvl, ply_rank, top_rank, rank_name )
			client_print ( players[i], print_chat, "%s has leveled up to %d! Rank: %d of %d with the title: ^"%s^"", plyname, newlvl, ply_rank, top_rank, rank_name )
		}
	}
	return PLUGIN_HANDLED
}

//------------------
//	ShowMyRank()
//------------------

public ShowMyRank(id)
{
	new Position = GetPosition(id);
	ply_rank = Position;
	// Lets call the GetCurrentRankTitle(id) to make sure we get the title for the player
	GetCurrentRankTitle(id);
	new auth[33];
	get_user_authid( id, auth, 32);
	LoadLevel(id, auth, false)
	client_print ( id, print_chat, "you are on rank %d of %d with the title: ^"%s^"", ply_rank, top_rank, rank_name )
	return PLUGIN_HANDLED
}

//------------------
//	BBHelp()
//------------------

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
		client_print ( id, print_console, "/fullreset	--		To reset your level, skills and experience back to 0 (can't be undone!)" )
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

//------------------
//	hook_say()
//------------------

public hook_say(id)
{
	new said[32]
	read_argv(1, said, 31)
	remove_quotes(said)

	if (equali(said[0], "/reset"))
	{
		ResetSkills(id)
	}
	else if (equali(said[0], "/fullreset"))
	{
		FullReset(id)
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

//------------------
//	ShowTop10()
//------------------

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

//------------------
//	CheckGameTime()
//------------------
public CheckGameTime() {
	for (new i = 1; i <= get_maxplayers(); i++) {
		if (is_user_alive(i) && is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i)) {
			new newangle[3];
			get_user_origin(i, newangle);

			if ( newangle[0] == g_oldangles[i][0] && newangle[1] == g_oldangles[i][1] && newangle[2] == g_oldangles[i][2] ) {
				// Don't do anything, because we don't want to give them any gametime points for standing still >:c
			} else {
				g_oldangles[i][0] = newangle[0];
				g_oldangles[i][1] = newangle[1];
				g_oldangles[i][2] = newangle[2];
				
				new auth[33];
				get_user_authid( i, auth, 32);
				SaveGameTime(auth);
			}
		}
	}
	return PLUGIN_HANDLED
}

//------------------
//	PluginThinkLoop()
//------------------

public PluginThinkLoop()
{
	new iPlayers[32],iNum
	get_players(iPlayers,iNum)
	for(new i=0;i<iNum;i++)
	{
		new id=iPlayers[i]
		if(is_user_connected(id))
		{
			new GetCurrentLevel = bb_get_user_level(id);
			if(get_user_frags(id)>lastfrags[id])
			{
				lastfrags[id]=get_user_frags(id)
				
				new auth[33];
				get_user_authid( id, auth, 32);
				SaveLevel(id, auth)
				SaveKills(auth)
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
			if(HasSpawned[id])
			{
				if(is_user_alive(id) && GetCurrentLevel > get_sql_lvl[id])
				{
					AnnounceNewLevel(id, GetCurrentLevel);
					get_sql_lvl[id] = GetCurrentLevel;
				}
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

//------------------
//	PluginAdverts()
//------------------

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

//------------------
//	PlayerDataFile()
//------------------

public PlayerDataFile()
{
	new filename[256]
	new player_data[64]
	new bb_filerewrite = get_cvar_num ( "bb_filerewrite" )
	get_cvar_string("sv_playerinfofile",player_data,63)
	format( filename, 255, "%s", player_data )
	if (file_exists(filename))
	{
		if (bb_filerewrite == 0)
			log_amx("Player Data file was found, please set sv_savexp to ^"0^" to make sure it doesn't read %s. The players will not load their SQL stats until the file is removed/renamed, to override this, enable bb_filerewrite.", filename)
	}
}

//------------------
//	client_connect()
//------------------

public client_connect(id)
{
	LoadStatsForPlayer[id] = false;
	LoadStatsForPlayerDone[id] = false;
	LoadMyPoints[id] = false;
	HasSpawned[id] = false;
	LoadMyPointsOnce[id] = false;
	get_sql_lvl[id] = 0;
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

//------------------
//	PluginThink()
//------------------

public PluginThink(id)
{
	new deadflag=pev(id,pev_deadflag)
	if(!deadflag&&lastDeadflag[id])
	{
		OnPlayerSpawn(id)
	}
	lastDeadflag[id]=deadflag
}

//------------------
//	OnPlayerSpawn()
//------------------

public OnPlayerSpawn(id) {
	if(!LoadStatsForPlayerDone[id])
	{
		HelpOnConnect(id)
		new auth[33];
		get_user_authid( id, auth, 32);
		CreateStats(id, auth)
	}
} 

//------------------
//	HelpOnConnect()
//------------------

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

//------------------
//	ShowStatsOnSpawn()
//------------------

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

//------------------
//	client_disconnect()
//------------------

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

// ============================================================//
//                          [~ Saving datas ~]			       //
// ============================================================//

//------------------
//	MySQLx_Init()
//------------------
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
	
	return SQL_MakeDbTuple( szHost, szUser, szPass, szDB, timeout );
}

//------------------
//	QueryCreateTable()
//------------------

public QueryCreateTable( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iDataSize, Float:fQueueTime ) 
{ 
	if( iFailState == TQUERY_CONNECT_FAILED 
	|| iFailState == TQUERY_QUERY_FAILED ) 
	{ 
		log_amx( "%s", szError ); 
		
		return;
	} 
}

//------------------
//	SaveLevel()
//------------------

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
		SQL_QueryAndIgnore(sql, "UPDATE `%s` SET `name` = '%s', `exp` = %i, `lvl` = %d, `skill_hp` = %d, `skill_skill` = %d, `skill_speed` = %d, `points` = %d WHERE `authid` = '%s';", table, plyname, floatround(GetEXP), level, hps, skill, speed, points, auth )
	}

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}

//------------------
//	UpdateConnection()
//------------------

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
		geoip_code2_ex(ip[client],countrycode)
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

//------------------
//	SaveKills()
//------------------

SaveKills(auth[],IsType[]="")
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
	
	UpdateKills(auth)
	
	new set_frags = 1 + gb_sql_kills
	new set_player_kills = 1 + gb_sql_kills_player

	new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE (`authid` = '%s')", table, auth)

	if (!SQL_Execute(query))
	{
		server_print("query not saved")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		SQL_QueryAndIgnore(sql, "UPDATE `%s` SET `kills` = '%d' WHERE `authid` = '%s';", table, set_frags, auth )
		if (equal(IsType,"human_player"))
			SQL_QueryAndIgnore(sql, "UPDATE `%s` SET `kills_player` = '%d' WHERE `authid` = '%s';", table, set_player_kills, auth );
	}

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}

//------------------
//	UpdateKills()
//------------------

UpdateKills(auth[])
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
		server_print("query not loaded")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		new kills;
		new kills_player;
		
		kills = SQL_FieldNameToNum(query, "kills");
		kills_player = SQL_FieldNameToNum(query, "kills_player");

		new sql_kills;
		new sql_kills_player;

		while (SQL_MoreResults(query))
		{
			sql_kills = SQL_ReadResult(query, kills);
			sql_kills_player = SQL_ReadResult(query, kills_player);
			
			gb_sql_kills = sql_kills
			gb_sql_kills_player = sql_kills_player
			
			SQL_NextRow(query);
		}
	}

	SQL_FreeHandle(query);
	SQL_FreeHandle(sql);
	SQL_FreeHandle(info);
}

//------------------
//	SaveDate()
//------------------

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

//------------------
//	ChangeAutoLoad()
//------------------

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

//------------------
//	LoadLevel()
//------------------

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
				get_sql_lvl[id] = sql_lvl

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
						{
							// Kills the player, so the stats actually get loaded properly.
							fakedamage(id, "Z0mbeh", 999999.0, DMG_BULLET);
							// Now lets remove his -2 on the score, because we had to kill him manually.
							set_user_frags(id, 0);
						}
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
		new Handle:query2 = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE `lvl` <= (%d) and `lvl` ORDER BY abs(`lvl` - %d) LIMIT 1", table2, get_sql_lvl[id], get_sql_lvl[id])
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
				// Sets the title
				rank_name = ranktitle;
				SQL_NextRow(query2);
			}
		}

		SQL_FreeHandle(query2);
		SQL_FreeHandle(query);
		SQL_FreeHandle(sql);
		SQL_FreeHandle(info);
	}
}

//------------------
//	GetPosition()
//------------------

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

//------------------
//	GetCurrentRankTitle()
//------------------

GetCurrentRankTitle(id)
{
	new error[128], errno
	new Handle:info = MySQLx_Init()
	new Handle:sql = SQL_Connect(info, errno, error, 127)

	if (sql == Empty_Handle)
	{
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_CON", error)
	}

	new table[32]

	get_cvar_string("bb_rank_table", table, 31)

	// This will read the player LVL and then give him the title he needs
	new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE `lvl` <= (%d) and `lvl` ORDER BY abs(`lvl` - %d) LIMIT 1", table, get_sql_lvl[id], get_sql_lvl[id])
	if (!SQL_Execute(query))
	{
		server_print("query not loaded")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		while (SQL_MoreResults(query))
		{
			new ranktitle[185]
			SQL_ReadResult(query, 1, ranktitle, 31)
			
			top_rank = rank_max
			
			rank_name = ranktitle
			SQL_NextRow(query);
		}
	}
	SQL_FreeHandle(query);
	SQL_FreeHandle(sql);
	SQL_FreeHandle(info);
	return 0;
}

//------------------
//	CreateStats()
//------------------

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

		SQL_QueryAndIgnore(sql, "INSERT INTO `%s` (`authid`, `name`, `lvl`, `skill_hp`, `skill_skill`, `skill_speed`, `points`) VALUES ('%s', '%s', 0, 0, 0, 0, 0)", table, auth, plyname)
		LoadStatsForPlayer[id] = true;
	}
	
	SaveDate(auth);
	UpdateConnection(id, auth);

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}

//------------------
//	SaveGameTime()
//------------------

SaveGameTime(auth[])
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
	
	UpdateGameTime(auth)
	
	new set_gametime = 1 + gb_sql_gametime

	new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE (`authid` = '%s')", table, auth)

	if (!SQL_Execute(query))
	{
		server_print("query not saved")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		SQL_QueryAndIgnore(sql, "UPDATE `%s` SET `gametime` = '%d' WHERE `authid` = '%s';", table, set_gametime, auth )
	}

	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
}

//------------------
//	UpdateGameTime()
//------------------

UpdateGameTime(auth[])
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
		server_print("query not loaded")
		SQL_QueryError(query, error, 127)
		server_print("[AMXX] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else {
		new gtime;
		gtime = SQL_FieldNameToNum(query, "gametime");

		new sql_gametime;

		while (SQL_MoreResults(query))
		{
			sql_gametime = SQL_ReadResult(query, gtime);
			gb_sql_gametime = sql_gametime
			SQL_NextRow(query);
		}
	}

	SQL_FreeHandle(query);
	SQL_FreeHandle(sql);
	SQL_FreeHandle(info);
}
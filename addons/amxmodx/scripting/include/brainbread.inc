/* BrainBread stock functions v0.11
 *
 * (c) 2005, XxAvalanchexX
 *
 * AMX Modx Forums Topic URL:
 * http://www.amxmodx.org/forums/viewtopic.php?t=10392
 *
 * This file is provided as is (no warranties).
 */

#if defined _brainbread_included
  #endinput
#endif
#define _brainbread_included

#include <engine>
#include <fakemeta>

#define SPRAY_BSPRITZ	1
#define SPRAY_BGUSH	2
#define SPRAY_SMOKEPUFF	4
#define SPRAY_EXPLOSION	5

#define DOT_GREEN	1
#define DOT_RED	2
#define DOT_WHITE	3
#define DOT_LTBLUE	4
#define DOT_BLUE	5
#define DOT_ORANGE	6
#define DOT_FLYELLOW	7
#define DOT_FLGREEN	8

/********************************************************************/
/*                      REQUIRES ENGINE TO USE!                     */
/********************************************************************/
/*                     REQUIRES FAKEMETA TO USE!                    */
/********************************************************************/

/* Returns Level of player */
stock bb_get_user_level(id) {
	return get_pdata_int(id,505);
}

stock bb_add_user_level(id) {
	return bb_set_user_level(id,bb_get_user_level(id)+1);
}

stock bb_add_user_levels(id,level) {
	return bb_set_user_level(id,bb_get_user_level(id)+level);
}

/* Sets Level of player */
/* Setting a user DOWN a level will not work, in a matter of seconds
   they will be bumped back up to what they were at with a large amount
   of skill points,as if the game thinks that they had just joined */
stock bb_set_user_level(id,level) {

	new i, totalxp = 0;

	for(i=1;i<=level;i++) {
		totalxp += 150 + ((i-1) * 300);
	}

	bb_set_user_points(id,level)

	bb_set_user_exp(id,float(totalxp))

	message_begin(MSG_ONE,120,{0,0,0},id);
	write_coord(0);
	write_byte(level);
	write_byte(bb_get_user_points(id));
	message_end();

	message_begin(MSG_ALL,81,{0,0,0},0);
	write_byte(id);
	write_short(get_user_frags(id));
	write_short(get_user_deaths(id));
	write_byte(level);
	message_end();

	set_pdata_int(id,504,level);
	return set_pdata_int(id,505,level);
}

/* Returns Experience of player */
stock Float:bb_get_user_exp(id) {
	return get_pdata_float(id,4, -1);
}

/* Sets Experience of player */
/* Note that experience does not go from 0-100 as you might
   believe from the display bar. Instead, it starts at 0 and
   you gain experience, and then the game interprets what level
   you are and how much experience you have to a value from
   0-100 to be able to draw it accurately across the bar. */
/* Additionally, this will not update their level
   when it reaches what would be a new level */
stock bb_set_user_exp(id,Float:exp) {
	return set_pdata_float(id,4,exp, -1);
}

/*
	Adds EXP to the player
*/
stock bb_update_user_exp(id,Float:exp) {
	return set_pdata_float(id,4, bb_get_user_exp(id) + exp, -1);
}

/*
	Removes EXP from the player
*/
stock bb_remove_user_exp(id,Float:exp) {
	return set_pdata_float(id,4, bb_get_user_exp(id) - exp, -1);
}

/* Returns Available Skill Points of player */
stock bb_get_user_points(id) {
	return floatround(get_pdata_float(id,432));
}

/* Sets Avaiable Skill Points of player */
stock bb_set_user_points(id,points) {
	message_begin(MSG_ONE,113,{0,0,0},id);
	write_byte(bb_get_user_hps(id));
	write_byte(bb_get_user_speed(id));
	write_byte(bb_get_user_skill(id));
	write_byte(points);
	message_end();
	return set_pdata_float(id,432,float(points));
}

/* Returns Speed stat of player */
stock bb_get_user_speed(id) {
	return get_pdata_int(id,501);
}

/* Sets Speed stat of player */
stock bb_set_user_speed(id,speed) {
	message_begin(MSG_ONE,113,{0,0,0},id);
	write_byte(bb_get_user_hps(id));
	write_byte(speed);
	write_byte(bb_get_user_skill(id));
	write_byte(bb_get_user_points(id));
	message_end();
	return set_pdata_int(id,501,speed);
}

/* Returns Hitpoints stat of player */
stock bb_get_user_hps(id) {
	return get_pdata_int(id,502);
}

/* Sets Hitpoints stat of player */
stock bb_set_user_hps(id,hps) {
	message_begin(MSG_ONE,113,{0,0,0},id);
	write_byte(hps);
	write_byte(bb_get_user_speed(id));
	write_byte(bb_get_user_skill(id));
	write_byte(bb_get_user_points(id));
	message_end();
	return set_pdata_int(id,502,hps);
}

/* Returns Skill stat of player */
stock bb_get_user_skill(id) {
	return get_pdata_int(id,503);
}

/* Sets Skill stat of player */
stock bb_set_user_skill(id,skill) {
	message_begin(MSG_ONE,113,{0,0,0},id);
	write_byte(bb_get_user_hps(id));
	write_byte(bb_get_user_speed(id));
	write_byte(skill);
	write_byte(bb_get_user_points(id));
	message_end();
	return set_pdata_int(id,503,skill);
}

/* Returns flamethrower ammo for player */
stock bb_get_user_flame_ammo(id) {
	new weapon, current, Float:origin[3], Float:radius = 0.5;
	entity_get_vector(id,EV_VEC_origin,origin);

	while((current = find_ent_in_sphere(current,origin,radius)) != 0) {
		new classname[32];
		entity_get_string(current,EV_SZ_classname,classname,31);

		if(equal(classname,"weapon_flame")) {
			weapon = current;
			break;
		}

	}

	if(is_valid_ent(weapon)) {
		return get_pdata_int(weapon,173);
	}

	return 0;
}

/* Sets flamethrower ammo for player */
stock bb_set_user_flame_ammo(id,ammo) {
	new weapon, current, Float:origin[3], Float:radius = 0.5;
	entity_get_vector(id,EV_VEC_origin,origin);

	while((current = find_ent_in_sphere(current,origin,radius)) != 0) {
		new classname[32];
		entity_get_string(current,EV_SZ_classname,classname,31);

		if(equal(classname,"weapon_flame")) {
			weapon = current;
			break;
		}

	}

	if(is_valid_ent(weapon)) {
		set_pdata_int(weapon,173,ammo);
		return set_pdata_int(weapon,173,ammo);
	}

	return 0;
}

/* Sets any ammo for a weapon */
stock bb_setammo_primary(id,weapon_index[],ammo) {
	new weapon, current, Float:origin[3], Float:radius = 0.5;
	entity_get_vector(id,EV_VEC_origin,origin);

	while((current = find_ent_in_sphere(current,origin,radius)) != 0) {
		new classname[32];
		entity_get_string(current,EV_SZ_classname,classname,31);

		if(equal(classname, weapon_index)) {
			weapon = current;
			break;
		}

	}

	if(is_valid_ent(weapon)) {
		set_pdata_int(weapon,173,ammo);
		return set_pdata_int(weapon,173,ammo);
	}

	return 0;
}
stock bb_setammo_secondary(id,weapon_index[],ammo) {
	new weapon, current, Float:origin[3], Float:radius = 0.5;
	entity_get_vector(id,EV_VEC_origin,origin);

	while((current = find_ent_in_sphere(current,origin,radius)) != 0) {
		new classname[32];
		entity_get_string(current,EV_SZ_classname,classname,31);

		if(equal(classname, weapon_index)) {
			weapon = current;
			break;
		}

	}

	if(is_valid_ent(weapon)) {
		set_pdata_int(weapon,172,ammo);
		return set_pdata_int(weapon,172,ammo);
	}

	return 0;
}

/* debug */
stock bb_debugvalues(id, const weapon_index[]) {
	new weapon, current, Float:origin[3], Float:radius = 0.5;
	entity_get_vector(id,EV_VEC_origin,origin);

	while((current = find_ent_in_sphere(current,origin,radius)) != 0) {
		new classname[32];
		entity_get_string(current,EV_SZ_classname,classname,31);

		if(equal(classname, weapon_index)) {
			weapon = current;
			break;
		}

	}

	if(is_valid_ent(weapon)) {
		test(id, weapon);
		return get_pdata_int(weapon,173);
	}

	return 0;
}

stock test(player, weapon) {
	new iCount = 0;
	for(new i = 1; i <= 200; i++)
	{
		new id = get_pdata_int(weapon,i);
		client_print(player,print_console,"[BB] ID%d: %d", i, id)
		++iCount;
	//	if (i == 200)
	//		test2(player, weapon);
	}
}
/*
stock test2(player, weapon) {
	new iCount = 0;
	for(new i = 201; i <= 400; i++)
	{
		new id = get_pdata_int(weapon,i);
		client_print(player,print_console,"[BB] ID%d: %d", i, id)
		++iCount;
	//	if (i == 200)
	//		test2(player, weapon);
	}
}
*/

/* Returns minigun ammo for player */
stock bb_get_user_minigun_ammo(id) {
	new weapon, current, Float:origin[3], Float:radius = 0.5;
	entity_get_vector(id,EV_VEC_origin,origin);

	while((current = find_ent_in_sphere(current,origin,radius)) != 0) {
		new classname[32];
		entity_get_string(current,EV_SZ_classname,classname,31);

		if(equal(classname,"weapon_minigun")) {
			weapon = current;
			break;
		}

	}

	if(is_valid_ent(weapon)) {
		return get_pdata_int(weapon,173);
	}

	return 0;
}

/* Sets minigun ammo for player */
stock bb_set_user_minigun_ammo(id,ammo) {
	new weapon, current, Float:origin[3], Float:radius = 0.5;
	entity_get_vector(id,EV_VEC_origin,origin);

	while((current = find_ent_in_sphere(current,origin,radius)) != 0) {
		new classname[32];
		entity_get_string(current,EV_SZ_classname,classname,31);

		if(equal(classname,"weapon_minigun")) {
			weapon = current;
			break;
		}

	}

	if(is_valid_ent(weapon)) {
		set_pdata_int(weapon,173,ammo);
		return set_pdata_int(weapon,173,ammo);
	}

	return 0;
}


/* Returns if player is a human */
stock bb_get_user_human(id) {
	return (entity_get_int(id,EV_INT_team) == 1) ? 1 : 0;
}

/* Returns if player is a zombie */
stock bb_get_user_zombie(id) {
	return (entity_get_int(id,EV_INT_team) == 2) ? 1 : 0;
}

/* Zombifies a user */
/* This will set a user to "respawn as human" automatically */
stock bb_set_user_zombie(id,zombie) {

	new team = 1;

	if(zombie == 1) {
		team = 2;
	}

	set_pdata_int(id,408,team);
	set_pdata_int(id,415,team);

	if(team == 2) {
		message_begin(MSG_ONE,106,{0,0,0},id);
		write_coord(-1);
		write_byte(96);
		message_end();
	}
	else {
		bb_show_objective(id," ");
	}

	message_begin(MSG_ALL,108,{0,0,0},0);
	write_byte(id);
	write_byte(team);
	message_end();

	message_begin(MSG_ONE,108,{0,0,0},id);
	write_byte(100+id);
	write_byte(team);
	message_end();

	entity_set_int(id,EV_INT_iStepLeft,(team == 2) ? 1 : 0);
	entity_set_float(id,EV_FL_fuser4,(team == 2) ? 1.0 : 0.0);
	entity_set_int(id,EV_INT_team,team);

	new Float:origin[3], Float:angles[3], Float:v_angle[3];
	entity_get_vector(id,EV_VEC_origin,origin);
	entity_get_vector(id,EV_VEC_angles,angles);
	entity_get_vector(id,EV_VEC_v_angle,v_angle);
	dllfunc(DLLFunc_Spawn,id);
	entity_set_vector(id,EV_VEC_origin,origin);
	entity_set_vector(id,EV_VEC_angles,angles);
	entity_set_vector(id,EV_VEC_v_angle,v_angle);

	strip_user_weapons(id);
	bb_give_item_ex(id,(team == 2) ? "weapon_hand" : "weapon_knife");

	set_pdata_int(id,415,1);

	return 1;
}

/* A give_item that doesn't crash BrainBread */
/* The problem with the original give_item is that it gets the user to
   "touch" the item the moment it is spawned, and apparently BrainBread
   needs a tenth of a second or so to get the item set up before it
   can properly be given to a player... or something */
stock bb_give_item(id,item[]) {
	new weapon = create_entity(item);

	if(is_valid_ent(weapon) == 0) {
		return 0;
	}

	entity_set_origin(weapon,Float:{40000.0,40000.0,40000.0});
	entity_set_edict(weapon,EV_ENT_euser4,id);
	DispatchSpawn(weapon);

	if(is_valid_ent(weapon) == 0) {
		return 0;
	}

	set_task(0.1,"qwertyuiop1234567890",weapon);
	return 1;
}

stock bb_give_item_ex(id, const item[]) {
	new weapon = create_entity(item);

	if(is_valid_ent(weapon) == 0) {
		return 0;
	}

	entity_set_origin(weapon,Float:{40000.0,40000.0,40000.0});
	entity_set_edict(weapon,EV_ENT_euser4,id);
	DispatchSpawn(weapon);

	if(is_valid_ent(weapon) == 0) {
		return 0;
	}

	// Needs to be called on the plugin itself, its a weird bug i know.
	// And using stock doesn't work either.
	/*
public give_item_ex_task(weapon) {
	dllfunc(DLLFunc_Touch,weapon,entity_get_edict(weapon,EV_ENT_euser4));
}
	*/
	set_task(0.1,"give_item_ex_task",weapon);
	return 1;
}

/* Adds Experience to a player */
stock bb_give_exp(id,Float:exp) {
	return bb_set_user_exp(id,bb_get_user_exp(id)+exp);
}

/* Used to display a progress bar in the top-left corner */
stock bb_progress_bar(id,title[],time) {
	/* title: the title of the bar, ie: "Zombie transformation" */
	/* time: the time, in seconds, it takes for the bar to finish */
	message_begin(MSG_ONE,122,{0,0,0},id);
	write_string(title);
	write_coord(time);
	message_end();
	return 1;
}

/* Used to set the "objective" in the top-left corner of the screen */
stock bb_show_objective(id,objective[]) {
	message_begin(MSG_ONE,106,{0,0,0},id);
	write_coord(-1);
	write_byte(144);
	write_string(objective);
	message_end();
	return 1;
}

/* Used to display a message in the center of the screen */
/* duration is how long to hold it, -1 is permanent*/
stock bb_show_message(id,duration,line1[],line2[]) {
	message_begin(MSG_ONE,106,{0,0,0},id);
	write_coord(duration);
	write_byte(32);
	write_string(line1);
	write_string(line2);
	message_end();
	return 1;
}

/* Used to create a spray */
stock bb_spray(type,origin[3]) {

	/* type: type of spray, see below */
	/* origin: origin of where spray comes from */

	/* TYPES:
	SPRAY_BSPRITZ	(1) = Blood spritz
	SPRAY_BGUSH	(2) = Blood gush
	SPRAY_SMOKEPUFF	(4) = Smoke puffs
	SPRAY_EXPLOSION	(5) = Firey explosion */

	message_begin(MSG_PVS,118,origin,0);
	write_byte(type);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(random_num(-1,1));
	write_coord(random_num(-1,1));
	write_coord(random_num(-1,1));
	write_coord(random_num(-1,1));
	write_coord(random_num(-1,1));
	write_coord(random_num(-1,1));
	message_end();

	return 1;
}

/* Used to create a spray, with more parameters */
stock bb_spray_adv(type,origin[3],size[3],dir[3]) {

	/* type: type of spray, see below */
	/* origin: origin of where spray comes from */
	/* size: size of spray, in XYZ format (I think), use a small number like -1 to 1 */
	/* dir: direction of spray, in XYZ format (I think), use a small number like -1 to 1 */

	/* TYPES:
	SPRAY_BSPRITZ	(1) = Blood spritz
	SPRAY_BGUSH	(2) = Blood gush
	SPRAY_SMOKEPUFF	(4) = Smoke puffs
	SPRAY_EXPLOSION	(5) = Firey explosion */

	message_begin(MSG_PVS,118,origin,0);
	write_byte(type);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(size[0]);
	write_coord(size[1]);
	write_coord(size[2]);
	write_coord(dir[0]);
	write_coord(dir[1]);
	write_coord(dir[2]);
	message_end();

	return 1;
}

/* Used to set dots on the radar */
stock bb_radar(id,dot_id,dot_origin[3],dot_status,dot_type) {

	/* dot_id: unique ID for this dot, use same ID to modify the same dot */
	/* dot_origin: the origin of where to place this dot */
	/* dot_status: 0 to remove the dot, 1 to add or modify the dot */
	/* dot_type: the type of dot, see below */

	/* dot_origin and dot_type need not be set accurately when removing the dot */

	/* TYPES:
	DOT_GREEN	(1) = Green Dot, used to mark teammates
	DOT_RED	(2) = Red Dot, used to mark enemies for zombies
	DOT_WHITE	(3) = White Dot, used to mark mission zones
	DOT_LTBLUE	(4) = Light Blue Dot, not used for BrainBread
	DOT_BLUE	(5) = Blue Dot, used to mark the BlackHawk
	DOT_ORANGE	(6) = Orange Dot, not used for BrainBread
	DOT_FLYELLOW	(7) = Flashing Yellow Dot, used to mark the Case or Fred
	DOT_FLGREEN	(8) = Flashing Green Dot, not used for BrainBread,
 	   it stops flashing and turns to white after 3 seconds */

	message_begin(MSG_ONE,93,{0,0,0},id);
	write_short(dot_id);
	write_byte(1);
	write_coord(dot_origin[0]);
	write_coord(dot_origin[1]);
	write_coord(dot_origin[2]);
	write_byte(1);
	message_end();

	message_begin(MSG_ONE,93,{0,0,0},id);
	write_short(dot_id);
	write_byte((dot_status > 0) ? 2 : 0);

	if(dot_status > 0) {
		write_byte(dot_type);
	}

	message_end();

	return 1;
}

/* I have to use this for set_task in bb_give_item, just ignore it paweez :-) */
stock qwertyuiop1234567890(weapon) {
	dllfunc(DLLFunc_Touch,weapon,entity_get_edict(weapon,EV_ENT_euser4));
}

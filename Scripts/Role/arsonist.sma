/**

**/

#define ARSONIST_TEXT	g_rgszRoleNames[Role_Arsonist]
#define ARSONIST_TASK	9164318	// just some random number.

#define FIRE_GRENADE_OPEN	183496
#define FIRE_GRENADE_CLOSED	817724

#define ARSONIST_GRAND_SFX	"leadermode/burn_colony.wav"
#define ARSONIST_REVOKE_SFX	"leadermode/engage_enemy_02.wav"
#define FIREGRENADE_SFX_A	"leadermode/molotov_detonate_3.wav"
#define FIREGRENADE_SFX_B	"leadermode/fire_loop_1.wav.wav"
#define FIREGRENADE_SFX_C	"leadermode/fire_loop_fadeout_01.wav"
#define BURING_SCREAM_SFX	"leadermode/burning_scream_0%d.wav"

new cvar_arsonistDuration, cvar_arsonistCooldown;
new cvar_firegrenade_range, cvar_firegrenade_dmgtime, cvar_firegrenade_dmg, cvar_firegrenade_interval;

new g_idFireSprite, g_idFireTrace, g_idFireHit;
new bool:g_rgbArsonistFiring[33], Float:g_rgflNextBurningScream[33];

public Arsonist_Initialize()
{
	cvar_arsonistDuration	= register_cvar("lm_arsonist_duration",	"15.0");
	cvar_arsonistCooldown	= register_cvar("lm_arsonist_cooldown",	"30.0");

	cvar_firegrenade_range		= register_cvar("lm_firegrenade_range", "350.0");
	cvar_firegrenade_dmgtime	= register_cvar("lm_firegrenade_dmgtime", "20.0");
	cvar_firegrenade_dmg		= register_cvar("lm_firegrenade_dmg", "15.0");
	cvar_firegrenade_interval	= register_cvar("lm_firegrenade_interval", "0.7");

	g_rgSkillDuration[Role_Arsonist] = cvar_arsonistDuration;
	g_rgSkillCooldown[Role_Arsonist] = cvar_arsonistCooldown;
}

public Arsonist_Precache()
{
	engfunc(EngFunc_PrecacheSound, ARSONIST_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, ARSONIST_REVOKE_SFX);
	engfunc(EngFunc_PrecacheSound, FIREGRENADE_SFX_A);
	engfunc(EngFunc_PrecacheSound, FIREGRENADE_SFX_B);
	engfunc(EngFunc_PrecacheSound, FIREGRENADE_SFX_C);
	
	g_idFireSprite = engfunc(EngFunc_PrecacheModel, "sprites/leadermode/flame.spr");
	g_idFireTrace = engfunc(EngFunc_PrecacheModel, "sprites/leadermode/FireSmoke.spr");
	g_idFireHit = engfunc(EngFunc_PrecacheModel, "sprites/xspark4.spr");
	
	static szBurningScreamSFX[48];
	for (new i = 1; i <= 5; i++)
	{
		formatex(szBurningScreamSFX, charsmax(szBurningScreamSFX), BURING_SCREAM_SFX, i);
		precache_sound(szBurningScreamSFX);
	}
}

public bool:Arsonist_ExecuteSkill(pPlayer)
{
	set_task(get_pcvar_float(cvar_arsonistDuration), "Arsonist_RevokeSkill", ARSONIST_TASK + pPlayer);

	engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, ARSONIST_GRAND_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	return true;
}

public Arsonist_RevokeSkill(iTaskId)
{
	new pPlayer = iTaskId - ARSONIST_TASK;

	if (!is_user_connected(pPlayer))
		return;

	if (g_rgPlayerRole[pPlayer] != Role_Arsonist)
		return;

	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_arsonistCooldown);
	print_chat_color(pPlayer, REDCHAT, "技能已结束！");
	client_cmd(pPlayer, "spk %s", ARSONIST_REVOKE_SFX);
}

public Arsonist_MakeFlames(const Float:origin[3])
{
	new Float:fOrigin[3], Float:Range = get_pcvar_float(cvar_firegrenade_range);
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	for (new i = 0; i < floatround(Range/40.0); i++)
	{
		fOrigin[0] = origin[0] + random_float(-Range/2.0, Range/2.0);
		fOrigin[1] = origin[1] + random_float(-Range/2.0, Range/2.0);
		fOrigin[2] = origin[2];

		if(engfunc(EngFunc_PointContents, fOrigin) != CONTENTS_EMPTY) 
			fOrigin[2] += get_distance_f(fOrigin, origin);

		set_pev(iEntity, pev_origin, fOrigin);
		engfunc(EngFunc_DropToFloor, iEntity);
		pev(iEntity, pev_origin, fOrigin);
		
		if(engfunc(EngFunc_PointContents, fOrigin) != CONTENTS_EMPTY)
			continue;
		
		if(!UTIL_PointVisible(origin, fOrigin, IGNORE_MONSTERS))
			continue;
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, fOrigin[0]);
		engfunc(EngFunc_WriteCoord, fOrigin[1]);
		engfunc(EngFunc_WriteCoord, fOrigin[2]+random_float(75.0, 95.0));
		write_short(g_idFireSprite);
		write_byte(random_num(9, 11));
		write_byte(100);
		message_end();
	}
	set_pev(iEntity, pev_flags, FL_KILLME);
}

public Arsonist_CreateTrace(iPlayer, Float:End[3])
{
	new Float:origin[3];
	if (get_pdata_int(iPlayer, 363, 5) >= 90) 
		get_aim_origin_vector(iPlayer, 16.0, 3.0, -3.0, origin);
	else 
		get_aim_origin_vector(iPlayer, 0.0, 0.0, 0.0, origin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	engfunc(EngFunc_WriteCoord, End[0]);
	engfunc(EngFunc_WriteCoord, End[1]);
	engfunc(EngFunc_WriteCoord, End[2]);
	write_short(g_idFireTrace);
	write_byte(1);
	write_byte(10);
	write_byte(15);
	write_byte(6);
	write_byte(0);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(10);
	write_byte(10);
	message_end();
	
	if (engfunc(EngFunc_PointContents, End) == CONTENTS_SKY)
		return;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, End, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, End[0]);
	engfunc(EngFunc_WriteCoord, End[1]);
	engfunc(EngFunc_WriteCoord, End[2]);
	write_short(g_idFireHit);
	write_byte(3);
	write_byte(180);
	message_end();
}
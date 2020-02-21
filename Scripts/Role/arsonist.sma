/**

**/

#define ARSONIST_TEXT	g_rgszRoleNames[Role_Arsonist]
#define ARSONIST_TASK	9164318	// just some random number.

#define FIRE_GRENADE_OPEN	183496
#define FIRE_GRENADE_CLOSED	817724

#define ARSONIST_GRAND_SFX	"leadermode/war_declared.wav"
#define FIREGRENADE_SFX_A	"leadermode/molotov_detonate_3.wav"
#define FIREGRENADE_SFX_B	"leadermode/fire_loop_1.wav.wav"
#define FIREGRENADE_SFX_C	"leadermode/fire_loop_fadeout_01.wav"

new cvar_arsonistDuration, cvar_arsonistCooldown;
new cvar_firegrenade_range, cvar_firegrenade_dmgtime, cvar_firegrenade_dmg, cvar_firegrenade_interval;

new g_idFireSprite;

public Arsonist_Initialize()
{
	cvar_arsonistDuration	= register_cvar("lm_arsonist_duration",	"15.0");
	cvar_arsonistCooldown	= register_cvar("lm_arsonist_cooldown",	"30.0");

	cvar_firegrenade_range		= register_cvar("lm_firegrenade_range", "400.0");
	cvar_firegrenade_dmgtime	= register_cvar("lm_firegrenade_dmgtime", "20.0");
	cvar_firegrenade_dmg		= register_cvar("lm_firegrenade_dmg", "20.0");
	cvar_firegrenade_interval	= register_cvar("lm_firegrenade_interval", "0.3");

	g_rgSkillDuration[Role_Arsonist] = cvar_arsonistDuration;
	g_rgSkillCooldown[Role_Arsonist] = cvar_arsonistCooldown;
}

public Arsonist_Precache()
{
	engfunc(EngFunc_PrecacheSound, ARSONIST_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, FIREGRENADE_SFX_A);
	engfunc(EngFunc_PrecacheSound, FIREGRENADE_SFX_B);
	engfunc(EngFunc_PrecacheSound, FIREGRENADE_SFX_C);
	g_idFireSprite = engfunc(EngFunc_PrecacheModel, "sprites/leadermode/flame.spr");
}

public Arsonist_ExecuteSkill(pPlayer)
{
	set_task(get_pcvar_float(cvar_arsonistDuration), "Arsonist_RevokeSkill", ARSONIST_TASK + pPlayer);

	engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, ARSONIST_GRAND_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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
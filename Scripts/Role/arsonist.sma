/**

**/

#define ARSONIST_TEXT	g_rgszRoleNames[Role_Arsonist]
#define ARSONIST_TASK	9164318	// just some random number.

#define FIRE_GRENADE_OPEN	183496
#define FIRE_GRENADE_CLOSED	817724

#define ARSONIST_GRAND_SFX	"leadermode/burn_colony.wav"
#define ARSONIST_REVOKE_SFX	"leadermode/engage_enemy_02.wav"
#define FIREGRENADE_SFX_A	"leadermode/molotov_detonate_3.wav"
#define FIREGRENADE_SFX_B	"leadermode/fire_loop_1.wav"
#define FIREGRENADE_SFX_C	"leadermode/fire_loop_fadeout_01.wav"
#define BURING_SCREAM_SFX	"leadermode/burning_scream_0%d.wav"

new cvar_arsonistDuration, cvar_arsonistCooldown;
new cvar_arsonistIgniteDmg, cvar_arsonistIgniteDur, cvar_arsonistIgniteInv;
new cvar_firegrenade_range, cvar_firegrenade_dmgtime, cvar_firegrenade_dmg, cvar_firegrenade_interval;

new g_idFireSprite, g_idFireTrace, g_idFireHit;
new bool:g_rgbArsonistFiring[33], Float:g_rgflNextBurningScream[33];

public Arsonist_Initialize()
{
	cvar_arsonistDuration	= register_cvar("lm_arsonist_duration",	"15.0");
	cvar_arsonistCooldown	= register_cvar("lm_arsonist_cooldown",	"30.0");
	
	cvar_arsonistIgniteDmg	= register_cvar("lm_ignition_damage", "14.0");
	cvar_arsonistIgniteDur	= register_cvar("lm_ignition_default_duration", "5.0");
	cvar_arsonistIgniteInv	= register_cvar("lm_ignition_damage_interval", "0.5");

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

new Float:g_rgflPlayerBurning[33], g_rgiIgnitedBy[33], Float:g_rgflFlameThink[33], Float:g_rgflDoFireDamage[33], Float:g_rgflBurningSFX[33];

public Command_Ignite(pPlayer)
{
	if (!get_pcvar_num(cvar_DebugMode))
		return PLUGIN_CONTINUE;
	
	get_aiming_trace(pPlayer);
	
	new iEntity = get_tr2(0, TR_pHit);
	if (is_user_alive2(iEntity))
		pPlayer = iEntity;
	
	static szCommand[24];
	read_argv(1, szCommand, charsmax(szCommand));
	
	g_rgflPlayerBurning[pPlayer] = get_gametime() + str_to_float(szCommand);
	g_rgiIgnitedBy[pPlayer] = pPlayer;
	return PLUGIN_HANDLED;
}

public IncendiaryGrenade_Think(iEntity)
{
	new Float:dmgtime;
	pev(iEntity, pev_dmgtime, dmgtime);
	if (dmgtime - get_gametime() <= 10.0)
	{
		engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, FIREGRENADE_SFX_B, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM);
		engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, FIREGRENADE_SFX_C, 1.0, ATTN_NORM, 0, PITCH_NORM);
		set_pev(iEntity, pev_flags, FL_KILLME);
		return FMRES_SUPERCEDE;
	}
	
	new Float:fCurTime, Float:ThinkTime;
	global_get(glb_time, fCurTime);
	set_pev(iEntity, pev_nextthink, fCurTime + 0.01);
	pev(iEntity, pev_fuser1, ThinkTime);
	
	if (ThinkTime <= fCurTime)
	{
		new Float:origin[3];
		pev(iEntity, pev_origin, origin);
		new i = -1;
		while ((i = engfunc(EngFunc_FindEntityInSphere, i, origin, get_pcvar_float(cvar_firegrenade_range))) > 0)
		{
			if (!pev_valid(i))
				continue;
			
			if (pev(i, pev_takedamage) == DAMAGE_NO)
				continue;
			
			new Float:fOrigin[3];
			pev(i, pev_origin, fOrigin);
			
			if (!UTIL_PointVisible(origin, fOrigin, IGNORE_MONSTERS))
				continue;
			
			if (is_user_alive2(i) && g_rgflFrozenNextthink[i] > 0.0)	// melt the ice.
				Sharpshooter_SetFree(i);
			
			if (is_user_alive2(i) && g_rgPlayerRole[i] == Role_Assassin && g_rgbUsingSkill[i])
				Assassin_Revealed(i, pev(iEntity, pev_owner));
			
			if (is_user_alive2(i) && g_rgflNextBurningScream[i] < get_gametime())
				IncendiaryGrenade_Scream(i);
			
			new Float:fDistance = get_distance_f(fOrigin, origin);
			new Float:range = get_pcvar_float(cvar_firegrenade_range);
			new Float:fMaxDamage = floatmax(get_pcvar_float(cvar_firegrenade_dmg)*((range-fDistance)/range), 0.0);
			
			if (fMaxDamage <= 1.0)
				continue;
			
			ExecuteHamB(Ham_TakeDamage, i, iEntity, pev(iEntity, pev_owner), fMaxDamage, DMG_SLOWBURN);
		}
		set_pev(iEntity, pev_fuser1, fCurTime + get_pcvar_float(cvar_firegrenade_interval));
	}
	
	pev(iEntity, pev_fuser3, ThinkTime);
	if (ThinkTime <= fCurTime)
	{
		engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, FIREGRENADE_SFX_B, 1.0, ATTN_NORM, 0, PITCH_NORM);
		set_pev(iEntity, pev_fuser3, fCurTime + 4.0);
	}
	
	pev(iEntity, pev_fuser2, ThinkTime);
	if (ThinkTime > fCurTime)
		return FMRES_SUPERCEDE;
	
	new Float:origin[3];
	pev(iEntity, pev_origin, origin);
	Arsonist_MakeFlames(origin);
	set_pev(iEntity, pev_fuser2, fCurTime + 0.1);
	
	return FMRES_SUPERCEDE;
}

public IncendiaryGrenade_Scream(pPlayer)
{
	if (g_rgflNextBurningScream[pPlayer] >= get_gametime())
		return;
	
	static szBurningScreamSFX[48];
	formatex(szBurningScreamSFX, charsmax(szBurningScreamSFX), BURING_SCREAM_SFX, random_num(1, 5));
	
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, szBurningScreamSFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	g_rgflNextBurningScream[pPlayer] = get_gametime() + random_float(3.0, 3.5);
}

public IncendiaryGrenade_Blast(iEntity)
{
	if (!engfunc(EngFunc_EntIsOnFloor, iEntity))
		return;

	new Float:fCurTime;
	global_get(glb_time, fCurTime);
	
	set_pev(iEntity, pev_rendermode, kRenderTransAlpha);
	set_pev(iEntity, pev_renderamt, 0.0);
	set_pev(iEntity, pev_solid, SOLID_NOT);
	set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
	set_pev(iEntity, pev_dmgtime, fCurTime + get_pcvar_float(cvar_firegrenade_dmgtime) + 10.0);
	set_pev(iEntity, pev_weapons, FIRE_GRENADE_CLOSED);
	engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, FIREGRENADE_SFX_A, 1.0, ATTN_NORM, 0, PITCH_NORM);
	set_pev(iEntity, pev_fuser3, fCurTime + 1.0);
	
	// the first blast of incendiary grenade would ignite the player inside.
	new i = -1, Float:vecOrigin[3];
	pev(iEntity, pev_origin, vecOrigin);
	while ((i = engfunc(EngFunc_FindEntityInSphere, i, vecOrigin, get_pcvar_float(cvar_firegrenade_range))) > 0)
	{
		if (!pev_valid(i) || iEntity == i)
			continue;
		
		if (pev(i, pev_takedamage) == DAMAGE_NO)
			continue;
		
		ExecuteHamB(Ham_TakeDamage, i, iEntity, pev(iEntity, pev_owner), get_pcvar_float(cvar_firegrenade_dmg), DMG_SLOWBURN);
		
		if (is_user_alive2(i) && g_rgPlayerRole[i] != Role_Arsonist)
		{
			g_rgflPlayerBurning[i] = fCurTime + get_pcvar_float(cvar_arsonistIgniteDur);
			g_rgiIgnitedBy[i] = pev(iEntity, pev_owner);
		}
	}
}

public IncendiaryGrenade_VictimThink(pPlayer)
{
	if (g_rgflPlayerBurning[pPlayer] <= 0.0)	// not burning.
		return;
	
	if (g_rgflPlayerBurning[pPlayer] < get_gametime())	// quench.
	{
		UTIL_ScreenFade(pPlayer, 0.3, 0.2, FFADE_IN, 255, 117, 26, 40);
		ResetMaxSpeed(pPlayer);
		g_rgflPlayerBurning[pPlayer] = -1.0;
		engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, FIREGRENADE_SFX_C, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		return;
	}
	
	if (g_rgflDoFireDamage[pPlayer] < get_gametime())
	{
		new Float:flMaxDamage = get_pcvar_float(cvar_arsonistIgniteDmg);
		ExecuteHamB(Ham_TakeDamage, pPlayer, 0, g_rgiIgnitedBy[pPlayer], random_float(flMaxDamage / 2.0, flMaxDamage), DMG_BURN | DMG_NEVERGIB);
		
		g_rgflDoFireDamage[pPlayer] = get_gametime() + get_pcvar_float(cvar_arsonistIgniteInv);
	}
	
	if (g_rgflFlameThink[pPlayer] < get_gametime())
	{
		new Float:vecOrigin[3];
		pev(pPlayer, pev_origin, vecOrigin);
		vecOrigin[0] += random_float(-16.0, 16.0);
		vecOrigin[1] += random_float(-16.0, 16.0);
		vecOrigin[2] += random_float(-36.0, 36.0);
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_short(g_idFireSprite);
		write_byte(random_num(9, 11));
		write_byte(100);
		message_end();
		
		g_rgflFlameThink[pPlayer] = get_gametime() + 0.1;
	}
	
	if (g_rgflNextBurningScream[pPlayer] < get_gametime())
		IncendiaryGrenade_Scream(pPlayer);
	
	if (g_rgflBurningSFX[pPlayer] < get_gametime())
	{
		engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, FIREGRENADE_SFX_B, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		g_rgflBurningSFX[pPlayer] = get_gametime() + 4.0;
	}
}

new Float:g_rgflArsonistBotThink[33];

public Arsonist_BotThink(pPlayer)
{
	// use the skill if a player is in his fire.
	// use the skill if fighting against a player.
	// give a grenade if commander is met.
	
	if (!is_user_bot(pPlayer) || g_rgflArsonistBotThink[pPlayer] > get_gametime() || !g_bRoundStarted || !is_user_alive(pPlayer))
		return;
	
	if (!g_rgbAllowSkill[pPlayer])
		return;
	
	g_rgflArsonistBotThink[pPlayer] = get_gametime() + 0.5;
	
	get_aiming_trace(pPlayer);
	
	new iEntity = get_tr2(0, TR_pHit);
	if (is_user_alive2(iEntity) && !fm_is_user_same_team(pPlayer, iEntity))
	{
		new Float:vecOrigin[3], Float:vecVictimOrigin[3];
		pev(pPlayer, pev_origin, vecOrigin);
		pev(pPlayer, pev_view_ofs, vecVictimOrigin);
		xs_vec_add(vecOrigin, vecVictimOrigin, vecOrigin);
		pev(iEntity, pev_origin, vecVictimOrigin);
		
		new Float:vecDir[3], Float:vecVAngle[3];
		vecVictimOrigin[2] += 36.0;	// consider the arc.
		xs_vec_sub(vecVictimOrigin, vecOrigin, vecDir);
		engfunc(EngFunc_VecToAngles, vecDir, vecVAngle);
		vecVAngle[0] *= -1.0;
		set_pev(pPlayer, pev_angles, vecVAngle);
		set_pev(pPlayer, pev_v_angle, vecVAngle);
		set_pev(pPlayer, pev_fixangle, 1);
		
		Bot_ForceGrenadeThrow(pPlayer, CSW_HEGRENADE);
		Hub_ExecuteSkill(pPlayer);
	}
}


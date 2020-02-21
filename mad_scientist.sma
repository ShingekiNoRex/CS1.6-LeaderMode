/**

**/

#define MADSCIENTIST_TASK	136874

new cvar_msGravityGunCD, cvar_msGravityGunDur, cvar_msGravityGunDist, cvar_msGravityGunDragSpd;
new Float:g_rgflPlayerElectrified[33], Float:g_rgflElectrifiedScreenFade[33], Float:g_rgflElectrifiedPunch[33];
new Float:g_rgflGravityGunThink[33];

public MadScientist_Initialize()
{
	cvar_msGravityGunCD		= register_cvar("lm_ms_gravity_gun_cd",			"40.0");
	cvar_msGravityGunDur	= register_cvar("lm_ms_gravity_gun_dur",		"15.0");
	cvar_msGravityGunDist	= register_cvar("lm_ms_gravity_gun_dist",		"1600.0");
	cvar_msGravityGunDragSpd= register_cvar("lm_ms_gravity_gun_drag_speed",	"900.0");
	
	g_rgSkillDuration[Role_MadScientist] = cvar_msGravityGunDur;
	g_rgSkillCooldown[Role_MadScientist] = cvar_msGravityGunCD;
}

public Command_Electrify(pPlayer)
{
	if (!get_pcvar_num(cvar_DebugMode))
		return PLUGIN_CONTINUE;
	
	static szCommand[24];
	read_argv(1, szCommand, charsmax(szCommand));
	
	g_rgflPlayerElectrified[pPlayer] = get_gametime() + str_to_float(szCommand);
	return PLUGIN_HANDLED;
}

public MadScientist_ExecuteSkill(pPlayer)
{
	set_task(get_pcvar_float(cvar_msGravityGunDur), "MadScientist_RevokeSkill", MADSCIENTIST_TASK + pPlayer);
}

public MadScientist_RevokeSkill(iTaskId)
{
	new pPlayer = iTaskId - MADSCIENTIST_TASK;
	
	if (!is_user_alive(pPlayer))
		return;
	
	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_msGravityGunCD);
	print_chat_color(pPlayer, REDCHAT, "技能已结束！");
}

public MadScientist_TerminateSkill(pPlayer)
{
	remove_task(MADSCIENTIST_TASK + pPlayer);
	SWAT_RevokeSkill(MADSCIENTIST_TASK + pPlayer);
}

public MadScientist_SkillThink(pPlayer)	// apply on victims
{
	if (g_rgflPlayerElectrified[pPlayer] <= 0.0)	// not electrified.
		return;
	
	if (g_rgflPlayerElectrified[pPlayer] < get_gametime())	// de-electrify
	{
		UTIL_ScreenFade(pPlayer, 0.3, 0.2, FFADE_IN, random_num(0, 255), random_num(0, 255), random_num(0, 255), random_num(60, 100));
		ResetMaxSpeed(pPlayer);
		g_rgflPlayerElectrified[pPlayer] = -1.0;
		
		return;
	}
	
	if (g_rgflElectrifiedScreenFade[pPlayer] < get_gametime())
	{
		NvgScreen(pPlayer, random_num(0, 255), random_num(0, 255), random_num(0, 255), random_num(64, 128));
		g_rgflElectrifiedScreenFade[pPlayer] = get_gametime() + random_float(1.5, 3.0);
	}
	
	if (g_rgflElectrifiedPunch[pPlayer] < get_gametime())
	{
		new Float:vecPunch[3];
		vecPunch[0] = random_float(-20.0, 20.0);
		vecPunch[1] = random_float(-20.0, 20.0);
		vecPunch[2] = random_float(-20.0, 20.0);
		
		new Float:flInterval = random_float(0.5, 1.2);
		
		set_pev(pPlayer, pev_punchangle, vecPunch);
		UTIL_ScreenShake(pPlayer, 4.0, flInterval, 4.0);
		
		g_rgflElectrifiedPunch[pPlayer] = get_gametime() + flInterval;
	}
	
	// random shoot
	if (!random_num(0, 4))
		set_pev(pPlayer, pev_button, pev(pPlayer, pev_button) | IN_ATTACK);
	
	if (!random_num(0, 2))
		set_pev(pPlayer, pev_button, pev(pPlayer, pev_button) & ~IN_ATTACK);
	
	engfunc(EngFunc_SetClientMaxspeed, pPlayer, 125.0);
	set_pev(pPlayer, pev_maxspeed, 125.0);
}

public MadScientist_GravityGunThink(pPlayer)
{
	if (g_rgPlayerRole[pPlayer] != Role_MadScientist || !g_rgbUsingSkill[pPlayer])
		return;
	
	if (g_rgflGravityGunThink[pPlayer] > get_gametime())
		return;
	
	new Float:vecSrc[3], Float:vecEnd[3];
	pev(pPlayer, pev_origin, vecSrc);
	pev(pPlayer, pev_view_ofs, vecEnd);
	xs_vec_add(vecSrc, vecEnd, vecSrc);	// vecSrc is the eye point.
	get_aim_origin_vector(pPlayer, get_pcvar_float(cvar_msGravityGunDist), 0.0, 0.0, vecEnd);
	
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, 0);
	
	new iVictom = get_tr2(0, TR_pHit);
	if (is_user_connected(iVictom))
	{
		new Float:vecVelocity[3];
		xs_vec_sub(vecSrc, vecEnd, vecVelocity);
		xs_vec_normalize(vecVelocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, get_pcvar_float(cvar_msGravityGunDragSpd), vecVelocity);
		vecVelocity[2] = 100.0;
		
		set_pev(iVictom, pev_velocity, vecVelocity);
	}
	
	g_rgflGravityGunThink[pPlayer] = get_gametime() + 0.75;
}
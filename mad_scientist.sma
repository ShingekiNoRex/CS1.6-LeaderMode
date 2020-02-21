/**

**/

#define MADSCIENTIST_TASK	136874

#define ELECTROBULLETS_EFX	"leadermode/electro1.wav"
#define ELECTRIFY_SFX		"leadermode/electric_damage.wav"

new cvar_msGravityGunCD, cvar_msGravityGunDur, cvar_msGravityGunDragSpd;
new cvar_msElectrobltDur;
new Float:g_rgflPlayerElectrified[33], Float:g_rgflElectrifiedScreenFade[33], Float:g_rgflElectrifiedPunch[33], Float:g_rgflElectrifyingSFX[33], Float:g_rgflElectrifyingVFX[33];
new bool:g_rgbShootingElectrobullets[33], Float:g_rgvecElectrobulletsHitsOfs[33][3];

public MadScientist_Initialize()
{
	cvar_msGravityGunCD		= register_cvar("lm_ms_gravity_gun_cd",			"45.0");
	cvar_msGravityGunDur	= register_cvar("lm_ms_gravity_gun_dur",		"12.0");
	cvar_msGravityGunDragSpd= register_cvar("lm_ms_gravity_gun_drag_speed",	"900.0");
	cvar_msElectrobltDur	= register_cvar("lm_ms_electrobullets_lasting",	"3.0");
	
	g_rgSkillDuration[Role_MadScientist] = cvar_msGravityGunDur;
	g_rgSkillCooldown[Role_MadScientist] = cvar_msGravityGunCD;
}

public MadScientist_Precache()
{
	precache_sound(ELECTROBULLETS_EFX);
	precache_sound(ELECTRIFY_SFX);
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
		engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, ELECTRIFY_SFX, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
		
		return;
	}
	
	if (g_rgflElectrifyingSFX[pPlayer] < get_gametime())
	{
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), _, pPlayer);
		write_byte(0); // damage save
		write_byte(0); // damage take
		write_long(DMG_SHOCK); // damage type
		write_coord(0); // x
		write_coord(0); // y
		write_coord(0); // z
		message_end()
		
		engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, ELECTRIFY_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		g_rgflElectrifyingSFX[pPlayer] = get_gametime() + 3.75;
	}
	
	if (g_rgflElectrifyingVFX[pPlayer] < get_gametime())
	{
		MadScientist_VFX(pPlayer);
		g_rgflElectrifyingVFX[pPlayer] = get_gametime() + random_float(0.1, 0.5);
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
	if (!random_num(0, 5))
		set_pev(pPlayer, pev_button, pev(pPlayer, pev_button) | IN_ATTACK);
	
	if (!random_num(0, 2))
		set_pev(pPlayer, pev_button, pev(pPlayer, pev_button) & ~IN_ATTACK);
	
	engfunc(EngFunc_SetClientMaxspeed, pPlayer, 125.0);
	set_pev(pPlayer, pev_maxspeed, 125.0);
}

public MadScientist_DragPlayer(iVictim, Float:vecSrc[3])
{
	static Float:vecOrigin[3], Float:vecVelocity[3];
	pev(iVictim, pev_origin, vecOrigin);
	
	xs_vec_sub(vecSrc, vecOrigin, vecVelocity);
	xs_vec_normalize(vecVelocity, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, get_pcvar_float(cvar_msGravityGunDragSpd), vecVelocity);
	
	set_pev(iVictim, pev_velocity, vecVelocity);
}

public MadScientist_VFX(pPlayer)
{
	static Float:vecOrigin[3];
	pev(pPlayer, pev_origin, vecOrigin);
	
	xs_vec_add(vecOrigin, g_rgvecElectrobulletsHitsOfs[pPlayer], vecOrigin);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_DLIGHT);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(20);		//range
	write_byte(160);
	write_byte(250);
	write_byte(250);
	write_byte(1);		//time
	write_byte(0);
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPARKS);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	message_end();
	
	vecOrigin[0] += random_float(-32.0, 32.0);
	vecOrigin[1] += random_float(-32.0, 32.0);
	vecOrigin[2] += random_float(-36.0, 36.0);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPARKS);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	message_end();
	
	UTIL_BeamEntPoint(pPlayer, vecOrigin, g_ptrBeamSprite, 0, 100, 1, 31, 125, 160, 250, 250, 255, random_num(20, 30));
}
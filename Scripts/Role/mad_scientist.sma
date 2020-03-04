/**

sub_10083E20: CGrenade::ShootSmokeGrenade()
0x56,0x57,0xff,0x15,"*","*","*","*",0x85,0xc0,0x75,"*",0x33,0xff,0xeb,"*"
better 3rd person poisoned VFX. some green smoke around player?
put the speed reduction back. only SWAT with skill can resist it.
the gravity gun have a chance to drop player's weapon and drag it back.
**/

#define MADSCIENTIST_TASK	136874

#define ELECTROBULLETS_SFX	"leadermode/electro1.wav"
#define ELECTRIFY_SFX		"leadermode/electric_damage.wav"
#define MADSCIENTIST_SFX	"leadermode/hermetic_society_interface_01.wav"
#define STATIC_ELEC_SFX		"leadermode/electric_hum2.wav"
#define BREATHE_SFX			"leadermode/breathe1.wav"
#define COUGH_SFX			"leadermode/cough%d.wav"

#define GAS_GRENADE_ENTITY	"gas_grenade"

new cvar_msRevengeRatio;
new cvar_msGravityGunCD, cvar_msGravityGunDur, cvar_msGravityGunDragSpd;
new cvar_msElectrobltDur, cvar_msElectrobltSpdLim;
new cvar_msPoisonLast, cvar_msPoisonDmg, cvar_msPoisonDmgInv, cvar_msPoisonVelMod;
new Float:g_rgflPlayerElectrified[33], Float:g_rgflElectrifiedScreenFade[33], Float:g_rgflElectrifiedPunch[33], Float:g_rgflElectrifyingSFX[33], Float:g_rgflElectrifyingVFX[33];
new bool:g_rgbShootingElectrobullets[33], Float:g_rgvecElectrobulletsHitsOfs[33][3];

public MadScientist_Initialize()
{
	cvar_msGravityGunCD		= register_cvar("lm_ms_gravity_gun_cd",			"60.0");
	cvar_msGravityGunDur	= register_cvar("lm_ms_gravity_gun_dur",		"14.0");
	cvar_msGravityGunDragSpd= register_cvar("lm_ms_gravity_gun_drag_speed",	"900.0");
	cvar_msElectrobltDur	= register_cvar("lm_ms_electrobullets_lasting",	"3.0");
	cvar_msElectrobltSpdLim	= register_cvar("lm_ms_electrobullets_spdlim",	"125.0");
	cvar_msPoisonDmg		= register_cvar("lm_ms_poison_damage",			"7.0");
	cvar_msPoisonLast		= register_cvar("lm_ms_poison_lasting",			"5.0");
	cvar_msPoisonDmgInv		= register_cvar("lm_ms_poison_damage_interval",	"1.0");
	cvar_msPoisonVelMod		= register_cvar("lm_ms_poison_dmg_vel_modifier","0.5");
	cvar_msRevengeRatio		= register_cvar("lm_ms_revenge_ratio",			"0.15");
	
	g_rgSkillDuration[Role_MadScientist] = cvar_msGravityGunDur;
	g_rgSkillCooldown[Role_MadScientist] = cvar_msGravityGunCD;
}

public MadScientist_Precache()
{
	precache_sound(ELECTROBULLETS_SFX);
	precache_sound(ELECTRIFY_SFX);
	precache_sound(MADSCIENTIST_SFX);
	precache_sound(STATIC_ELEC_SFX);
	precache_sound(BREATHE_SFX);
	
	static szCoughSFX[48];
	for (new i = 1; i <= 6; i++)
	{
		formatex(szCoughSFX, charsmax(szCoughSFX), COUGH_SFX, i);
		precache_sound(szCoughSFX);
	}
}

public Command_Electrify(pPlayer)
{
	if (!get_pcvar_num(cvar_DebugMode))
		return PLUGIN_CONTINUE;
	
	static szCommand[24];
	read_argv(1, szCommand, charsmax(szCommand));
	
	g_rgflPlayerElectrified[pPlayer] = get_gametime() + str_to_float(szCommand);
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_ITEM, ELECTRIFY_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return PLUGIN_HANDLED;
}

public bool:MadScientist_ExecuteSkill(pPlayer)
{
	set_task(get_pcvar_float(cvar_msGravityGunDur), "MadScientist_RevokeSkill", MADSCIENTIST_TASK + pPlayer);
	
	client_cmd(pPlayer, "spk %s", MADSCIENTIST_SFX);
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, STATIC_ELEC_SFX, 0.5, ATTN_NORM, 0, PITCH_NORM);
	
	return true;
}

public MadScientist_RevokeSkill(iTaskId)
{
	new pPlayer = iTaskId - MADSCIENTIST_TASK;
	
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, STATIC_ELEC_SFX, 0.5, ATTN_NORM, SND_STOP, PITCH_NORM);
	
	if (!is_user_alive(pPlayer))
		return;
	
	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_msGravityGunCD);
	print_chat_color(pPlayer, REDCHAT, "技能已结束！");
}

public MadScientist_TerminateSkill(pPlayer)
{
	remove_task(MADSCIENTIST_TASK + pPlayer);
	MadScientist_RevokeSkill(MADSCIENTIST_TASK + pPlayer);
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
		engfunc(EngFunc_EmitSound, pPlayer, CHAN_ITEM, ELECTRIFY_SFX, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
		
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
		message_end();
		
		//engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, ELECTRIFY_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);	// could be a overlap?
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
	
	engfunc(EngFunc_SetClientMaxspeed, pPlayer, get_pcvar_float(cvar_msElectrobltSpdLim));
	set_pev(pPlayer, pev_maxspeed, get_pcvar_float(cvar_msElectrobltSpdLim));
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

new Float:g_rgflPlayerPoisoned[33], g_rgiPoisonedBy[33], Float:g_rgflPoisonedDamage[33], bool:g_rgbPoisonedFadeIn[33], Float:g_rgflPoisonedFade[33], Float:g_rgflPoisonedCough[33], Float:g_rgflBreathStop[33];

public Command_Poison(pPlayer)
{
	if (!get_pcvar_num(cvar_DebugMode))
		return PLUGIN_CONTINUE;
	
	static szCommand[24];
	read_argv(1, szCommand, charsmax(szCommand));
	
	g_rgflPlayerPoisoned[pPlayer] = get_gametime() + str_to_float(szCommand);
	g_rgiPoisonedBy[pPlayer] = pPlayer;
	return PLUGIN_HANDLED;
}

public GasGrenade_Think(iEntity)
{
	static Float:flTimeRemove;
	pev(iEntity, pev_fuser1, flTimeRemove);
	
	if (flTimeRemove < get_gametime())
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return;
	}

	static Float:vecOrigin[3];
	pev(iEntity, pev_origin, vecOrigin);
	
	static iAttacker;
	iAttacker = pev(iEntity, pev_iuser4);
	
	new pPlayer = -1, Float:vecVictimOrigin[3];
	while ((pPlayer = engfunc(EngFunc_FindEntityInSphere, pPlayer, vecOrigin, 280.0)) > 0)
	{
		if (!is_user_alive2(pPlayer))
			continue;
		
		pev(pPlayer, pev_origin, vecVictimOrigin);
		if (!UTIL_PointVisible(vecOrigin, vecVictimOrigin, IGNORE_MONSTERS))
			continue;
		
		if (g_rgPlayerRole[pPlayer] == Role_Assassin && g_rgbUsingSkill[pPlayer])
			Assassin_Revealed(pPlayer, iAttacker);
		
		g_rgflPlayerPoisoned[pPlayer] = get_gametime() + get_pcvar_float(cvar_msPoisonLast);
		g_rgiPoisonedBy[pPlayer] = iAttacker;
	}
	
	set_pev(iEntity, pev_nextthink, get_gametime() + 0.1);
}

public GasGrenade_VictimThink(pPlayer)
{
	if (g_rgflBreathStop[pPlayer] > 0.0 && g_rgflBreathStop[pPlayer] < get_gametime())
	{
		engfunc(EngFunc_EmitSound, pPlayer, CHAN_VOICE, BREATHE_SFX, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
		g_rgflBreathStop[pPlayer] = 0.0;
		return;
	}
	
	if (g_rgflPlayerPoisoned[pPlayer] <= 0.0)	// not poisoned.
		return;
	
	if (g_rgflPlayerPoisoned[pPlayer] < get_gametime())	// detoxify
	{
		g_rgbPoisonedFadeIn[pPlayer] = false;
		g_rgflPlayerPoisoned[pPlayer] = 0.0;
		g_rgflBreathStop[pPlayer] = get_gametime() + 6.0;
		engfunc(EngFunc_EmitSound, pPlayer, CHAN_VOICE, BREATHE_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		return;
	}
	
	if (g_rgflPoisonedFade[pPlayer] < get_gametime())
	{
		UTIL_ScreenFade(pPlayer, 0.6, 0.4, g_rgbPoisonedFadeIn[pPlayer] ? FFADE_IN : FFADE_OUT, 128, 255, 128, 150);
		
		g_rgbPoisonedFadeIn[pPlayer] = !g_rgbPoisonedFadeIn[pPlayer];
		g_rgflPoisonedFade[pPlayer] = get_gametime() + 1.0;
	}
	
	if (g_rgflPoisonedCough[pPlayer] < get_gametime())
	{
		static szCoughSFX[48];
		formatex(szCoughSFX, charsmax(szCoughSFX), COUGH_SFX, random_num(1, 6));
		engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, szCoughSFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		g_rgflPoisonedCough[pPlayer] = get_gametime() + random_float(2.5, 4.0);
	}
	
	if (g_rgflPoisonedDamage[pPlayer] < get_gametime())
	{
		new Float:flMaxDamage = get_pcvar_float(cvar_msPoisonDmg);
		ExecuteHamB(Ham_TakeDamage, pPlayer, 0, g_rgiPoisonedBy[pPlayer], random_float(flMaxDamage / 2.0, flMaxDamage), DMG_NERVEGAS | DMG_NEVERGIB);
		
		g_rgflPoisonedDamage[pPlayer] = get_gametime() + get_pcvar_float(cvar_msPoisonDmgInv);
	}
}

new Float:g_rgflMadScientistBotThink[33], Float:g_rgflMadScientistBotNextGR[33];

public MadScientist_BotThink(pPlayer)
{
	// use skill when fighting against player.
	
	if (!is_user_bot(pPlayer) || g_rgflMadScientistBotThink[pPlayer] > get_gametime() || !g_bRoundStarted || !is_user_alive(pPlayer))
		return;
	
	g_rgflMadScientistBotThink[pPlayer] = get_gametime() + 0.5;
	
	get_aiming_trace(pPlayer);
	
	new iEntity = get_tr2(0, TR_pHit);
	if (is_user_alive2(iEntity) && !fm_is_user_same_team(pPlayer, iEntity))
	{
		if (g_rgflMadScientistBotNextGR[pPlayer] < get_gametime())
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
			
			Bot_ForceGrenadeThrow(pPlayer, CSW_SMOKEGRENADE);
			g_rgflMadScientistBotNextGR[pPlayer] = get_gametime() + 5.0;
		}
		else if (g_rgbAllowSkill[pPlayer])
		{
			Hub_ExecuteSkill(pPlayer);
		}
	}
}





















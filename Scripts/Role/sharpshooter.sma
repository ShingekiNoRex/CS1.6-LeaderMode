/**

**/

#define SHARPSHOOTER_TEXT	g_rgszRoleNames[Role_Sharpshooter]
#define SHARPSHOOTER_TASK	2643819	// just some random number.

#define SHARPSHOOTER_GRAND_SFX				"leadermode/agent_recruited.wav"
#define SHARPSHOOTER_REVOKE_SFX				"leadermode/attack_out_of_range_01.wav"
#define SHARPSHOOTER_ICEGRE_NOVA_SFX		"weapons/frostnova.wav"
#define SHARPSHOOTER_ICEGRE_FLESH_SFX		"weapons/impalehit.wav"
#define SHARPSHOOTER_ICEGRE_BREAKOUT_SFX	"weapons/impalelaunch1.wav"

#define ICE_GRENADE_KEY		317465

new cvar_sharpshooterDeathMarkDur, cvar_sharpshooterCooldown;
new cvar_icegrenade_time, cvar_icegrenade_damage, cvar_icegrenade_range;
new g_idShockwaveSprite, g_idGlassModel;

new Float:g_rgflFrozenNextthink[33], Float:g_rgvecFrozenAngles[33][3], Float:g_rgflFrozenFrame[33], Float:g_rgvecFrozenVAngle[33][3];

public Sharpshooter_Initialize()
{
	cvar_sharpshooterDeathMarkDur	= register_cvar("lm_sharpshooter_deathmark_duration",	"5.0");
	cvar_sharpshooterCooldown		= register_cvar("lm_sharpshooter_cooldown",				"30.0");

	cvar_icegrenade_time 			= register_cvar("lm_sharpshooter_frozen_time", "4.0")				//冰冻时间
	cvar_icegrenade_damage 			= register_cvar("lm_sharpshooter_frozen_damage", "20.0")			//冰冻伤害
	cvar_icegrenade_range 			= register_cvar("lm_sharpshooter_frozen_range", "240.0")			//冰冻范围
	
	g_rgSkillDuration[Role_Sharpshooter] = cvar_sharpshooterDeathMarkDur;
	g_rgSkillCooldown[Role_Sharpshooter] = cvar_sharpshooterCooldown;
}

public Sharpshooter_Precache()
{
	engfunc(EngFunc_PrecacheSound, SHARPSHOOTER_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, SHARPSHOOTER_REVOKE_SFX);
	engfunc(EngFunc_PrecacheSound, SHARPSHOOTER_ICEGRE_NOVA_SFX);
	engfunc(EngFunc_PrecacheSound, SHARPSHOOTER_ICEGRE_FLESH_SFX);
	engfunc(EngFunc_PrecacheSound, SHARPSHOOTER_ICEGRE_BREAKOUT_SFX);

	g_idShockwaveSprite = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr")
	g_idGlassModel = engfunc(EngFunc_PrecacheModel, "models/glassgibs.mdl")
}

public Sharpshooter_ExecuteSkill(pPlayer)
{
	set_task(get_pcvar_float(cvar_sharpshooterDeathMarkDur), "Sharpshooter_RevokeSkill", SHARPSHOOTER_TASK + pPlayer);
	
	client_cmd(pPlayer, "spk %s", SHARPSHOOTER_GRAND_SFX);
}

public Sharpshooter_RevokeSkill(iTaskId)
{
	new pPlayer = iTaskId - SHARPSHOOTER_TASK;
	
	if (!is_user_alive(pPlayer))
		return;
	
	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_sharpshooterCooldown);
	print_chat_color(pPlayer, BLUECHAT, "技能已结束！");
	client_cmd(pPlayer, "spk %s", SHARPSHOOTER_REVOKE_SFX);
}

public Sharpshooter_TerminateSkill(pPlayer)
{
	remove_task(SHARPSHOOTER_TASK + pPlayer);
	Sharpshooter_RevokeSkill(SHARPSHOOTER_TASK + pPlayer);
}

public Sharpshooter_IceExplode(iEntity)
{
	new Float:vecOrigin[3];
	pev(iEntity, pev_origin, vecOrigin);
	
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, vecOrigin[0]) // x
	engfunc(EngFunc_WriteCoord, vecOrigin[1]) // y
	engfunc(EngFunc_WriteCoord, vecOrigin[2]) // z
	engfunc(EngFunc_WriteCoord, vecOrigin[0]) // x axis
	engfunc(EngFunc_WriteCoord, vecOrigin[1]) // y axis
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 385.0) // z axis
	write_short(g_idShockwaveSprite) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, vecOrigin[0]) // x
	engfunc(EngFunc_WriteCoord, vecOrigin[1]) // y
	engfunc(EngFunc_WriteCoord, vecOrigin[2]) // z
	engfunc(EngFunc_WriteCoord, vecOrigin[0]) // x axis
	engfunc(EngFunc_WriteCoord, vecOrigin[1]) // y axis
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 470.0) // z axis
	write_short(g_idShockwaveSprite) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, vecOrigin[0]) // x
	engfunc(EngFunc_WriteCoord, vecOrigin[1]) // y
	engfunc(EngFunc_WriteCoord, vecOrigin[2]) // z
	engfunc(EngFunc_WriteCoord, vecOrigin[0]) // x axis
	engfunc(EngFunc_WriteCoord, vecOrigin[1]) // y axis
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 555.0) // z axis
	write_short(g_idShockwaveSprite) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	new i = -1;
	while((i = engfunc(EngFunc_FindEntityInSphere, i, vecOrigin, get_pcvar_float(cvar_icegrenade_range))) > 0)
	{
		if(!pev_valid(i) || iEntity == i)
			continue;
		
		if(pev(i, pev_takedamage) == DAMAGE_NO)
			continue;
		
		if(is_user_alive(i))
		{
			pev(i, pev_frame, g_rgflFrozenFrame[i]);
			pev(i, pev_angles, g_rgvecFrozenAngles[i]);
			pev(i, pev_v_angle, g_rgvecFrozenVAngle[i]);
		}
		
		ExecuteHamB(Ham_TakeDamage, i, iEntity, pev(iEntity, pev_owner), get_pcvar_float(cvar_icegrenade_damage), DMG_FREEZE);
		
		if (is_user_connected(i))
		{
			NvgScreen(i, 0, 50, 200, 100);
			engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, SHARPSHOOTER_ICEGRE_FLESH_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}
	
	engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, SHARPSHOOTER_ICEGRE_NOVA_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_pev(iEntity, pev_flags, FL_KILLME);
}

public Sharpshooter_IceThink(iPlayer)
{
	if(pev(iPlayer, pev_deadflag) != DEAD_NO)
		return;
	
	if(g_rgflFrozenNextthink[iPlayer] == 0.0)
		return;
	
	if(g_rgflFrozenNextthink[iPlayer] > get_gametime())
	{
		set_pev(iPlayer, pev_angles, g_rgvecFrozenAngles[iPlayer]);
		set_pev(iPlayer, pev_frame, g_rgflFrozenFrame[iPlayer]);
		set_pev(iPlayer, pev_v_angle, g_rgvecFrozenVAngle[iPlayer]);
		set_pev(iPlayer, pev_fixangle, 1);
		set_pev(iPlayer, pev_framerate, 0.0);
		set_pev(iPlayer, pev_velocity, Float:{ 0.0, 0.0, -500.0 } );
		
		set_pdata_float(iPlayer, m_flNextAttack, 9999.0, 5);
		
		return;
	}
	
	Sharpshooter_SetFree(iPlayer)
}

public Sharpshooter_GetFrozen(iPlayer)
{
	g_rgflFrozenNextthink[iPlayer] = get_gametime() + get_pcvar_float(cvar_icegrenade_time);
	set_pev(iPlayer, pev_flags, (pev(iPlayer, pev_flags) | FL_FROZEN));
}

public Sharpshooter_SetFree(iPlayer)
{
	set_pdata_float(iPlayer, m_flNextAttack, 0.0);
	set_pev(iPlayer, pev_flags, (pev(iPlayer, pev_flags) & ~ FL_FROZEN));
	set_pev(iPlayer, pev_framerate, 1.0);
	set_pev(iPlayer, pev_fixangle, 0);
	
	if (is_user_connected(iPlayer))
		UTIL_ScreenFade(iPlayer, 0.9, 0.1, FFADE_IN, 0, 50, 200, 100);
	
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SHARPSHOOTER_ICEGRE_BREAKOUT_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	if(g_rgflFrozenNextthink[iPlayer] == 0.0)
		return;
	
	Sharpshooter_IceBroken(iPlayer);
	g_rgflFrozenNextthink[iPlayer] = 0.0;
}

public Sharpshooter_IceBroken(iPlayer)
{
	new Float:vecOrigin[3], Float:origin2[3], Float:velocity[3];
	pev(iPlayer, pev_origin, vecOrigin);
	pev(iPlayer, pev_origin, origin2);
	origin2[2] += 36.0;
	
	GetVelocityFromOrigin(origin2, vecOrigin, 50.0, velocity);
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	engfunc(EngFunc_WriteCoord, 1.5);
	engfunc(EngFunc_WriteCoord, 1.5);
	engfunc(EngFunc_WriteCoord, 1.5);
	engfunc(EngFunc_WriteCoord, velocity[0]);
	engfunc(EngFunc_WriteCoord, velocity[1]);
	engfunc(EngFunc_WriteCoord, velocity[2]);
	write_byte(20);
	write_short(g_idGlassModel);
	write_byte(12);
	write_byte(25);
	write_byte(0x01);
	message_end();
}
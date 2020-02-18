/**

**/

#define SHARPSHOOTER_TEXT	g_rgszRoleNames[Role_Sharpshooter]
#define SHARPSHOOTER_TASK	2643819	// just some random number.

#define SHARPSHOOTER_GRAND_SFX		"leadermode/agent_recruited.wav"
#define SHARPSHOOTER_REVOKE_SFX		"leadermode/attack_out_of_range_01.wav"
#define SHARPSHOOTER_ICEGRE_SFX		"leadermode/iceexplode.wav"

#define ICE_GRENADE_KEY		317465

new cvar_sharpshooterDeathMarkDur, cvar_sharpshooterCooldown;
new cvar_icegrenade_time, cvar_icegrenade_damage, cvar_icegrenade_range;
new g_smodelindexShockwave, g_smodelindexGlass;

new Float:g_rgflFrozenNextthink[33], Float:g_rgvecFrozenAngles[33][3], Float:g_rgflFrozenFrame[33]

public Sharpshooter_Initialize()
{
	cvar_sharpshooterDeathMarkDur	= register_cvar("lm_sharpshooter_deathmark_duration",	"5.0");
	cvar_sharpshooterCooldown		= register_cvar("lm_sharpshooter_cooldown",				"30.0");

	cvar_icegrenade_time 			= register_cvar("lm_sharpshooter_frozen_time", "8.0")				//冰冻时间
	cvar_icegrenade_damage 			= register_cvar("lm_sharpshooter_frozen_damage", "200.0")			//冰冻伤害
	cvar_icegrenade_range 			= register_cvar("lm_sharpshooter_frozen_range", "180.0")			//冰冻范围
	
	g_rgSkillDuration[Role_Sharpshooter] = cvar_sharpshooterDeathMarkDur;
	g_rgSkillCooldown[Role_Sharpshooter] = cvar_sharpshooterCooldown;
}

public Sharpshooter_Precache()
{
	engfunc(EngFunc_PrecacheSound, SHARPSHOOTER_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, SHARPSHOOTER_REVOKE_SFX);
	engfunc(EngFunc_PrecacheSound, SHARPSHOOTER_ICEGRE_SFX);

	g_smodelindexShockwave = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr")
	g_smodelindexGlass = engfunc(EngFunc_PrecacheModel, "models/glassgibs.mdl")
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
	new Float:origin[3];
	pev(iEntity, pev_origin, origin);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + 700.0);
	write_short(g_smodelindexShockwave);
	write_byte(0);
	write_byte(0);
	write_byte(2);
	write_byte(60);
	write_byte(0);
	write_byte(100);
	write_byte(100);
	write_byte(255);
	write_byte(150);
	write_byte(0);
	message_end();
	
	new i = -1
	while((i = engfunc(EngFunc_FindEntityInSphere, i, origin, get_pcvar_float(cvar_icegrenade_range))) > 0)
	{
		if(!pev_valid(i) || iEntity == i)
			continue
		
		if(pev(i, pev_takedamage) == DAMAGE_NO)
			continue
		
		if(is_user_alive(i))
		{
			pev(i, pev_frame, g_rgflFrozenFrame[i])
			pev(i, pev_angles, g_rgvecFrozenAngles[i])
		}
		
		Sharpshooter_GetFrozen(i);
		ExecuteHamB(Ham_TakeDamage, i, iEntity, pev(iEntity, pev_owner), get_pcvar_float(cvar_icegrenade_damage), DMG_FREEZE)
	}
	
	engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, SHARPSHOOTER_ICEGRE_SFX, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_pev(iEntity, pev_flags, FL_KILLME)
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
		set_pev(iPlayer, pev_framerate, 0.0);
		set_pdata_float(iPlayer, 83, 9999.0, 5);
		set_pev(iPlayer, pev_velocity, { 0.0, 0.0, -500.0 } );
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
	set_pdata_float(iPlayer, 83, 0.0, 5);
	set_pev(iPlayer, pev_flags, (pev(iPlayer, pev_flags) & ~ FL_FROZEN));
	set_pev(iPlayer, pev_framerate, 1.0);

	if(g_rgflFrozenNextthink[iPlayer] == 0.0)
		return;
	
	Sharpshooter_IceBroken(iPlayer);
	g_rgflFrozenNextthink[iPlayer] = 0.0;
}

public Sharpshooter_IceBroken(iPlayer)
{
	new Float:origin[3], Float:origin2[3], Float:velocity[3];
	pev(iPlayer, pev_origin, origin);
	pev(iPlayer, pev_origin, origin2);
	origin2[2] += 36.0;
	
	GetVelocityFromOrigin(origin2, origin, 50.0, velocity);
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	engfunc(EngFunc_WriteCoord, 1.5);
	engfunc(EngFunc_WriteCoord, 1.5);
	engfunc(EngFunc_WriteCoord, 1.5);
	engfunc(EngFunc_WriteCoord, velocity[0]);
	engfunc(EngFunc_WriteCoord, velocity[1]);
	engfunc(EngFunc_WriteCoord, velocity[2]);
	write_byte(20);
	write_short(g_smodelindexGlass);
	write_byte(12);
	write_byte(25);
	write_byte(0x01);
	message_end();
}
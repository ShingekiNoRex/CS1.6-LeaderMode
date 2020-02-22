/**

**/

#define BERSERKER_TEXT	g_rgszRoleNames[Role_Berserker]
#define BERSERKER_TASK	8561735	// just some random number.

#define BERSERKER_GRAND_SFX	"leadermode/war_declared.wav"

new cvar_berserkerDuration, cvar_berserkerCooldown, cvar_berserkerDashSpeed;

public Berserker_Initialize()
{
	cvar_berserkerDuration	= register_cvar("lm_berserker_duration",	"5.0");
	cvar_berserkerCooldown	= register_cvar("lm_berserker_cooldown",	"30.0");
	cvar_berserkerDashSpeed	= register_cvar("lm_berserker_dashspeed",	"300.0");

	g_rgSkillDuration[Role_Berserker] = cvar_berserkerDuration;
	g_rgSkillCooldown[Role_Berserker] = cvar_berserkerCooldown;
}

public Berserker_Precache()
{
	engfunc(EngFunc_PrecacheSound, BERSERKER_GRAND_SFX);
}

public Berserker_ExecuteSkill(pPlayer)
{
	set_task(get_pcvar_float(cvar_berserkerDuration), "Berserker_RevokeSkill", BERSERKER_TASK + pPlayer);
	
	engfunc(EngFunc_SetClientMaxspeed, pPlayer, get_pcvar_float(cvar_berserkerDashSpeed));
	set_pev(pPlayer, pev_maxspeed, get_pcvar_float(cvar_berserkerDashSpeed));

	UTIL_ScreenFade(pPlayer, 0.5, get_pcvar_float(cvar_berserkerDuration), FFADE_IN, 255, 10, 10, 60);
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, BERSERKER_GRAND_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public Berserker_RevokeSkill(iTaskId)
{
	new pPlayer = iTaskId - BERSERKER_TASK;

	if (!is_user_connected(pPlayer))
		return;

	if (g_rgPlayerRole[pPlayer] != Role_Berserker)
		return;

	ResetMaxSpeed(pPlayer);
	
	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_berserkerCooldown);
	print_chat_color(pPlayer, REDCHAT, "技能已结束！");

	if (is_user_alive(pPlayer))
	{
		new Float:flCurHealth;
		pev(pPlayer, pev_health, flCurHealth);
		if (flCurHealth <= 1.0)
		{
			ExecuteHamB(Ham_TakeDamage, pPlayer, 0, 0, 100.0, DMG_GENERIC | DMG_NEVERGIB);
		}
	}
}
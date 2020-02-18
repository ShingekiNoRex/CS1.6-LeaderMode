/**

**/

#define BERSERKER_TEXT	g_rgszRoleNames[Role_Berserker]
#define BERSERKER_TASK	8561735	// just some random number.

#define BERSERKER_GRAND_SFX	"leadermode/war_declared.wav"

new cvar_berserkerDuration, cvar_berserkerCooldown;

public Berserker_Initialize()
{
	cvar_berserkerDuration	= register_cvar("lm_berserker_duration",	"5.0");
	cvar_berserkerCooldown	= register_cvar("lm_berserker_cooldown",	"30.0");

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
	
	NvgScreen(pPlayer, 255, 10, 10, 60);
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_BODY, BERSERKER_GRAND_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public Berserker_RevokeSkill(iTaskId)
{
	new iPlayer = iTaskId - BERSERKER_TASK;

	if (!is_user_connected(iPlayer))
		return;

	if (g_rgPlayerRole[iPlayer] != Role_Berserker)
		return;

	NvgScreen(iPlayer);
	g_rgbUsingSkill[iPlayer] = false;
	g_rgflSkillCooldown[iPlayer] = get_gametime() + get_pcvar_float(cvar_berserkerCooldown);
	print_chat_color(iPlayer, REDCHAT, "技能已结束！");

	if (is_user_alive(iPlayer))
	{
		new Float:flCurHealth;
		pev(iPlayer, pev_health, flCurHealth);
		if (flCurHealth <= 1.0)
		{
			ExecuteHamB(Ham_TakeDamage, iPlayer, 0, 0, 100.0, DMG_GENERIC | DMG_NEVERGIB);
		}
	}
}
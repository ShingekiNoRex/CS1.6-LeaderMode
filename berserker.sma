/**

**/

#define BERSERKER_TEXT	g_rgszRoleNames[Role_Berserker]
#define BERSERKER_TASK	8561735	// just some random number.

new cvar_berserkerDuration, cvar_berserkerCooldown;

public Berserker_Initialize()
{
	cvar_berserkerDuration	= register_cvar("lm_berserker_duration",	"5.0");
	cvar_berserkerCooldown	= register_cvar("lm_berserker_cooldown",	"30.0");

	g_rgSkillDuration[Role_Berserker] = cvar_berserkerDuration;
	g_rgSkillCooldown[Role_Berserker] = cvar_berserkerCooldown;
}

public Berserker_TerminateSkill()
{
	remove_task(BERSERKER_TASK);
}

public Berserker_ExecuteSkill(pPlayer)
{
	set_task(get_pcvar_float(cvar_berserkerDuration), "Berserker_RevokeSkill", BERSERKER_TASK);
}

public Berserker_RevokeSkill(iTaskId)
{
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if (g_rgPlayerRole[i] != Role_Berserker)
			continue;
		
		g_rgbUsingSkill[i] = false;
		g_rgflSkillCooldown[i] = get_gametime() + get_pcvar_float(cvar_berserkerCooldown);
		print_chat_color(i, REDCHAT, "技能已结束！");
		
		if (is_user_alive(i))
		{
			new Float:flCurHealth;
			pev(i, pev_health, flCurHealth);
			if (flCurHealth <= 1.0)
			{
				ExecuteHamB(Ham_TakeDamage, i, 0, 0, 100.0, DMG_GENERIC);
			}
		}
	}
}
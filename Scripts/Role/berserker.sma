/**

**/

#define BERSERKER_TEXT	g_rgszRoleNames[Role_Berserker]
#define BERSERKER_TASK	8561735	// just some random number.

#define BERSERKER_GRAND_SFX	"leadermode/war_declared.wav"

new cvar_berserkerDuration, cvar_berserkerCooldown, cvar_berserkerDashSpeed, cvar_berserkerDyingSpeed;

public Berserker_Initialize()
{
	cvar_berserkerDuration	= register_cvar("lm_berserker_duration",	"6.0");
	cvar_berserkerCooldown	= register_cvar("lm_berserker_cooldown",	"40.0");
	cvar_berserkerDashSpeed	= register_cvar("lm_berserker_dashspeed",	"300.0");
	cvar_berserkerDyingSpeed= register_cvar("lm_berserker_dyingspeed",	"10.0");

	g_rgSkillDuration[Role_Berserker] = cvar_berserkerDuration;
	g_rgSkillCooldown[Role_Berserker] = cvar_berserkerCooldown;
}

public Berserker_Precache()
{
	engfunc(EngFunc_PrecacheSound, BERSERKER_GRAND_SFX);
}

public bool:Berserker_ExecuteSkill(pPlayer)
{
	if (g_rgflGodchildrenSavedHP[pPlayer] > 0.0)
	{
		UTIL_ColorfulPrintChat(pPlayer, "/t受/g%s/t的/g洗禮/t約束期間，/g天鵝絕唱/t技能無法使用!", REDCHAT, GODFATHER_TEXT);
		return false;
	}
	
	set_task(get_pcvar_float(cvar_berserkerDuration), "Berserker_RevokeSkill", BERSERKER_TASK + pPlayer);
	
	engfunc(EngFunc_SetClientMaxspeed, pPlayer, get_pcvar_float(cvar_berserkerDashSpeed));
	set_pev(pPlayer, pev_maxspeed, get_pcvar_float(cvar_berserkerDashSpeed));

	UTIL_ScreenFade(pPlayer, 0.5, get_pcvar_float(cvar_berserkerDuration), FFADE_IN, 255, 10, 10, 60);
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_VOICE, BERSERKER_GRAND_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	return true;
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
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_VOICE, BERSERKER_GRAND_SFX, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);

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

public Berserker_TerminateSkill(pPlayer)
{
	remove_task(pPlayer + BERSERKER_TASK);
	
	ResetMaxSpeed(pPlayer);
	
	new Float:flSkillUsedPercentage = (get_gametime() - g_rgflSkillExecutedTime[pPlayer]) / (get_pcvar_float(cvar_berserkerDuration));
	flSkillUsedPercentage = floatclamp(flSkillUsedPercentage, 0.0, 1.0);

	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + (get_pcvar_float(cvar_berserkerCooldown) * flSkillUsedPercentage);
	print_chat_color(pPlayer, REDCHAT, "技能被迫中斷!");
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_VOICE, BERSERKER_GRAND_SFX, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
	
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

new Float:g_rgflBerserkerBotThink[33];

public Berserker_BotThink(pPlayer)
{
	// use their skill when fighting against player.
	
	if (!is_user_bot(pPlayer) || g_rgflBerserkerBotThink[pPlayer] > get_gametime() || !g_bRoundStarted || !is_user_alive(pPlayer))
		return;
	
	if (!g_rgbAllowSkill[pPlayer])
		return;
	
	g_rgflBerserkerBotThink[pPlayer] = get_gametime() + 0.5;
	
	new Float:vecOrigin[3], Float:vecVictimOrigin[3];
	pev(pPlayer, pev_origin, vecOrigin);
	pev(pPlayer, pev_view_ofs, vecVictimOrigin);
	xs_vec_add(vecOrigin, vecVictimOrigin, vecOrigin);
	
	new iEnemyCounts = 0;
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_alive2(i))
			continue;
		
		if (fm_is_user_same_team(pPlayer, i))
			continue;
		
		pev(i, pev_origin, vecVictimOrigin);
		if (!UTIL_PointVisible(vecOrigin, vecVictimOrigin, IGNORE_MONSTERS))
			continue;
		
		iEnemyCounts++;
		
		if (i == THE_COMMANDER)
			iEnemyCounts += 10;	// COMMANDER? KILL HIM!!!!!!!!
		
		if (iEnemyCounts >= 2)
			break;
	}
	
	if (iEnemyCounts >= 2)
	{
		Berserker_ExecuteSkill(pPlayer);
		g_rgbUsingSkill[pPlayer] = true;
		g_rgbAllowSkill[pPlayer] = false;
	}
}

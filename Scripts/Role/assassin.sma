/**

translucent?
will be reveal by HG
**/

#define ASSASSIN_TEXT		g_rgszRoleNames[Role_Assassin]
#define ASSASSIN_TASK		2568736
#define ASSASSIN_HIDEHUD	(HIDEHUD_WEAPONS | HIDEHUD_FLASHLIGHT | HIDEHUD_CROSSHAIR)

#define ASSASSIN_GRAND_SFX		"leadermode/assassins_drug_induced_visions_01.wav"
#define ASSASSIN_DISCOVERED_SFX	"leadermode/agent_detected_and_expelled.wav"
#define ASSASSIN_CRITICAL_SFX	"leadermode/siege_attack.wav"

new cvar_assassinInvisibleDur, cvar_assassinCooldown, cvar_assassinUgDist, cvar_assassinUgInv, cvar_assassinSpeed, cvar_assassinGravity;
new gmsgBombDrop, gmsgBombPickup;
new Float:g_flAssassinRadarThink, Float:g_vecTracedLastOrigin[3], g_iAssassinTracing;
new g_rgiViewModelBuffer[33];

public Assassin_Initialize()
{
	cvar_assassinInvisibleDur	= register_cvar("lm_assassin_marking_duration",		"10.0");
	cvar_assassinCooldown		= register_cvar("lm_assassin_cooldown",				"60.0");
	cvar_assassinUgDist			= register_cvar("lm_assassin_radar_refresh_dist",	"150.0");
	cvar_assassinUgInv			= register_cvar("lm_assassin_radar_refresh_inv",	"2.0");
	cvar_assassinSpeed			= register_cvar("lm_assassin_shadowing_speed",		"350.0");
	cvar_assassinGravity		= register_cvar("lm_assassin_shadowing_gravity",	"0.65");
	
	g_rgSkillDuration[Role_Assassin] = cvar_assassinInvisibleDur;
	g_rgSkillCooldown[Role_Assassin] = cvar_assassinCooldown;

	gmsgBombDrop = get_user_msgid("BombDrop");
	gmsgBombPickup = get_user_msgid("BombPickup");
}

public Assassin_Precache()
{
	engfunc(EngFunc_PrecacheSound, ASSASSIN_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, ASSASSIN_DISCOVERED_SFX);
	engfunc(EngFunc_PrecacheSound, ASSASSIN_CRITICAL_SFX);
}

public bool:Assassin_ExecuteSkill(pPlayer)
{
	if (g_rgflGodchildrenSavedHP[pPlayer] > 0.0)
	{
		UTIL_ColorfulPrintChat(pPlayer, "/t受/g%s/t的/g洗禮/t約束期間，/g幻影/t技能無法使用!", REDCHAT, GODFATHER_TEXT);
		return false;
	}
	
	set_pev(pPlayer, pev_deadflag, DEAD_RESPAWNABLE);	// avoid BOT chasing.
	
	set_pev(pPlayer, pev_gravity, get_pcvar_float(cvar_assassinGravity));
	engfunc(EngFunc_SetClientMaxspeed, pPlayer, get_pcvar_float(cvar_assassinSpeed));
	set_pev(pPlayer, pev_maxspeed, get_pcvar_float(cvar_assassinSpeed));
	
	g_rgiViewModelBuffer[pPlayer] = pev(pPlayer, pev_viewmodel);
	set_pev(pPlayer, pev_viewmodel, 0);
	set_pdata_int(pPlayer, m_iHideHUD, get_pdata_int(pPlayer, m_iHideHUD) | ASSASSIN_HIDEHUD);
	
	UTIL_ScreenFade(pPlayer, 0.3, get_pcvar_float(cvar_assassinInvisibleDur), FFADE_IN, 10, 10, 255, 60);
	client_cmd(pPlayer, "spk %s", ASSASSIN_GRAND_SFX);
	
	if (!is_user_alive(THE_COMMANDER))	// then pick a random guy.
	{
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (!is_user_alive2(i))
				continue;
			
			if (get_pdata_int(i, m_iTeam) != TEAM_CT)
				continue;
			
			g_iAssassinTracing = i;
			break;
		}
	}
	else
		g_iAssassinTracing = THE_COMMANDER;
	
	// nobody to trace. but the assassin may still use the invisible skill.
	if (!is_user_alive2(g_iAssassinTracing))
		print_chat_color(pPlayer, GREYCHAT, "沒有可以追蹤的目標!");

	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i) || is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_TERRORIST)
			continue;
		
		if (g_iAssassinTracing == THE_COMMANDER)
			UTIL_ColorfulPrintChat(i, "/t%s/y的作戰計畫是: /g%s/y, 人力資源剩餘: %d", BLUECHAT, g_rgszTeamName[TEAM_CT], g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[TEAM_CT]], g_rgiTeamMenPower[TEAM_CT]);
		else
		{
			new szNetnames[32];
			pev(g_iAssassinTracing, pev_netname, szNetnames, charsmax(szNetnames));
			
			UTIL_ColorfulPrintChat(i, "/g%s/y已潛入敵方殘部, 並將/t%s%s/y的大致位置標記於雷達上!", BLUECHAT, ASSASSIN_TEXT, g_rgszRoleNames[g_rgPlayerRole[g_iAssassinTracing]], szNetnames);
		}
	}
	if (g_iAssassinTracing == THE_COMMANDER)
		UTIL_ColorfulPrintChat(0, "/g%s/y已竊取敵方作戰計畫, 並將/t%s%s/y的大致位置標記於雷達上!", BLUECHAT, ASSASSIN_TEXT, COMMANDER_TEXT, g_szLeaderNetname[TEAM_CT - 1]);

	set_task(get_pcvar_float(cvar_assassinInvisibleDur), "Assassin_RevokeSkill", ASSASSIN_TASK + pPlayer);
	return true;
}

public Assassin_SkillThink()	// place at StartFrame()
{
	if (!is_user_alive(g_iAssassinTracing))
		return;
	
	new bShouldThink = false;
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (is_user_connected(i) && g_rgPlayerRole[i] == Role_Assassin && g_rgbUsingSkill[i])
		{
			bShouldThink = true;
			break;
		}
	}
	
	if (!bShouldThink)
		return;
	
	static Float:vecOrigin[3];
	pev(g_iAssassinTracing, pev_origin, vecOrigin);
	
	if (get_distance_f(vecOrigin, g_vecTracedLastOrigin) < get_pcvar_float(cvar_assassinUgDist)	// only update radar if the target is moved a certain distance.
		&& g_flAssassinRadarThink > get_gametime() )
	{
		return;
	}
	
	g_flAssassinRadarThink = get_gametime() + get_pcvar_float(cvar_assassinUgInv);
	xs_vec_copy(vecOrigin, g_vecTracedLastOrigin);
	
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i) || is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_TERRORIST)
			continue;
		
		message_begin(MSG_ONE_UNRELIABLE, gmsgBombDrop, _, i);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_byte(0);
		message_end();

		client_cmd(i, "spk %s", SFX_RADAR_BEEP);
	}
}

public Assassin_SelfThink(pPlayer)
{
	if (!is_user_alive2(pPlayer))
		return;
	
	if (g_rgPlayerRole[pPlayer] != Role_Assassin)
		return;
	
	if (g_rgbUsingSkill[pPlayer] && pev(pPlayer, pev_button) & IN_ATTACK)	// manually self-reveal.
		Assassin_Revealed(pPlayer, 0);
}

public Assassin_RevokeSkill(iTaskId)
{
	// UNDONE: what if another assassin is overlaping the skill effect?
	
	new pPlayer = iTaskId - ASSASSIN_TASK;
	
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i) || is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_TERRORIST)
			continue;
		
		message_begin(MSG_ONE, gmsgBombPickup, _, i);
		message_end();
	}
	
	if (!is_user_connected(pPlayer))
		return;
	
	if (!g_rgbUsingSkill[pPlayer])	// which means the assassin was killed when cooling down.
		return;
	
	print_chat_color(pPlayer, REDCHAT, "技能已结束！");
	
	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_assassinCooldown);
	
	new Float:flHealth;
	pev(pPlayer, pev_health, flHealth);
	
	if (flHealth > 0.0)	// still alive
	{
		set_pev(pPlayer, pev_deadflag, DEAD_NO);
		set_pev(pPlayer, pev_viewmodel, g_rgiViewModelBuffer[pPlayer]);
		set_pev(pPlayer, pev_gravity, 1.0);
		
		set_pdata_int(pPlayer, m_iHideHUD, get_pdata_int(pPlayer, m_iHideHUD) & ~ASSASSIN_HIDEHUD);
		ExecuteHamB(Ham_Item_Deploy, get_pdata_cbase(pPlayer, m_pActiveItem));
		ResetMaxSpeed(pPlayer);
	}
}

public Assassin_TerminateSkill(pPlayer)
{
	remove_task(ASSASSIN_TASK + pPlayer);
	
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i) || is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_TERRORIST)
			continue;
		
		message_begin(MSG_ONE, gmsgBombPickup, _, i);
		message_end();
	}
	
	if (!is_user_alive2(pPlayer))
		return;
	
	new Float:flSkillUsedPercentage = (get_gametime() - g_rgflSkillExecutedTime[pPlayer]) / (get_pcvar_float(cvar_assassinInvisibleDur));
	flSkillUsedPercentage = floatclamp(flSkillUsedPercentage, 0.0, 1.0);

	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + (get_pcvar_float(cvar_assassinCooldown) * flSkillUsedPercentage);	// if you manually reveal yourself, this bonus would be applied.
	
	set_pev(pPlayer, pev_deadflag, DEAD_NO);
	set_pev(pPlayer, pev_viewmodel, g_rgiViewModelBuffer[pPlayer]);
	set_pev(pPlayer, pev_gravity, 1.0);
	
	client_cmd(pPlayer, "stopsound");
	set_pdata_int(pPlayer, m_iHideHUD, get_pdata_int(pPlayer, m_iHideHUD) & ~ASSASSIN_HIDEHUD);
	ExecuteHamB(Ham_Item_Deploy, get_pdata_cbase(pPlayer, m_pActiveItem));
	ResetMaxSpeed(pPlayer);
}

public Assassin_Revealed(pPlayer, iAttacker)	// cacha !!!
{
	Assassin_TerminateSkill(pPlayer);
	
	UTIL_ScreenFade(pPlayer, 0.3, 0.1, FFADE_IN, 10, 10, 255, 60);
	
	if (is_user_alive2(iAttacker))
	{
		client_cmd(pPlayer, "spk %s", ASSASSIN_DISCOVERED_SFX);	// this SFX would be played only if the assassin is discovered by someone else.
		g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_assassinCooldown);	// and the full-CD punishment would be applied.
	}
	
	print_chat_color(pPlayer, REDCHAT, is_user_alive2(iAttacker) ? "你被發現了!" : "技能已中斷!");
	
	if (is_user_connected(iAttacker) && !is_user_bot(iAttacker))
		client_cmd(iAttacker, "spk %s", ASSASSIN_DISCOVERED_SFX);
}

new Float:g_rgflAssassinBotThink[33];

public Assassin_BotThink(pPlayer)
{
	// use their skill whenever they can.
	
	if (!is_user_bot(pPlayer) || g_rgflAssassinBotThink[pPlayer] > get_gametime() || !g_bRoundStarted || !is_user_alive2(pPlayer))
		return;
	
	if (!g_rgbAllowSkill[pPlayer])
		return;
	
	g_rgflAssassinBotThink[pPlayer] = get_gametime() + 1.0;
	
	Assassin_ExecuteSkill(pPlayer);
	g_rgbUsingSkill[pPlayer] = true;
	g_rgbAllowSkill[pPlayer] = false;
}

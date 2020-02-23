/**

**/

#define THE_COMMANDER	g_iLeader[TEAM_CT - 1]
#define COMMANDER_TEXT	g_rgszRoleNames[Role_Commander]
#define COMMANDER_TASK	2876674	// just some random number.

#define COMMANDER_MODEL			"models/player/Bluemat/Bluemat.mdl"
#define COMMANDER_MODEL_T		"models/player/Bluemat/BluematT.mdl"
#define COMMANDER_MODEL_KEY		"Bluemat"

#define COMMANDER_GRAND_SFX		"leadermode/peace_summary_message_01.wav"
#define COMMANDER_REVOKE_SFX	"leadermode/assign_leader_02.wav"

new cvar_commanderMarkingDur, cvar_commanderCooldown;
new gmsgHostagePos, gmsgHostageK;
new Float:g_flCommanderRadarThink, g_iCommanderTracing;

public Commander_Initialize()
{
	cvar_commanderMarkingDur	= register_cvar("lm_commander_marking_duration",	"20.0");
	cvar_commanderCooldown		= register_cvar("lm_commander_cooldown",			"60.0");

	g_rgSkillDuration[Role_Commander] = cvar_commanderMarkingDur;
	g_rgSkillCooldown[Role_Commander] = cvar_commanderCooldown;
	
	gmsgHostagePos	= get_user_msgid("HostagePos");
	gmsgHostageK	= get_user_msgid("HostageK");
}

public Commander_Precache()
{
	engfunc(EngFunc_PrecacheModel, COMMANDER_MODEL);
	engfunc(EngFunc_PrecacheModel, COMMANDER_MODEL_T);

	engfunc(EngFunc_PrecacheSound, COMMANDER_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, COMMANDER_REVOKE_SFX);
}

public Commander_Assign(pPlayer)
{
	new Float:flSucceedHealth = 1000.0;
	if (is_user_connected(THE_COMMANDER))
	{
		new iAbdicator = THE_COMMANDER;
		
		emessage_begin(MSG_ALL, get_user_msgid("ScoreAttrib"));
		ewrite_byte(iAbdicator);
		ewrite_byte(0);
		emessage_end();
		
		g_rgPlayerRole[iAbdicator] = Role_UNASSIGNED;
		pev(iAbdicator, pev_health, flSucceedHealth);	// this health will be assign to new leader. prevents the confidence motion mechanism abused by players.

		set_pev(iAbdicator, pev_health, 100.0);
		set_pev(iAbdicator, pev_max_health, 100.0);
		UTIL_SetPlayerModel(pPlayer);	// reset his model.
	}
	
	if (!is_user_alive(pPlayer))	// what if this guy was dead?
		ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);
	
	// LONG LIVE THE KING!
	THE_COMMANDER = pPlayer;
	UTIL_SetPlayerModel(pPlayer, COMMANDER_MODEL_KEY);
	pev(THE_COMMANDER, pev_netname, g_szLeaderNetname[TEAM_CT - 1], charsmax(g_szLeaderNetname[]));
	set_pev(THE_COMMANDER, pev_health, flSucceedHealth);
	set_pev(THE_COMMANDER, pev_max_health, 1000.0);

	new rgColor[3] = { 255, 100, 255 };
	new Float:flCoordinate[2] = { -1.0, 0.30 };
	new Float:rgflTime[4] = { 6.0, 6.0, 0.1, 0.2 };
	
	g_rgPlayerRole[THE_COMMANDER] = Role_Commander;
	ShowHudMessage(THE_COMMANDER, rgColor, flCoordinate, 0, rgflTime, -1, "你已被選定為%s!", COMMANDER_TEXT);
	
	emessage_begin(MSG_ALL, get_user_msgid("ScoreAttrib"));
	ewrite_byte(THE_COMMANDER);	// head of CTs
	ewrite_byte(SCOREATTRIB_VIP);
	emessage_end();
}

public Commander_ExecuteSkill()
{
	if (g_rgbUsingSkill[THE_COMMANDER])
		return;
	
	if (!is_user_alive(THE_GODFATHER))	// then pick a random guy.
	{
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (!is_user_alive2(i))
				continue;
			
			if (get_pdata_int(i, m_iTeam) != TEAM_TERRORIST)
				continue;
			
			g_iCommanderTracing = i;
			break;
		}
	}
	else
		g_iCommanderTracing = THE_GODFATHER;
	
	// nobody to trace.
	if (!is_user_alive2(g_iCommanderTracing))
	{
		print_chat_color(THE_COMMANDER, REDCHAT, "沒有可以追蹤的目標!");
		return;
	}
	
	new Float:vecOrigin[3];
	pev(g_iCommanderTracing, pev_origin, vecOrigin);
	
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i) || is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_CT)
			continue;
		
		message_begin(MSG_ONE, gmsgHostagePos, _, i);
		write_byte(1);	// flags
		write_byte(1);	// hostage index
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		message_end();
		
		client_cmd(i, "spk %s", COMMANDER_GRAND_SFX);
	}
	
	if (g_iCommanderTracing == THE_GODFATHER)
		UTIL_ColorfulPrintChat(0, "/g%s執行了無人機低空掃描, /t%s%s/g的實時位置已標記於雷達上!", REDCHAT, COMMANDER_TEXT, GODFATHER_TEXT, g_szLeaderNetname[TEAM_TERRORIST - 1]);
	else
	{
		new szNetnames[32];
		pev(g_iCommanderTracing, pev_netname, szNetnames, charsmax(szNetnames));
		
		UTIL_ColorfulPrintChat(0, "/g%s執行了無人機低空掃描, /t%s%s/g的實時位置已標記於雷達上!", REDCHAT, COMMANDER_TEXT, g_rgszRoleNames[g_rgPlayerRole[g_iCommanderTracing]], szNetnames);
	}
	
	set_task(get_pcvar_float(cvar_commanderMarkingDur), "Commander_RevokeSkill", COMMANDER_TASK);
}

public Commander_SkillThink(pPlayer)	// place at PlayerPostThink()
{
	// please do the team check before calling this!
	if (g_flCommanderRadarThink > get_gametime())
		return;
	
	if (!is_user_alive(THE_COMMANDER) || !g_rgbUsingSkill[THE_COMMANDER])
		return;

	if (is_user_bot(pPlayer))
		return;
	
	if (!is_user_alive2(g_iCommanderTracing))	// never tracing the dead.
		return;

	g_flCommanderRadarThink = 2.0 + get_gametime();

	static Float:vecOrigin[3];
	pev(g_iCommanderTracing, pev_origin, vecOrigin);
	
	message_begin(MSG_ONE, gmsgHostagePos, _, pPlayer);
	write_byte(0);	// flags
	write_byte(1);	// hostage index
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	message_end();

	message_begin(MSG_ONE, gmsgHostageK, _, pPlayer);
	write_byte(1);	// hostage index
	message_end();

	client_cmd(pPlayer, "spk %s", SFX_RADAR_BEEP);
}

public Commander_RevokeSkill(iTaskId)
{
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i) || is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_CT)
			continue;
		
		message_begin(MSG_ONE, gmsgHostageK, _, i);
		write_byte(1);	// hostage index
		message_end();
		
		client_cmd(i, "spk %s", COMMANDER_REVOKE_SFX);
	}
	
	if (is_user_connected(THE_COMMANDER))
	{
		print_chat_color(THE_COMMANDER, REDCHAT, "技能已结束！");
	
		g_rgbUsingSkill[THE_COMMANDER] = false;
		g_rgflSkillCooldown[THE_COMMANDER] = get_gametime() + get_pcvar_float(cvar_commanderCooldown);
	}
}

public Commander_TerminateSkill()
{
	remove_task(COMMANDER_TASK);
	Commander_RevokeSkill(COMMANDER_TASK);
}

new Float:g_flCommanderBotThink = 0.0;	// there is only one THE_COMMANDER

public Commander_BotThink(pPlayer)
{
	// the goal of BOT commander:
	// never sell weapons on the ground. (players may needs it). unless the entire CT-team is bot team.
	// use skill only when firing at someone. unless one of the CTs is the player.
	
	if (g_flCommanderBotThink > get_gametime())
		return;
	
	if (!g_rgbAllowSkill[pPlayer])
		return;
	
	g_flCommanderBotThink = get_gametime() + 1.0;
	
	if (g_rgbFullBotsTeam[TEAM_CT])
	{
		get_aiming_trace(pPlayer);
		
		new iTarget = get_tr2(0, TR_pHit);
		if (is_user_alive(iTarget) && get_pdata_int(iTarget, m_iTeam) == TEAM_TERRORIST)
		{
			Commander_ExecuteSkill();
			g_rgbUsingSkill[pPlayer] = true;
			g_rgbAllowSkill[pPlayer] = false;	// we need to set this value manually, since we bypass fw_CmdStart().
		}
	}
	else
	{
		Commander_ExecuteSkill();	// if there is a player in the team, commander should keep his skill running ASAP.
		g_rgbUsingSkill[pPlayer] = true;
		g_rgbAllowSkill[pPlayer] = false;
	}
}

public bool:Commander_CheckWeaponSell(pPlayer, iId)
{
	if (!g_rgbFullBotsTeam[TEAM_CT])
		return false;
	
	if (pev_valid(get_pdata_cbase(pPlayer, m_rgpPlayerItems[g_rgiWeaponDefaultSlot[iId] + 1])) != 2)	// don't have a weapon in the slot yet.
		return false;
	
	return !!is_user_bot(pPlayer);
}

/**

**/

#define ASSASSIN_TEXT		g_rgszRoleNames[Role_Assassin]
#define ASSASSIN_TASK		2568736
#define ASSASSIN_HIDEHUD	(HIDEHUD_WEAPONS | HIDEHUD_FLASHLIGHT | HIDEHUD_CROSSHAIR)

#define ASSASSIN_GRAND_SFX		"leadermode/assassins_drug_induced_visions_01.wav"
#define ASSASSIN_DISCOVERED_SFX	"leadermode/agent_detected_and_expelled.wav"

new cvar_assassinInvisibleDur, cvar_assassinCooldown;
new gmsgBombDrop, gmsgBombPickup;
new Float:g_rgflAssassinRadarThink;
new g_rgiViewModelBuffer[33];

public Assassin_Initialize()
{
	cvar_assassinInvisibleDur	= register_cvar("lm_assassin_marking_duration",	"10.0");
	cvar_assassinCooldown		= register_cvar("lm_assassin_cooldown",			"60.0");
	
	g_rgSkillDuration[Role_Assassin] = cvar_assassinInvisibleDur;
	g_rgSkillCooldown[Role_Assassin] = cvar_assassinCooldown;

	gmsgBombDrop = get_user_msgid("BombDrop");
	gmsgBombPickup = get_user_msgid("BombPickup");
}

public Assassin_Precache()
{
	engfunc(EngFunc_PrecacheSound, ASSASSIN_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, ASSASSIN_DISCOVERED_SFX);
}

public Assassin_ExecuteSkill(pPlayer)
{
	set_pev(pPlayer, pev_deadflag, DEAD_RESPAWNABLE);	// avoid BOT chasing.
	set_pev(pPlayer, pev_effects, pev(pPlayer, pev_effects) | EF_NODRAW);
	
	g_rgiViewModelBuffer[pPlayer] = pev(pPlayer, pev_viewmodel);
	set_pev(pPlayer, pev_viewmodel, 0);
	set_pdata_int(pPlayer, m_iHideHUD, get_pdata_int(pPlayer, m_iHideHUD) | ASSASSIN_HIDEHUD);
	
	NvgScreen(pPlayer, 10, 10, 255, 60);
	client_cmd(pPlayer, "spk %s", ASSASSIN_GRAND_SFX);
	UTIL_ColorfulPrintChat(0, "/g%s已窃取敌方情报, /t%s%s/g的實時位置已標記於雷達上!", REDCHAT, ASSASSIN_TEXT, COMMANDER_TEXT, g_szLeaderNetname[TEAM_CT - 1]);

	set_task(get_pcvar_float(cvar_assassinInvisibleDur), "Assassin_RevokeSkill", ASSASSIN_TASK + pPlayer);
}

public Assassin_SkillThink()	// place at StartFrame()
{
	if (g_rgflAssassinRadarThink > get_gametime())
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
	
	g_rgflAssassinRadarThink = 2.0 + get_gametime();

	static Float:vecOrigin[3];
	pev(THE_COMMANDER, pev_origin, vecOrigin);
	
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

		if (g_rgPlayerRole[i] != Role_Assassin)
			client_cmd(i, "spk %s", SFX_RADAR_BEEP);
	}
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
	
	NvgScreen(pPlayer);
	
	new Float:flHealth;
	pev(pPlayer, pev_health, flHealth);
	
	if (flHealth > 0.0)	// still alive
	{
		set_pev(pPlayer, pev_deadflag, DEAD_NO);
		set_pev(pPlayer, pev_viewmodel, g_rgiViewModelBuffer[pPlayer]);
		set_pev(pPlayer, pev_effects, pev(pPlayer, pev_effects) & ~EF_NODRAW);
		
		set_pdata_int(pPlayer, m_iHideHUD, get_pdata_int(pPlayer, m_iHideHUD) & ~ASSASSIN_HIDEHUD);
		ExecuteHamB(Ham_Item_Deploy, get_pdata_cbase(pPlayer, m_pActiveItem));
	}
	
	print_chat_color(pPlayer, REDCHAT, "技能已结束！");
	
	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_assassinCooldown);
}

public Assassin_TerminateSkill(pPlayer)
{
	remove_task(ASSASSIN_TASK + pPlayer);
	Assassin_RevokeSkill(ASSASSIN_TASK + pPlayer);
}
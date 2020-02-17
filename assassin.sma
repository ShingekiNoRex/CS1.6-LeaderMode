/**

**/

#define ASSASSIN_TEXT	g_rgszRoleNames[Role_Assassin]
#define ASSASSIN_TASK	2568736

#define ASSASSIN_GRAND_SFX	"leadermode/assassins_drug_induced_visions_01.wav"

new cvar_assassinInvisibleDur, cvar_assassinCooldown;
new gmsgBombDrop, gmsgBombPickup;

public Assassin_Initialize()
{
	cvar_assassinInvisibleDur	= register_cvar("lm_assassin_marking_duration",	"10.0");
	cvar_assassinCooldown		= register_cvar("lm_assassin_cooldown",			"60.0");
	
	g_rgSkillDuration[Role_Assassin] = cvar_assassinInvisibleDur;
	g_rgSkillCooldown[Role_Assassin] = cvar_assassinCooldown;
	
	gmsgBombDrop	= get_user_msgid("BombDrop");
	gmsgBombPickup	= get_user_msgid("BombPickup");
}

public Assassin_ExecuteSkill(pPlayer)
{
	set_pev(pPlayer, pev_deadflag, DEAD_RESPAWNABLE);	// avoid BOT chasing.
	
	NvgScreen(pPlayer, 10, 10, 255, 60);
	client_cmd(pPlayer, "spk %s", ASSASSIN_GRAND_SFX);
	
	set_task(get_pcvar_float(cvar_assassinInvisibleDur), "Assassin_RevokeSkill", ASSASSIN_TASK + pPlayer);
	g_rgflSkillExecutedTime[pPlayer] = get_gametime();
}

public Assassin_SkillThink()	// place at StartFrame_Post()
{
	new bShouldThink = false;
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (is_user_alive(i) && g_rgPlayerRole[i] == Role_Assassin && g_rgbUsingSkill[i])
		{
			bShouldThink = true;
			break;
		}
	}
	
	if (!bShouldThink)
		return;
	
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_TERRORIST)
			continue;
		
		if (is_user_bot(i))
			continue;
		
		static Float:vecOrigin[3];
		pev(THE_COMMANDER, pev_origin, vecOrigin);
		
		message_begin(MSG_ONE_UNRELIABLE, gmsgBombDrop, _, i);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_byte(0);
		message_end();
	}
}

public Assassin_RevokeSkill(iTaskId)
{
	new pPlayer = iTaskId - ASSASSIN_TASK;
	
	NvgScreen(pPlayer);
	
	new Float:flHealth;
	pev(pPlayer, pev_health, flHealth);
	
	if (flHealth > 0.0)	// still alive
		set_pev(pPlayer, pev_deadflag, DEAD_NO);
	
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_TERRORIST)
			continue;
		
		if (is_user_bot(i))
			continue;
		
		message_begin(MSG_ONE, gmsgBombPickup, _, i);
		message_end();
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
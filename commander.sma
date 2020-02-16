/**

**/

#define THE_COMMANDER	g_iLeader[TEAM_CT - 1]
#define COMMANDER_TEXT	g_rgszRoleNames[Role_Commander]
#define COMMANDER_TASK	2876674	// just some random number.

#define COMMANDER_GRAND_SFX		"leadermode/peace_summary_message_01.wav"
#define COMMANDER_REVOKE_SFX	"leadermode/assign_leader_02.wav"

new cvar_commanderMarkingDur, cvar_commanderCooldown;

public Commander_Initialize()
{
	cvar_commanderMarkingDur	= register_cvar("lm_commander_marking_duration",	"20.0");
	cvar_commanderCooldown		= register_cvar("lm_commander_cooldown",			"60.0");

	g_rgSkillDuration[Role_Commander] = cvar_commanderMarkingDur;
	g_rgSkillCooldown[Role_Commander] = cvar_commanderCooldown;
}

public Commander_ExecuteSkill(pPlayer)
{
	if (!is_user_alive(THE_GODFATHER) || g_rgbUsingSkill[THE_COMMANDER])
		return;
	
	new Float:vecOrigin[3];
	pev(THE_GODFATHER, pev_origin, vecOrigin);
	
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i) || is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_CT)
			continue;
		
		message_begin(MSG_ONE, get_user_msgid("HostagePos"), _, i);
		write_byte(1);	// flags
		write_byte(1);	// hostage index
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		message_end();

		if (i != THE_COMMANDER)
			print_chat_color(i, GREENCHAT, "指挥官发动了技能，%s的位置已在雷达上标出！", GODFATHER_TEXT);
		
		client_cmd(i, "spk %s", COMMANDER_GRAND_SFX);
	}
	
	set_task(get_pcvar_float(cvar_commanderMarkingDur), "Commander_RevokeSkill", COMMANDER_TASK);
	g_rgflSkillExecutedTime[THE_COMMANDER] = get_gametime();
}

public Commander_SkillThink(pPlayer)	// place at PlayerPostThink()
{
	// please do the team check before calling this!
	
	if (!is_user_alive(THE_COMMANDER) || !g_rgbUsingSkill[THE_COMMANDER])
		return;

	if (is_user_bot(pPlayer))
		return;
	
	static Float:vecOrigin[3];
	pev(THE_GODFATHER, pev_origin, vecOrigin);
	
	static gmsgHostagePos;
	if (!gmsgHostagePos)
		gmsgHostagePos = get_user_msgid("HostagePos");
	
	message_begin(MSG_ONE, gmsgHostagePos, _, pPlayer);
	write_byte(0);	// flags
	write_byte(1);	// hostage index
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	message_end();
}

public Commander_RevokeSkill(iTaskId)
{
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i) || is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != TEAM_CT)
			continue;
		
		message_begin(MSG_ONE, get_user_msgid("HostageK"), _, i);
		write_byte(1);	// hostage index
		message_end();
		
		client_cmd(i, "spk %s", COMMANDER_REVOKE_SFX);
	}
	
	print_chat_color(THE_COMMANDER, REDCHAT, "技能已结束！");
	
	remove_task(COMMANDER_TASK);
	g_rgbUsingSkill[THE_COMMANDER] = false;
	g_rgflSkillCooldown[THE_COMMANDER] = get_gametime() + get_pcvar_float(cvar_commanderCooldown);
}

public Commander_TerminateSkill()
{
	remove_task(COMMANDER_TASK);
	
	if (is_user_connected(THE_COMMANDER))
	{
		print_chat_color(THE_COMMANDER, REDCHAT, "技能已结束！");
		
		g_rgbUsingSkill[THE_COMMANDER] = false;
		g_rgflSkillCooldown[THE_COMMANDER] = get_gametime() + get_pcvar_float(cvar_commanderCooldown);
	}
}
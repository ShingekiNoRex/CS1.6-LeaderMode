/**

**/

#define THE_GODFATHER	g_iLeader[TEAM_TERRORIST - 1]
#define GODFATHER_TEXT	g_rgszRoleNames[Role_Godfather]
#define GODFATHER_TASK	3654861	// just some random number.

#define GODFATHER_GRAND_SFX		"leadermode/sfx_event_sainthood_01.wav"
#define GODFATHER_REVOKE_SFX	"leadermode/sfx_bloodline_add_bloodline_01.wav"

new g_iGodchildrenCount = 0, g_rgiGodchildren[33];
new Float:g_flGodfatherSavedHP = 1000.0, Float:g_rgflGodchildrenSavedHP[33];
new Float:g_rgflGodfatherHealingThink[33];
new cvar_godfatherRadius, cvar_godfatherDuration, cvar_godfatherCooldown, cvar_godfatherHealingInterval, cvar_godfatherHealingAmount;

public Godfather_Initialize()
{
	cvar_godfatherRadius	= register_cvar("lm_godfather_radius",		"250.0");
	cvar_godfatherDuration	= register_cvar("lm_godfather_duration",	"20.0");
	cvar_godfatherCooldown	= register_cvar("lm_godfather_cooldown",	"60.0");
	cvar_godfatherHealingInterval = register_cvar("lm_godfather_healing_interval", "5.0");
	cvar_godfatherHealingAmount = register_cvar("lm_godfather_healing_amount", "10.0");

	g_rgSkillDuration[Role_Godfather] = cvar_godfatherDuration;
	g_rgSkillCooldown[Role_Godfather] = cvar_godfatherCooldown;
}

public Godfather_Assign(pPlayer)
{
	new Float:flSucceedHealth = 1000.0;
	if (is_user_connected(THE_GODFATHER))	// deal with the old godfather...
	{
		new iAbdicator = THE_GODFATHER;
		
		emessage_begin(MSG_ALL, get_user_msgid("ScoreAttrib"));
		ewrite_byte(iAbdicator);
		ewrite_byte(0);
		emessage_end();
		
		g_rgPlayerRole[iAbdicator] = Role_UNASSIGNED;
		pev(iAbdicator, pev_health, flSucceedHealth);	// this health will be assign to new leader. prevents the confidence motion mechanism abused by players.

		set_pev(iAbdicator, pev_health, 100.0);
		set_pev(iAbdicator, pev_max_health, 100.0);
	}
	
	if (!is_user_alive(pPlayer))	// what if this guy was dead?
		ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);
	
	// LONG LIVE THE KING!
	THE_GODFATHER = pPlayer;
	pev(THE_GODFATHER, pev_netname, g_szLeaderNetname[TEAM_TERRORIST - 1], charsmax(g_szLeaderNetname[]));
	set_pev(THE_GODFATHER, pev_health, flSucceedHealth);
	set_pev(THE_GODFATHER, pev_max_health, 1000.0);

	new rgColor[3] = { 255, 100, 255 };
	new Float:flCoordinate[2] = { -1.0, 0.30 };
	new Float:rgflTime[4] = { 6.0, 6.0, 0.1, 0.2 };
	
	g_rgPlayerRole[THE_GODFATHER] = Role_Godfather;
	ShowHudMessage(THE_GODFATHER, rgColor, flCoordinate, 0, rgflTime, -1, "你已被選定為%s!", GODFATHER_TEXT);
	
	emessage_begin(MSG_ALL, get_user_msgid("ScoreAttrib"));
	ewrite_byte(THE_GODFATHER);	// head of TRs
	ewrite_byte(SCOREATTRIB_BOMB);
	emessage_end();
}

public Godfather_TerminateSkill()
{
	g_iGodchildrenCount = 0;
	remove_task(GODFATHER_TASK);
	
	if (is_user_connected(THE_GODFATHER))
		g_rgbUsingSkill[THE_GODFATHER] = false;
}

public Godfather_ExecuteSkill(pPlayer)
{
	// UNDONE: check skill usage status.
	
	g_iGodchildrenCount = 0;
	
	new iGodchild = -1, Float:vecOrigin[3];
	pev(pPlayer, pev_origin, vecOrigin);
	
	client_cmd(pPlayer, "spk %s", GODFATHER_GRAND_SFX);
	
	while ((iGodchild = engfunc(EngFunc_FindEntityInSphere, iGodchild, vecOrigin, get_pcvar_float(cvar_godfatherRadius))) > 0)
	{
		if (!is_user_connected(iGodchild))
			continue;
		
		if (get_pdata_int(iGodchild, m_iTeam) != TEAM_TERRORIST)	// UNDONE: godfather in CT...?
			continue;
		
		if (iGodchild == pPlayer)
			continue;
		
		g_iGodchildrenCount++;	// thus, the indexes are started from 1 and end with its exact number.
		g_rgiGodchildren[g_iGodchildrenCount] = iGodchild;
		
		client_cmd(iGodchild, "spk %s", GODFATHER_GRAND_SFX);
	}
	
	new Float:flGodfatherHealth, Float:flDividedHealth;
	pev(pPlayer, pev_health, flGodfatherHealth);
	
	flDividedHealth = flGodfatherHealth / (g_iGodchildrenCount + 1);	// the godfather should be included when partitioning occurs.
	
	g_flGodfatherSavedHP = flGodfatherHealth - flDividedHealth;	// at the end of skill, the godfather will only receive this delta-health.
	set_pev(pPlayer, pev_health, flDividedHealth);
	
	new Float:flGodchildHealth;
	for (new i = 1; i <= g_iGodchildrenCount; i++)
	{
		pev(g_rgiGodchildren[i], pev_health, flGodchildHealth);
		g_rgflGodchildrenSavedHP[g_rgiGodchildren[i]] = flGodchildHealth;
		set_pev(g_rgiGodchildren[i], pev_health, flGodchildHealth + flDividedHealth);
	}
	
	set_task(get_pcvar_float(cvar_godfatherDuration), "Godfather_RevokeSkill", GODFATHER_TASK);
	g_rgflSkillExecutedTime[pPlayer] = get_gametime();
}

public Godfather_RevokeSkill(iTaskId)
{
	// the death of godchildren will NOT stop the HP payback. this is the rule. intended.
	for (new i = 1; i <= g_iGodchildrenCount; i++)
	{
		if (is_user_alive(g_rgiGodchildren[i]))
		{
			set_pev(g_rgiGodchildren[i], pev_health, g_rgflGodchildrenSavedHP[g_rgiGodchildren[i]]);
			client_cmd(g_rgiGodchildren[i], "spk %s", GODFATHER_REVOKE_SFX);
		}
	}
	
	g_rgbUsingSkill[THE_GODFATHER] = false;
	g_rgflSkillCooldown[THE_GODFATHER] = get_gametime() + get_pcvar_float(cvar_godfatherCooldown);

	// the only way to stop it is the death of the Godfather
	if (is_user_alive(THE_GODFATHER))
	{
		new Float:flCurHealth;
		pev(THE_GODFATHER, pev_health, flCurHealth);
		set_pev(THE_GODFATHER, pev_health, flCurHealth + g_flGodfatherSavedHP);	// unlike his godchildren, the godfather will not have his original health back.
		
		client_cmd(THE_GODFATHER, "spk %s", GODFATHER_REVOKE_SFX);
		print_chat_color(THE_GODFATHER, REDCHAT, "技能已结束！");
	}
	
	// g_iGodchildrenCount == 0 could be an indicator of the skill usage status ???
	// what if skill was fail due to nobody near Godfather?
	g_iGodchildrenCount = 0;
}

public Godfather_HealingThink(iPlayer)		// place at PlayerPostThink()
{
	// please do the team check before calling this!

	if (!is_user_alive(THE_GODFATHER) || iPlayer == THE_GODFATHER)
		return;

	static Float:fCurTime;
	global_get(glb_time, fCurTime);
	if (g_rgflGodfatherHealingThink[iPlayer] > fCurTime)
		return;

	static Float:vecGFOrigin[3], Float:vecPlayerOrigin[3];
	pev(THE_GODFATHER, pev_origin, vecGFOrigin);
	pev(iPlayer, pev_origin, vecPlayerOrigin);
	if (get_distance_f(vecGFOrigin, vecPlayerOrigin) > get_pcvar_float(cvar_godfatherRadius))
		return;

	g_rgflGodfatherHealingThink[iPlayer] = fCurTime + get_pcvar_float(cvar_godfatherHealingInterval);

	new Float:flCurHealth;
	pev(iPlayer, pev_health, flCurHealth);

	if (flCurHealth < 100.0)
	{
		flCurHealth += get_pcvar_float(cvar_godfatherHealingAmount);
		if (flCurHealth > 100.0)
			flCurHealth = 100.0

		set_pev(iPlayer, pev_health, flCurHealth);
	}
}

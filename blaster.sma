/**

**/

#define BLASTER_TEXT	g_rgszRoleNames[Role_Blaster]
#define BLASTER_TASK	5971543	// just some random number.

new g_smodelindexfireball[2];
new cvar_blasterDuration, cvar_blasterCooldown, cvar_explosionDamage, cvar_explosionRange;

public Blaster_Initialize()
{
	cvar_blasterDuration	= register_cvar("lm_blaster_duration",	"5.0");
	cvar_blasterCooldown	= register_cvar("lm_blaster_cooldown",	"30.0");
	cvar_explosionDamage	= register_cvar("lm_blaster_explosion_damage", "100.0");
	cvar_explosionRange		= register_cvar("lm_blaster_explosion_range", "100.0");

	g_rgSkillDuration[Role_Blaster] = cvar_blasterDuration;
	g_rgSkillCooldown[Role_Blaster] = cvar_blasterCooldown;
}

public Blaster_Precache()
{
	g_smodelindexfireball[0] = engfunc(EngFunc_PrecacheModel, "sprites/eexplo.spr");
	g_smodelindexfireball[1] = engfunc(EngFunc_PrecacheModel, "sprites/fexplo.spr");
}

public Blaster_ExecuteSkill(pPlayer)
{
	fm_give_item(pPlayer, "weapon_hegrenade");
	set_task(get_pcvar_float(cvar_blasterDuration), "Blaster_RevokeSkill", BLASTER_TASK + pPlayer);
}

public Blaster_RevokeSkill(iTaskId)
{
	new iPlayer = iTaskId - BLASTER_TASK;
	if (!is_user_connected(iPlayer))
		return;

	if (g_rgPlayerRole[iPlayer] != Role_Blaster)
		return;

	g_rgbUsingSkill[iPlayer] = false;
	g_rgflSkillCooldown[iPlayer] = get_gametime() + get_pcvar_float(cvar_blasterCooldown);
	print_chat_color(iPlayer, REDCHAT, "技能已结束！");
}

public Blaster_Explosion(iPlayer)
{
	static Float:origin[3];
	pev(iPlayer, pev_origin, origin);
	new i = -1;
	while ((i = engfunc(EngFunc_FindEntityInSphere, i, origin, get_pcvar_float(cvar_explosionRange))) > 0)
	{
		if (!pev_valid(i) || iPlayer == i)
			continue;

		if (pev(i, pev_takedamage) == DAMAGE_NO)
			continue;

		static classname[32];
		pev(i, pev_classname, classname, charsmax(classname));
		if (!strcmp(classname, "func_breakable"))
		{
			ExecuteHamB(Ham_TakeDamage, i, iPlayer, iPlayer, get_pcvar_float(cvar_explosionDamage), DMG_BLAST);
			continue;
		}

		new Float:origin2[3];
		pev(i, pev_origin, origin2);

		new Float:damage = floatclamp(get_pcvar_float(cvar_explosionDamage)*(1.0 - (get_distance_f(origin2, origin) - 21.0) / get_pcvar_float(cvar_explosionRange)), 0.0, get_pcvar_float(cvar_explosionDamage));
		if (damage == 0.0)
			continue;

		ExecuteHamB(Ham_TakeDamage, i, iPlayer, iPlayer, damage, DMG_BLAST);
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + 25.0);
	write_short(g_smodelindexfireball[1]);
	write_byte(clamp(floatround(get_pcvar_float(cvar_explosionRange) / 6.0), 10, 30));
	write_byte(50);
	write_byte(TE_EXPLFLAG_NONE);
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + random_float(30.0, 35.0));
	write_short(g_smodelindexfireball[0]);
	write_byte(clamp(floatround(get_pcvar_float(cvar_explosionRange) / 6.0), 10, 30));
	write_byte(30);
	write_byte(TE_EXPLFLAG_NONE);
	message_end();
}
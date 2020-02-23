/**

negative effect would be cancel when stay in the smoke
**/

#define MEDIC_TASK	5687361

#define HEALING_GRENADE_ENTITY	"healing_grenade"

#define HEALING_SFX				"leadermode/choosecountry%d.wav"
#define HEALINGSHOT_SFX			"leadermode/healsound.wav"
#define HEALING_VFX				"sprites/leadermode/heal.spr"
#define HEALING_FULL_SFX		"leadermode/Building_Completed.wav"
#define OVERHEALING_DECAY_SFX	"leadermode/click_01.wav"
#define MEDIC_SKILL_SFX			"leadermode/diplomacy_panel.wav"

#define RANDOM_IN_ARRAY(%1)		%1[random_num(0, sizeof %1)]

new cvar_medicHGAmount, cvar_medicHGInterval, cvar_medicOHLimit, cvar_medicOHDecayInv, cvar_medicOHDecayAmt;
new Float:g_rgflOverhealingThink[33];
new bool:g_rgbShootingHealingDart[33];
new Float:g_flCommanderOHThink, Float:g_flCommanderOriginalHP;
new g_idHealingSpr;

public Medic_Initialize()
{
	cvar_medicHGAmount		= register_cvar("lm_medic_healing_gr_amount",	"5.0");
	cvar_medicHGInterval	= register_cvar("lm_medic_healing_gr_inv",		"2.0");
	cvar_medicOHLimit		= register_cvar("lm_medic_overhealing_limit",	"200.0");
	cvar_medicOHDecayInv	= register_cvar("lm_medic_overhealing_decayInv","1.0");
	cvar_medicOHDecayAmt	= register_cvar("lm_medic_overhealing_decayAmt","1.0");
}

public Medic_Precache()
{
	precache_sound(HEALING_FULL_SFX);
	precache_sound(HEALINGSHOT_SFX);
	precache_sound(OVERHEALING_DECAY_SFX);
	precache_sound(MEDIC_SKILL_SFX);
	
	static szHealingSFX[48];
	for (new i = 1; i <= 10; i++)
	{
		formatex(szHealingSFX, charsmax(szHealingSFX), HEALING_SFX, i);
		precache_sound(szHealingSFX);
	}
	
	g_idHealingSpr = precache_model(HEALING_VFX);
}

public Command_DamageOther(pPlayer)
{
	if (!get_pcvar_num(cvar_DebugMode))
		return PLUGIN_CONTINUE;

	get_aiming_trace(pPlayer);
	
	new iEntity = get_tr2(0, TR_pHit);
	if (is_user_alive(iEntity))
		set_pev(iEntity, pev_health, 50.0);
	
	return PLUGIN_HANDLED;
}

public HealingGrenade_Think(iEntity)
{
	static Float:flTimeRemove;
	pev(iEntity, pev_fuser1, flTimeRemove);
	
	if (flTimeRemove < get_gametime())
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return;
	}

	static Float:vecOrigin[3];
	pev(iEntity, pev_origin, vecOrigin);
	
	static iMedicPlayer;
	iMedicPlayer = pev(iEntity, pev_iuser4);
	
	new pPlayer = -1, Float:vecVictimOrigin[3], Float:flHealth, Float:flMaxHealth;
	while ((pPlayer = engfunc(EngFunc_FindEntityInSphere, pPlayer, vecOrigin, 280.0)) > 0)
	{
		if (!is_user_connected(pPlayer))
			continue;
		
		pev(pPlayer, pev_origin, vecVictimOrigin);
		if (!UTIL_PointVisible(vecOrigin, vecVictimOrigin, IGNORE_MONSTERS))
			continue;
		
		if (pPlayer == THE_GODFATHER)	// never heal the godfather.
			continue;
		
		pev(pPlayer, pev_health, flHealth);
		pev(pPlayer, pev_max_health, flMaxHealth);
		
		if (pPlayer == THE_COMMANDER)	// but we can overheal commander.
		{
			if (g_flCommanderOHThink <= 0.0)
				g_flCommanderOriginalHP = flHealth;
			
			g_flCommanderOHThink = get_gametime() + get_pcvar_float(cvar_medicOHDecayInv) + get_pcvar_float(cvar_medicHGInterval);
			
			new Float:flLastHealth = flHealth;
			flHealth += get_pcvar_float(cvar_medicHGAmount);
			set_pev(pPlayer, pev_health, flHealth);
			HealingGrenade_SFX(pPlayer);
			
			client_cmd(iMedicPlayer, "spk %s", SFX_TSD_GBD);
			UTIL_AddAccount(iMedicPlayer, floatround(flHealth - flLastHealth) / 2);
			
			continue;
		}
		
		if (flHealth >= flMaxHealth)	// reach the default maxium health.
		{
			if (flHealth < get_pcvar_float(cvar_medicOHLimit))	// continue overhealing.
			{
				new Float:flLastHealth = flHealth;
				flHealth = floatmin(flHealth + get_pcvar_float(cvar_medicHGAmount), get_pcvar_float(cvar_medicOHLimit));
				set_pev(pPlayer, pev_health, flHealth);
				
				client_cmd(iMedicPlayer, "spk %s", SFX_TSD_GBD);
				UTIL_AddAccount(iMedicPlayer, floatround(flHealth - flLastHealth) / 2);	// only give half of money if the medic is overhealing player.
				g_rgflOverhealingThink[pPlayer] = get_gametime() + get_pcvar_float(cvar_medicOHDecayInv) + get_pcvar_float(cvar_medicHGInterval);	// prevents player both add and reduce health in healing smoke.
				
				if (flHealth >= get_pcvar_float(cvar_medicOHLimit))
					engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, HEALING_FULL_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				else
					HealingGrenade_SFX(pPlayer);
			}
		}
		else	// normal healing
		{
			new Float:flLastHealth = flHealth;
			flHealth = floatmin(flHealth + get_pcvar_float(cvar_medicHGAmount), flMaxHealth);
			set_pev(pPlayer, pev_health, flHealth);
			
			Healing_VFX(pPlayer);
			client_cmd(iMedicPlayer, "spk %s", SFX_TSD_GBD);
			UTIL_AddAccount(iMedicPlayer, floatround(flHealth - flLastHealth));
			
			if (flHealth >= flMaxHealth)
				engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, HEALING_FULL_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			else
				HealingGrenade_SFX(pPlayer);
		}
	}
	
	set_pev(iEntity, pev_nextthink, get_gametime() + get_pcvar_float(cvar_medicHGInterval));
}

public Overhealing_Think(pPlayer)
{
	if (g_rgflOverhealingThink[pPlayer] <= 0.0)
		return;
	
	if (g_rgflOverhealingThink[pPlayer] > get_gametime())
		return;
	
	static Float:flHealth, Float:flMaxHealth;
	pev(pPlayer, pev_health, flHealth);
	pev(pPlayer, pev_max_health, flMaxHealth);
	
	if (flHealth <= flMaxHealth)
	{
		g_rgflOverhealingThink[pPlayer] = 0.0;
		return;
	}
	
	g_rgflOverhealingThink[pPlayer] = get_gametime() + get_pcvar_float(cvar_medicOHDecayInv);
	
	flHealth -= get_pcvar_float(cvar_medicOHDecayAmt);
	set_pev(pPlayer, pev_health, flHealth);
	
	client_cmd(pPlayer, "spk %s", OVERHEALING_DECAY_SFX);
}

public CommanderOH_Think()
{
	if (!is_user_alive(THE_COMMANDER))	// new round bugfix.
	{
		g_flCommanderOHThink = 0.0;
		return;
	}
	
	if (g_flCommanderOHThink <= 0.0)
		return;
	
	if (g_flCommanderOHThink > get_gametime())
		return;
		
	static Float:flHealth;
	pev(THE_COMMANDER, pev_health, flHealth);
	
	if (flHealth <= g_flCommanderOriginalHP)
	{
		g_flCommanderOHThink = 0.0;
		return;
	}
	
	g_flCommanderOHThink = get_gametime() + get_pcvar_float(cvar_medicOHDecayInv);
	
	flHealth -= get_pcvar_float(cvar_medicOHDecayAmt);
	set_pev(THE_COMMANDER, pev_health, flHealth);
	
	client_cmd(THE_COMMANDER, "spk %s", OVERHEALING_DECAY_SFX);
}

Healing_VFX(pPlayer)
{
	static Float:vecOrigin[3];
	pev(pPlayer, pev_origin, vecOrigin);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(g_idHealingSpr);
	write_byte(10);
	write_byte(255);
	message_end();
}

ShotHeal_FX(pPlayer)
{
	Healing_VFX(pPlayer);
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, HEALINGSHOT_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

HealingGrenade_SFX(pPlayer)
{
	new szHealingSFX[48];
	formatex(szHealingSFX, charsmax(szHealingSFX), HEALING_SFX, random_num(1, 10));
	client_cmd(pPlayer, "spk %s", szHealingSFX);
}

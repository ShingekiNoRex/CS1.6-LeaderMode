/**

**/

#define MEDIC_TASK	5687361

#define HEALING_GRENADE_ENTITY	"healing_grenade"

new cvar_medicHGAmount, cvar_medicHGInterval, cvar_medicOHLimit, cvar_medicOHDecayInv, cvar_medicOHDecayAmt;
new Float:g_rgflOverhealingThink[33];

public Medic_Initialize()
{
	cvar_medicHGAmount		= register_cvar("lm_medic_healing_gr_amount",	"5.0");
	cvar_medicHGInterval	= register_cvar("lm_medic_healing_gr_inv",		"2.0");
	cvar_medicOHLimit		= register_cvar("lm_medic_overhealing_limit",	"200.0");
	cvar_medicOHDecayInv	= register_cvar("lm_medic_overhealing_decayInv","1.0");
	cvar_medicOHDecayAmt	= register_cvar("lm_medic_overhealing_decayAmt","1.0");
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
	
	new pPlayer = -1, Float:vecVictimOrigin[3], Float:flHealth, bResult;
	while ((pPlayer = engfunc(EngFunc_FindEntityInSphere, pPlayer, vecOrigin, 280.0)) > 0)
	{
		if (!is_user_connected(pPlayer))
			continue;
		
		pev(pPlayer, pev_origin, vecVictimOrigin);
		if (!UTIL_PointVisible(vecOrigin, vecVictimOrigin, IGNORE_MONSTERS))
			continue;
		
		if (pPlayer == THE_GODFATHER || pPlayer == THE_COMMANDER)	// never heal these two.
			continue;
		
		bResult = ExecuteHamB(Ham_TakeHealth, pPlayer, this, Float:health, damagebits);
		
		if (!bResult)	// reach the default maxium health.
		{
			pev(pPlayer, pev_health, flHealth);
			flHealth = floatclamp(flHealth + get_pcvar_float(cvar_medicHGAmount), 0.0, get_pcvar_float(cvar_medicOHLimit));
		}
	}
	
	set_pev(iEntity, pev_nextthink, get_gametime() + 0.1);
}
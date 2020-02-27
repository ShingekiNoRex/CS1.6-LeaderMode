/**

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

public Command_Harm(pPlayer)
{
	if (!get_pcvar_num(cvar_DebugMode))
		return PLUGIN_CONTINUE;
	
	set_pev(pPlayer, pev_health, 50.0);
	
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
	
	new pPlayer = -1, /*Float:vecVictimOrigin[3],*/ Float:flHealth, Float:flMaxHealth;
	while ((pPlayer = engfunc(EngFunc_FindEntityInSphere, pPlayer, vecOrigin, 280.0)) > 0)
	{
		if (!is_user_alive2(pPlayer))
			continue;
		
		/*
		pev(pPlayer, pev_origin, vecVictimOrigin);
		if (!UTIL_PointVisible(vecOrigin, vecVictimOrigin, IGNORE_MONSTERS))
			continue;
		*/
		
		if (pPlayer == THE_GODFATHER)	// never heal the godfather.
			continue;
		
		// clear debuff and rmeove DOTs. (not godfather)
		if (g_rgflFrozenNextthink[pPlayer] > 0.0)	// player is frozen.
			Sharpshooter_SetFree(pPlayer);
		
		if (g_rgPlayerRole[pPlayer] == Role_Berserker && g_rgbUsingSkill[pPlayer])	// terminate berserker's skill.
			Berserker_TerminateSkill(pPlayer);
		
		if (g_rgflPlayerElectrified[pPlayer] > 0.0)	// remove electrified state.
			g_rgflPlayerElectrified[pPlayer] = 1.0;
		
		if (g_rgflPlayerPoisoned[pPlayer] > 0.0)	// remove poisoned state.
			g_rgflPlayerPoisoned[pPlayer] = 1.0;
		
		if (g_rgPlayerRole[pPlayer] == Role_Assassin && g_rgbUsingSkill[pPlayer])
			Assassin_Revealed(pPlayer, iMedicPlayer);
		
		// start the healing job,
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

new Float:g_rgflMedicBotThink[33], Float:g_rgflMedicGrenadeThrow[33];

public Medic_BotThink(pPlayer)
{
	// throw medic grenade to player when they are under control of DOTs.
	// heal player with their DEAGLE or ANACONDA.
	
	if (!is_user_bot(pPlayer) || g_rgflMedicBotThink[pPlayer] > get_gametime() || !g_bRoundStarted || !is_user_alive(pPlayer))
		return;
	
	new Float:vecOrigin[3], Float:vecVictimOrigin[3];
	pev(pPlayer, pev_origin, vecOrigin);
	pev(pPlayer, pev_view_ofs, vecVictimOrigin);
	xs_vec_add(vecOrigin, vecVictimOrigin, vecOrigin);
	
	new Float:flHealth;
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_alive2(i))
			continue;
		
		if (i == THE_GODFATHER)
			continue;
		
		pev(i, pev_origin, vecVictimOrigin);
		if (!UTIL_PointVisible(vecOrigin, vecVictimOrigin, IGNORE_MONSTERS))
			continue;
		
		pev(i, pev_health, flHealth);
		if (i == THE_COMMANDER || i == pPlayer)
		{
			new Float:flMaxHealth;
			pev(i, pev_max_health, flMaxHealth);
			
			if (flHealth / flMaxHealth <= 0.5 && g_rgflMedicGrenadeThrow[pPlayer] <= get_gametime())
			{
				new Float:vecDir[3], Float:vecVAngle[3];
				vecVictimOrigin[2] += 36.0;	// consider the arc.
				xs_vec_sub(vecVictimOrigin, vecOrigin, vecDir);
				engfunc(EngFunc_VecToAngles, vecDir, vecVAngle);
				vecVAngle[0] *= -1.0;
				set_pev(pPlayer, pev_angles, vecVAngle);
				set_pev(pPlayer, pev_v_angle, vecVAngle);
				set_pev(pPlayer, pev_fixangle, 1);
				
				Bot_ForceGrenadeThrow(pPlayer, CSW_SMOKEGRENADE);
				g_rgflMedicGrenadeThrow[pPlayer] = get_gametime() + 5.0;
			}
			
			break;
		}
		
		if (g_rgflFrozenNextthink[pPlayer] > 0.0			// player is frozen.
			|| g_rgflPlayerElectrified[pPlayer] > 0.0		// is electrified.
			|| g_rgflPlayerPoisoned[pPlayer] > 0.0			// is poisoned.
			|| (flHealth < 120.0 && get_pdata_int(i, m_iTeam) == TEAM_CT)				// or some bleeding teammates
			|| (g_rgPlayerRole[pPlayer] == Role_Berserker && g_rgbUsingSkill[pPlayer]))	// or just a random freaking guy.
		{
			new iEntity = get_pdata_cbase(pPlayer, m_rgpPlayerItems[2]);
			
			if (pev_valid(iEntity) == 2 && ((1<<get_pdata_int(iEntity, m_iId)) & ((1<<CSW_DEAGLE)|(1<<CSW_ANACONDA))) )
			{
				// you got a heal gun, then use it.
				SelectItem(pPlayer, g_rgszWeaponEntity[get_pdata_int(iEntity, m_iId)]);
			}
			else
			{
				// you don't get one? find, I would get you one.
				
				new iId = random_num(0, 1) ? CSW_ANACONDA : CSW_DEAGLE;
				
				DropWeapons(pPlayer, 2);
				fm_give_item(pPlayer, g_rgszWeaponEntity[iId]);
				SelectItem(pPlayer, g_rgszWeaponEntity[iId]);
				
				iEntity = get_pdata_cbase(pPlayer, m_pActiveItem);
			}
			
			new Float:vecDir[3], Float:vecVAngle[3];
			xs_vec_sub(vecVictimOrigin, vecOrigin, vecDir);
			engfunc(EngFunc_VecToAngles, vecDir, vecVAngle);
			vecVAngle[0] *= -1.0;
			set_pev(pPlayer, pev_angles, vecVAngle);
			set_pev(pPlayer, pev_v_angle, vecVAngle);
			set_pev(pPlayer, pev_fixangle, 1);
			
			//set_pev(pPlayer, pev_button, pev(pPlayer, pev_button) | IN_ATTACK);	// I don't know why, but it just doesn't work.
			set_pdata_int(iEntity, m_iClip, 7);
			g_rgbShootingHealingDart[pPlayer] = true;
			ExecuteHamB(Ham_Weapon_PrimaryAttack, iEntity);
			g_rgbShootingHealingDart[pPlayer] = false;
			
			// one problen per time.
			break;
		}
	}
	
	g_rgflMedicBotThink[pPlayer] = get_gametime() + 1.0;
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

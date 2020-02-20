/**

**/



#define SWAT_TASK	2867926

#define SWAT_GRAND_SFX		"leadermode/merge_army_fleet.wav"
#define SWAT_REVOKE_SFX		"leadermode/illegal_move.wav"
#define SWAT_PASSIVE_SFX	"leadermode/select_army.wav"

new cvar_swatBulletproofCD, cvar_swatBulletproofLast;
new cvar_swatArmourMax, cvar_swatBulletproofRatio;
new cvar_swatArmourRegenInv, cvar_swatArmourRegenAmt, cvar_swatArmourRegenRad;

new Float:g_rgflSWATArmourRegenThink[33];

public SWAT_Initialize()
{
	cvar_swatArmourMax			= register_cvar("lm_SWAT_armour_value_max",	"200.0");
	cvar_swatArmourRegenAmt		= register_cvar("lm_SWAT_armour_regen_amt",	"10.0");
	cvar_swatArmourRegenInv		= register_cvar("lm_SWAT_armour_regen_inv", "5.0");
	cvar_swatArmourRegenRad		= register_cvar("lm_SWAT_armour_regen_rad",	"250.0");
	cvar_swatBulletproofCD		= register_cvar("lm_SWAT_bulletproof_cd",	"40.0");
	cvar_swatBulletproofLast	= register_cvar("lm_SWAT_bulletproof_last",	"15.0");
	cvar_swatBulletproofRatio	= register_cvar("lm_SWAT_bulletproof_ratio","0.9");
	
	g_rgSkillDuration[Role_SWAT] = cvar_swatBulletproofLast;
	g_rgSkillCooldown[Role_SWAT] = cvar_swatBulletproofCD;
}

public SWAT_Precache()
{
	precache_sound(SWAT_GRAND_SFX);
	precache_sound(SWAT_REVOKE_SFX);
	precache_sound(SWAT_PASSIVE_SFX);
}

public SWAT_ExecuteSkill(pPlayer)
{
	set_task(get_pcvar_float(cvar_swatBulletproofLast), "SWAT_RevokeSkill", SWAT_TASK + pPlayer);
	
	fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_FLASHBANG]);
	fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_FLASHBANG]);
	fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_SMOKEGRENADE]);
	fm_give_item(pPlayer, "item_assaultsuit");
	
	new iPrimaryWeapon = get_pdata_cbase(pPlayer, m_rgpPlayerItems[1]);
	new iSecondaryWeapon = get_pdata_cbase(pPlayer, m_rgpPlayerItems[2]);
	
	if (pev_valid(iPrimaryWeapon) == 2)
	{
		set_pdata_int(iPrimaryWeapon, m_iClip, g_rgiWeaponMaxClip[get_pdata_int(iPrimaryWeapon, m_iId, 4)], 4);
		ExecuteHamB(Ham_GiveAmmo, pPlayer, 240, g_rgszAmmoNameByIndex[get_pdata_int(iPrimaryWeapon, m_iPrimaryAmmoType, 4)], 240);	// I don't care the iAmmoCapacityMax here is because that we have another plugin is managing ammomaxes.
	}
	
	if (pev_valid(iSecondaryWeapon) == 2)
	{
		set_pdata_int(iSecondaryWeapon, m_iClip, g_rgiWeaponMaxClip[get_pdata_int(iSecondaryWeapon, m_iId, 4)], 4);
		ExecuteHamB(Ham_GiveAmmo, pPlayer, 240, g_rgszAmmoNameByIndex[get_pdata_int(iSecondaryWeapon, m_iPrimaryAmmoType, 4)], 240);
	}
	
	UTIL_ScreenFade(pPlayer, 0.5, get_pcvar_float(cvar_swatBulletproofLast), FFADE_IN, 179, 217, 255, 60);
	client_cmd(pPlayer, "spk %s", SWAT_GRAND_SFX);
}

public SWAT_RevokeSkill(iTaskId)
{
	new pPlayer = iTaskId - SWAT_TASK;
	
	if (!is_user_alive(pPlayer))
		return;
	
	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_swatBulletproofCD);
	print_chat_color(pPlayer, BLUECHAT, "技能已结束！");
	client_cmd(pPlayer, "spk %s", SWAT_REVOKE_SFX);
}

public SWAT_TerminateSkill(pPlayer)
{
	remove_task(SWAT_TASK + pPlayer);
	SWAT_RevokeSkill(SWAT_TASK + pPlayer);
}

public SWAT_SkillThink(pPlayer)	// place at PlayerPostThink()
{
	if (g_rgPlayerRole[pPlayer] != Role_SWAT)
		return;
	
	if (g_rgflSWATArmourRegenThink[pPlayer] > get_gametime())
		return;
	
	static Float:vecOrigin[3];
	pev(pPlayer, pev_origin,vecOrigin);
	
	new iEntity = -1, Float:flArmourValue, Float:flMax;
	while ((iEntity = engfunc(EngFunc_FindEntityInSphere, iEntity, vecOrigin, get_pcvar_float(cvar_swatArmourRegenRad))) > 0)
	{
		if (!is_user_alive(iEntity) || !is_user_connected(iEntity))
			continue;
		
		if (iEntity == pPlayer)
			continue;
		
		pev(iEntity, pev_armorvalue, flArmourValue);
		flMax = 100.0;
		
		if (g_rgPlayerRole[iEntity] == Role_SWAT)
			flMax = get_pcvar_float(cvar_swatArmourMax);
		
		if (flArmourValue < flMax)
		{
			flArmourValue = floatclamp(flArmourValue + get_pcvar_float(cvar_swatArmourRegenAmt), 0.0, flMax);
			set_pev(iEntity, pev_armorvalue, flArmourValue);
			
			if (!get_pdata_int(iEntity, m_iKevlar))
				set_pdata_int(iEntity, m_iKevlar, 1);
			
			client_cmd(iEntity, "spk %s", SWAT_PASSIVE_SFX);
		}
		else if (get_pdata_int(iEntity, m_iKevlar) == 1)	// no one will reach here unless their armour is full.
		{
			set_pdata_int(iEntity, m_iKevlar, 2);
			client_cmd(iEntity, "spk %s", SWAT_PASSIVE_SFX);
			
			emessage_begin(MSG_ONE, get_user_msgid("ItemPickup"), _, iEntity);
			ewrite_string("item_assaultsuit");
			emessage_end();
			
			emessage_begin(MSG_ONE, get_user_msgid("ArmorType"), _, iEntity);
			ewrite_byte(1);
			emessage_end();
		}
	}
	
	g_rgflSWATArmourRegenThink[pPlayer] = get_gametime() + get_pcvar_float(cvar_swatArmourRegenInv);
}
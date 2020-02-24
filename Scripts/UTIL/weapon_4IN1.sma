/* ammx编写头版 by Devzone */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <offset>
#include <orpheu>

#define PLUGIN_NAME		"Weapon Stats Configuration"
#define PLUGIN_VERSION	"1.5.2 (11 in 1)"
#define PLUGIN_AUTHOR	"Luna the Reborn"

#define ITEM_FLAG_SELECTONEMPTY		1
#define ITEM_FLAG_NOAUTORELOAD		2
#define ITEM_FLAG_NOAUTOSWITCHEMPTY	4
#define ITEM_FLAG_LIMITINWORLD		8
#define ITEM_FLAG_EXHAUSTIBLE		16	// A player can totally exhaust their ammo supply and lose this weapon.

enum PLAYER_ANIM
{
	PLAYER_IDLE,
	PLAYER_WALK,
	PLAYER_JUMP,
	PLAYER_SUPERJUMP,
	PLAYER_DIE,
	PLAYER_ATTACK1,
	PLAYER_ATTACK2,
	PLAYER_FLINCH,
	PLAYER_LARGE_FLINCH,
	PLAYER_RELOAD,
	PLAYER_HOLDBOMB
};

stock const g_rgszWeaponEntity[][] =
{
	"",
	"weapon_p228",
	"",
	"weapon_scout",
	"weapon_hegrenade",
	"weapon_xm1014",
	"weapon_c4",
	"weapon_mac10",
	"weapon_aug",
	"weapon_smokegrenade",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_flashbang",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_knife",
	"weapon_p90"
};
stock const g_rgszWeaponName[][] = { "", "p228", "", "scout", "hegrenade", "xm1014", "c4", "mac10", "aug", "smokegrenade", "elite", "fiveseven", "ump45", "sg550", "galil", "famas", "usp", "glock18", "awp", "mp5", "m249", "m3", "m4a1", "tmp", "g3sg1", "flashbang", "deagle", "sg552", "ak47", "knife", "p90" };
stock const g_rgiDefaultMaxClip[] = { -1,  13, -1, 10,  1,  7,  1, 30, 30,  1,  30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8 , 30, 30, 20,  2,  7, 30, 30, -1,  50 };
stock const g_rgszAmmoNameByIndex[][] =
{
	"",				// 0
	"338Magnum",
	"762Nato",
	"556NatoBox",
	"556Nato",
	"buckshot",		// 5
	"45acp",
	"57mm",
	"50AE",
	"357SIG",
	"9mm",			// 10
	"Flashbang",
	"HEGrenade",
	"SmokeGrenade",
	"C4"
	// ARRAY SIZE: 15
};
stock const g_rgszAmmoEntityNameByIndex[][] =
{
	"",				// 0
	"ammo_338magnum",
	"ammo_762nato",
	"ammo_556natobox",
	"ammo_556nato",
	"ammo_buckshot",		// 5
	"ammo_45acp",
	"ammo_57mm",
	"ammo_50ae",
	"ammo_357sig",
	"ammo_9mm"			// 10
};
stock const g_rgszAmmoDefaultMaxByIndex[] = { -1, 30, 90, 200, 90, 32, 100, 100, 35, 52, 120, 2, 1, 1, 1 };

new cvar_rate[CSW_P90+1], cvar_recoil[CSW_P90+1];								//use ham pri attack
new cvar_deploy[CSW_P90+1], cvar_reload[CSW_P90+1];								//use ham deploy | reload | add to player
new cvar_walkspeed[CSW_P90 + 1], cvar_zoomingwalkspeed[CSW_P90 + 1];			// HamF_CS_Item_GetMaxSpeed
new cvar_clip[CSW_P90+1];														//use ham spawn & reload & item post frame
new cvar_damageMul[CSW_P90+1], cvar_damageAdd[CSW_P90+1], cvar_knock[CSW_P90+1], cvar_maxdist[CSW_P90+1];		//use ham trace attack
new cvar_accuracy[CSW_P90+1];													//use fm playback event | UpdateClientData | trace line
new cvar_ammomax[15], cvar_ammoperbox[15];										// HAM_GiveAmmo
new cvar_start_reload[CSW_P90+1], cvar_after_reload[CSW_P90+1], cvar_chamberadd[CSW_P90+1];	// these are Shotgun vars.

new g_fwBotForwardRegister;
new g_bFabricateBPAmmoData = false;
new bool:g_rgbReloadBugTrigger[33], bool:g_rgbShooting[33], g_rgiIdActiveWeapon[33], g_iAmmoBuffer[15], bool:g_bAmmoBufferFix[15], bool:g_bPickingAmmo[33];
new OrpheuFunction:g_pfn_CBPW_SendWeaponAnim[CSW_P90+1], OrpheuFunction:g_pfn_CBP_SetAnimation, OrpheuFunction:g_pfn_CBPW_ReloadSound;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	// put orpheu before everything.
	// why? that's because if the user haven't install orpheu module, this two line would stop the entire plugin initiation.
	// thus, it can protect the user from a game which aggravates further.
	g_pfn_CBP_SetAnimation = OrpheuGetFunction("SetAnimation", "CBasePlayer");
	g_pfn_CBPW_ReloadSound = OrpheuGetFunction("ReloadSound", "CBasePlayerWeapon");
	
	// weapon HAM hook reg.
	new szCvarName[64];
	for (new i = 0; i < sizeof g_rgszWeaponEntity; i++)
	{
		if (!g_rgszWeaponName[i][0])
			continue;
		
		if (i == CSW_C4 || i == CSW_HEGRENADE || i == CSW_KNIFE || i == CSW_SMOKEGRENADE || i == CSW_FLASHBANG)
			continue;
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_firerate", g_rgszWeaponName[i]);
		cvar_rate[i] = register_cvar(szCvarName, "-1.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_recoil", g_rgszWeaponName[i]);
		cvar_recoil[i] = register_cvar(szCvarName, "-1.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_deploy_time", g_rgszWeaponName[i]);
		cvar_deploy[i] = register_cvar(szCvarName, "-1.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_reload_time", g_rgszWeaponName[i]);
		cvar_reload[i] = register_cvar(szCvarName, "-1.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_walkspeed", g_rgszWeaponName[i]);
		cvar_walkspeed[i] = register_cvar(szCvarName, "-1.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_zoomingwalkspeed", g_rgszWeaponName[i]);
		cvar_zoomingwalkspeed[i] = register_cvar(szCvarName, "-1.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_maxclip", g_rgszWeaponName[i]);
		cvar_clip[i] = register_cvar(szCvarName, "0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_damagemul", g_rgszWeaponName[i]);
		cvar_damageMul[i] = register_cvar(szCvarName, "1.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_damageadd", g_rgszWeaponName[i]);
		cvar_damageAdd[i] = register_cvar(szCvarName, "0.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_knock", g_rgszWeaponName[i]);
		cvar_knock[i] = register_cvar(szCvarName, "-1.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_shoot_maxdist", g_rgszWeaponName[i]);
		cvar_maxdist[i] = register_cvar(szCvarName, "-1.0");
		
		formatex(szCvarName, charsmax(szCvarName), "weap_%s_accuracy", g_rgszWeaponName[i]);
		cvar_accuracy[i] = register_cvar(szCvarName, "1.0");
		
		RegisterHam(Ham_Spawn, g_rgszWeaponEntity[i], "HamF_WeaponSpawn_Post", 1);
		RegisterHam(Ham_CS_Item_GetMaxSpeed, g_rgszWeaponEntity[i], "HamF_CS_Item_GetMaxSpeed");
		RegisterHam(Ham_Item_AddToPlayer, g_rgszWeaponEntity[i], "HamF_Item_AddToPlayer_Post", 1);
		RegisterHam(Ham_Item_Deploy, g_rgszWeaponEntity[i], "HamF_Item_Deploy_Post", 1);
		RegisterHam(Ham_Weapon_PrimaryAttack, g_rgszWeaponEntity[i], "HamF_Weapon_PrimaryAttack");
		RegisterHam(Ham_Weapon_PrimaryAttack, g_rgszWeaponEntity[i], "HamF_Weapon_PrimaryAttack_Post", 1);
		RegisterHam(Ham_Item_PostFrame, g_rgszWeaponEntity[i], "HamF_Item_PostFrame");
		RegisterHam(Ham_Item_PrimaryAmmoIndex, g_rgszWeaponEntity[i], "HamF_Item_PrimaryAmmoIndex_Post", 1);
		
		if (i != CSW_M3 && i != CSW_XM1014)
		{
			RegisterHam(Ham_Weapon_Reload, g_rgszWeaponEntity[i], "HamF_Weapon_Reload");
			RegisterHam(Ham_Weapon_Reload, g_rgszWeaponEntity[i], "HamF_Weapon_Reload_Post", 1);
		}
		
		g_pfn_CBPW_SendWeaponAnim[i] = OrpheuGetFunctionFromClass(g_rgszWeaponEntity[i], "SendWeaponAnim", "CBasePlayerWeapon");
		OrpheuRegisterHook(g_pfn_CBPW_SendWeaponAnim[i], "OrpheuF_SendWeaponAnim");
	}
	
	for (new i = 0; i < sizeof g_rgszAmmoNameByIndex; i++)
	{
		if (!g_rgszAmmoNameByIndex[i][0])
			continue;
		
		formatex(szCvarName, charsmax(szCvarName), "ammo_%s_max", g_rgszAmmoNameByIndex[i]);
		cvar_ammomax[i] = register_cvar(szCvarName, "0");
		
		formatex(szCvarName, charsmax(szCvarName), "ammo_%s_perbox", g_rgszAmmoNameByIndex[i]);
		cvar_ammoperbox[i] = register_cvar(szCvarName, "0");
		
		if (i < sizeof g_rgszAmmoEntityNameByIndex)
			RegisterHam(Ham_Touch, g_rgszAmmoEntityNameByIndex[i], "HAM_Ammo_Touch");
	}
	
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1);
	RegisterHam(Ham_TraceAttack, "player", "HAM_TraceAttack");
	RegisterHam(Ham_GiveAmmo, "player", "HAM_GiveAmmo");
	
	register_forward(FM_TraceLine, "fw_TraceLine");
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_ClientCommand, "fw_ClientCommand");
	register_forward(FM_ClientCommand, "fw_ClientCommand_Post", 1);
	
	register_message(get_user_msgid("WeaponList"), "Message_WeaponList");
	
	// shotgun support.
	RegisterHam(Ham_Weapon_Reload, g_rgszWeaponEntity[CSW_M3], "HamF_Shotgun_Weapon_Reload");
	RegisterHam(Ham_Item_PostFrame, g_rgszWeaponEntity[CSW_M3], "HamF_Shotgun_Item_PostFrame");
	RegisterHam(Ham_Weapon_WeaponIdle, g_rgszWeaponEntity[CSW_M3], "HamF_Shotgun_WeaponIdle");
	RegisterHam(Ham_Item_Holster, g_rgszWeaponEntity[CSW_M3], "HamF_Shotgun_Holster_Post", 1);
	
	RegisterHam(Ham_Weapon_Reload, g_rgszWeaponEntity[CSW_XM1014], "HamF_Shotgun_Weapon_Reload");
	RegisterHam(Ham_Item_PostFrame, g_rgszWeaponEntity[CSW_XM1014], "HamF_Shotgun_Item_PostFrame");
	RegisterHam(Ham_Weapon_WeaponIdle, g_rgszWeaponEntity[CSW_XM1014], "HamF_Shotgun_WeaponIdle");
	RegisterHam(Ham_Item_Holster, g_rgszWeaponEntity[CSW_XM1014], "HamF_Shotgun_Holster_Post", 1);
	
	set_pcvar_float(cvar_reload[CSW_M3], 0.4412);	// inserting animation length.
	cvar_start_reload[CSW_M3]	= register_cvar("weap_m3_start_reload_time",	"0.5");
	cvar_after_reload[CSW_M3]	= register_cvar("weap_m3_after_reload_time",	"‭0.8421");
	cvar_chamberadd[CSW_M3]		= register_cvar("weap_m3_chamber_add_cycle",	"0.1846");
	
	set_pcvar_float(cvar_reload[CSW_XM1014], 0.4);	// inserting animation length.
	cvar_start_reload[CSW_XM1014]	= register_cvar("weap_xm1014_start_reload_time",	"0.7");
	cvar_after_reload[CSW_XM1014]	= register_cvar("weap_xm1014_after_reload_time",	"‭0.4333");
	cvar_chamberadd[CSW_XM1014]		= register_cvar("weap_xm1014_chamber_add_cycle",	"0.2");
}

public fw_UpdateClientData_Post(iPlayer, iSendWeapon, hCD)	// credits to Nagist(a.k.a. Martin)
{
	if (get_cd(hCD, CD_DeadFlag) != DEAD_NO)
		return;
	
	static iEntity;
	iEntity = get_pdata_cbase(iPlayer, m_pActiveItem);
	if (pev_valid(iEntity) == 2 && !IsWeaponFromOriginalCS(iEntity))
		return;
	
	new Float:flAccuracy = get_pcvar_float(cvar_accuracy[iId]);
	if (flAccuracy != 1.0 && flAccuracy > 0.0)
		set_cd(hCD, CD_iUser3, 0);
	
	//if ( (iId == CSW_XM1014 && get_pcvar_num(cvar_clip[CSW_XM1014]) > 0)
	//	|| (iId == CSW_M3 && get_pcvar_num(cvar_clip[CSW_M3]) > 0) )
	set_cd(hCD, CD_ID, 0);	// remove the entire client weapon predict system.
}

public HamF_WeaponSpawn_Post(iEntity)
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return;
	
	new iClip = get_pcvar_num(cvar_clip[get_pdata_int(iEntity, m_iId, 4)])
	if (!iClip)
		return;
	
	set_pdata_int(iEntity, m_iClip, iClip, 4);
}

public HAM_Ammo_Touch(iEntity, pPlayer)
{
	if (!is_user_alive(pPlayer))
		return HAM_IGNORED;
	
	g_bPickingAmmo[pPlayer] = true;
	return HAM_IGNORED;
}

public HamF_Item_AddToPlayer_Post(iEntity, pPlayer)
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return;
	
	new iId = get_pdata_int(iEntity, m_iId, 4);
	new iMaxAmmo = get_pcvar_num(cvar_ammomax[get_pdata_int(iEntity, m_iPrimaryAmmoType, 4)]);
	
	if (iMaxAmmo <= 0 || iMaxAmmo > 254)
		return;
	
	UTIL_MsgWeaponList(pPlayer, iId, g_rgszWeaponEntity[iId], iMaxAmmo);
}

public HamF_CS_Item_GetMaxSpeed(iEntity)	// credits to No_Name
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return HAM_IGNORED;
	
	new iId = get_pdata_int(iEntity, m_iId, 4);
	new pPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	new Float:fSpeed = get_pcvar_float(get_pdata_int(pPlayer, m_iFOV, 5) >= 90 ? cvar_walkspeed[iId] : cvar_zoomingwalkspeed[iId]);
	
	if (fSpeed <= 0.0)
		return HAM_IGNORED;
	
	SetHamReturnFloat(fSpeed);
	return HAM_OVERRIDE;
}

public HamF_Item_Deploy_Post(iEntity)
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return;
	
	new iId = get_pdata_int(iEntity, m_iId, 4);
	if (get_pcvar_float(cvar_deploy[iId]) <= 0.0)
		return;
	
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	set_pdata_float(id, m_flNextAttack, get_pcvar_float(cvar_deploy[iId]));
}

public HamF_Weapon_PrimaryAttack(iEntity)
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return;
	
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);

	g_rgbShooting[id] = true;
	g_rgiIdActiveWeapon[id] = get_pdata_int(iEntity, m_iId, 4);
}

public fw_TraceLine(Float:vecStart[3], Float:vecEnd[3], iConditions, id, iTrace)	// credits to Nagist(a.k.a. Martin)
{
	if (!is_user_connected(id))
		return FMRES_IGNORED;

	if (!g_rgbShooting[id])
		return FMRES_IGNORED;

	new Float:flAccuracy = get_pcvar_float(cvar_accuracy[g_rgiIdActiveWeapon[id]]);
	if (flAccuracy < 0.0 || flAccuracy == 1.0)
		return FMRES_IGNORED;
	
	new Float:vecTemp[3], Float:vecDir[3];
	xs_vec_sub(vecEnd, vecStart, vecDir);

	vecDir[0] /= 8192.0;
	vecDir[1] /= 8192.0;
	vecDir[2] /= 8192.0;

	global_get(glb_v_forward, vecTemp);
	xs_vec_sub(vecDir, vecTemp, vecDir);
	xs_vec_mul_scalar(vecDir, flAccuracy, vecDir);
	xs_vec_add(vecDir, vecTemp, vecDir);
	xs_vec_mul_scalar(vecDir, 8192.0, vecDir);
	xs_vec_add(vecDir, vecStart, vecEnd);
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, iConditions, id, iTrace);
	
	return FMRES_SUPERCEDE;
}

public fw_PlaybackEvent(iFlags, id, iEvent, Float:fDelay, Float:vecOrigin[3], Float:vecAngle[3], Float:flParam1, Float:flParam2, iParam1, iParam2, bParam1, bParam2)	// credits to Nagist(a.k.a. Martin)
{
	if (!g_rgbShooting[id])
		return FMRES_IGNORED;

	new Float:flAccuracy = get_pcvar_float(cvar_accuracy[g_rgiIdActiveWeapon[id]]);
	
	engfunc(EngFunc_PlaybackEvent, FEV_GLOBAL, id, iEvent, fDelay, vecOrigin, vecAngle, flParam1 * flAccuracy, flParam2 * flAccuracy, iParam1, iParam2, bParam1, bParam2);
	
	return FMRES_SUPERCEDE;
}

public HamF_Weapon_PrimaryAttack_Post(iEntity)
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return;
	
	new iId = get_pdata_int(iEntity, m_iId, 4), id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	new Float:flInterval = get_pcvar_float(cvar_rate[iId]);
	if (flInterval > 0.0)
	{
		if (flInterval > 10.0)	// consider this is a RPM value.
			flInterval = 60.0 / get_pcvar_float(cvar_rate[iId]);
		
		set_pdata_float(iEntity, m_flNextPrimaryAttack, flInterval, 4);
	}
	
	if (get_pcvar_float(cvar_recoil[iId]) >= 0.0)
	{
		new Float:vecPunchAngle[3];
		pev(id, pev_punchangle, vecPunchAngle);
		xs_vec_mul_scalar(vecPunchAngle, get_pcvar_float(cvar_recoil[iId]), vecPunchAngle);
		set_pev(id, pev_punchangle, vecPunchAngle);
	}
	
	g_rgbShooting[id] = false;
}

public HamF_Weapon_Reload(iEntity)
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return;

	new iId = get_pdata_int(iEntity, m_iId, 4);
	new iClip = get_pcvar_num(cvar_clip[iId]);
	
	if (iClip <= 0)
		return;

	if (get_pdata_int(iEntity, m_iClip, 4) == g_rgiDefaultMaxClip[iId])
	{
		set_pdata_int(iEntity, m_iClip, 0, 4);
		g_rgbReloadBugTrigger[get_pdata_cbase(iEntity, m_pPlayer, 4)] = true;
	}
}

public HamF_Weapon_Reload_Post(iEntity)
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return;
	
	new iId = get_pdata_int(iEntity, m_iId, 4);
	new Float:fValue = get_pcvar_float(cvar_reload[iId]);
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	if (fValue > 0.0 && get_pdata_int(iEntity, m_fInReload, 4))
	{
		set_pdata_float(id, m_flNextAttack, fValue, 5);
		set_pdata_float(iEntity, m_flTimeWeaponIdle, fValue + 0.5, 4);
	}
	
	if (g_rgbReloadBugTrigger[id])
	{
		g_rgbReloadBugTrigger[id] = false;
		set_pdata_int(iEntity, m_iClip, g_rgiDefaultMaxClip[iId], 4);
	}
}

public HamF_Item_PostFrame(iEntity)	// credits to ConnorMcLeod
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return;
	
	static iId ; iId = get_pdata_int(iEntity, m_iId, 4);
	static iMaxClip ; iMaxClip = get_pcvar_num(cvar_clip[iId]);
	if (!iMaxClip)
		return;
	
	static fInReload ; fInReload = get_pdata_int(iEntity, m_fInReload, 4);
	static id ; id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	static Float:flNextAttack ; flNextAttack = get_pdata_float(id, m_flNextAttack);
	
	static iAmmoType ; iAmmoType = m_rgAmmo[get_pdata_int(iEntity, m_iPrimaryAmmoType, 4)];
	static iBpAmmo ; iBpAmmo = get_pdata_int(id, iAmmoType);
	static iClip ; iClip = get_pdata_int(iEntity, m_iClip, 4);
	
	if ( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(iMaxClip - iClip, iBpAmmo);
		set_pdata_int(iEntity, m_iClip, iClip + j, 4);
		set_pdata_int(id, iAmmoType, iBpAmmo-j, 5);
		
		set_pdata_int(iEntity, m_fInReload, 0, 4);
		fInReload = 0;
	}
	
	static iButton ; iButton = pev(id, pev_button);
	if ( (iButton & IN_ATTACK2 && get_pdata_float(iEntity, m_flNextSecondaryAttack, 4) <= 0.0)
	||	(iButton & IN_ATTACK && get_pdata_float(iEntity, m_flNextPrimaryAttack, 4) <= 0.0) )
	{
		return;
	}
	
	if ( iButton & IN_RELOAD && !fInReload && iClip >= iMaxClip )
	{
		set_pev(id, pev_button, iButton & ~IN_RELOAD);
		
		if ((iId == CSW_M4A1 || iId == CSW_USP) && !get_pdata_int(iEntity, m_iWeaponState, 4))
		{
			native_playanim(id, iId == CSW_USP ? 8 : 7);
			return;
		}
		
		native_playanim(id, 0);
	}
}

public HamF_Item_PrimaryAmmoIndex_Post(iEntity)
{
	if (!g_bFabricateBPAmmoData)	// this function will be called in ItemPostFrame() after you shoot your last bullet.
		return;
	
	if (!IsWeaponFromOriginalCS(iEntity))
		return;
	
	/**
	There are two scenarios.
	A. You wish the new maxium is larger than original maxium.
	B. You wish the new maxium is smaller than originall maxium.
	The two handles are different.
	**/
	
	new iId = 0;
	GetOrigHamReturnInteger(iId);	// DEBUG: why can't I use GetHamReturnInteger() here?!
	
	if (iId <= 0)
		return;
	
	new pPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	if (!is_user_alive(pPlayer))	// this function will be called in another place, i.e. CWeaponBox is created when player gets killed.
		return;
	
	new iCurAmmo = get_pdata_int(pPlayer, m_rgAmmo[iId]);
	new iMaxAmmo = get_pcvar_num(cvar_ammomax[iId]);
	
	if (iMaxAmmo <= 0 || iMaxAmmo > 254)	// skip the invalid settings.
		return;
	
	if (iMaxAmmo <= iCurAmmo)
	{
		// Handling situation B.
		if (iMaxAmmo <= g_rgszAmmoDefaultMaxByIndex[iId])
		{
			g_bAmmoBufferFix[iId] = true;	// handled at fw_ClientCommand_Post()
			g_iAmmoBuffer[iId] = iCurAmmo;
			set_pdata_int(pPlayer, m_rgAmmo[iId], g_rgszAmmoDefaultMaxByIndex[iId]);
		}
		
		return;
	}
	
	// Handling situation A.
	g_bAmmoBufferFix[iId] = true;	// handled at HAM_GiveAmmo()
	g_iAmmoBuffer[iId] = iCurAmmo;
	set_pdata_int(pPlayer, m_rgAmmo[iId], 0);
}

//public HamF_Weapon_SendWeaponAnim(iEntity, iAnim, bSkipLocal, iBody)	// bugged until AMXMODX 1.9.0
public OrpheuF_SendWeaponAnim(iEntity, iAnim, bSkipLocal)
{
	if (!IsWeaponFromOriginalCS(iEntity)/* || !( (1<<get_pdata_int(iEntity, m_iId, 4)) & ((1<<CSW_M3)|(1<<CSW_XM1014)) ) */)
		return _:OrpheuIgnored;
	
	OrpheuSetParam(3, 0);	// 0 == FALSE;
	return _:OrpheuIgnored;
}

#define m_flNextInsertAnim	m_flStartThrow
#define m_flNextAddAmmo		m_flReleaseThrow

#define SHOTGUN_INSERT		3
#define SHOTGUN_AFTERRELOAD	4
#define	SHOTGUN_STARTRELOAD	5
#define SHOTGUN_INSERT_DUR		get_pcvar_float(cvar_reload[iId])
#define SHOTGUN_AFTERRELOAD_DUR	get_pcvar_float(cvar_after_reload[iId])
#define	SHOTGUN_STARTRELOAD_DUR	get_pcvar_float(cvar_start_reload[iId])
#define	SHOTGUN_CHAMBERADD_TIME get_pcvar_float(cvar_chamberadd[iId])
#define AMMOTYPE_BUCKSHOT	5
#define AMMO_BUCKSHOT		get_pdata_int(pPlayer, m_rgAmmo[AMMOTYPE_BUCKSHOT])
#define ICLIP				get_pdata_int(iEntity, m_iClip, 4)

public HamF_Shotgun_Item_PostFrame(iEntity)
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return HAM_IGNORED;
	
	static iId ; iId = get_pdata_int(iEntity, m_iId, 4);
	static iMaxClip ; iMaxClip = get_pcvar_num(cvar_clip[iId]);
	
	if (iMaxClip <= 0)
		return HAM_IGNORED;
	
	new Float:fCurTime;
	global_get(glb_time, fCurTime);
	
	new pPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	if (get_pdata_int(iEntity, m_fInSpecialReload, 4))
	{
		if (get_pdata_float(iEntity, m_flNextInsertAnim, 4) <= fCurTime && ICLIP < iMaxClip && AMMO_BUCKSHOT > 0)
		{
			native_playanim(pPlayer, SHOTGUN_INSERT);
			SetAnimation(pPlayer, PLAYER_RELOAD);
			ReloadSound(iEntity);

			set_pdata_float(iEntity, m_flNextInsertAnim, fCurTime + SHOTGUN_INSERT_DUR, 4);
			
			set_pdata_float(iEntity, m_flNextPrimaryAttack, SHOTGUN_INSERT_DUR, 4);
			set_pdata_float(iEntity, m_flNextSecondaryAttack, SHOTGUN_INSERT_DUR, 4);
			set_pdata_float(iEntity, m_flTimeWeaponIdle, SHOTGUN_INSERT_DUR, 4);
		}

		if (AMMO_BUCKSHOT > 0 && get_pdata_float(iEntity, m_flNextAddAmmo, 4) <= fCurTime && ICLIP < iMaxClip)
		{
			set_pdata_int(iEntity, m_iClip, ICLIP + 1, 4);
			set_pdata_int(pPlayer, m_rgAmmo[AMMOTYPE_BUCKSHOT], AMMO_BUCKSHOT - 1);

			set_pdata_float(iEntity, m_flNextAddAmmo, fCurTime + SHOTGUN_INSERT_DUR, 4);
		}

		if ( ( (ICLIP >= iMaxClip || AMMO_BUCKSHOT <= 0) && get_pdata_float(iEntity, m_flNextInsertAnim, 4) <= fCurTime)
			|| pev(pPlayer, pev_button) & (IN_ATTACK|IN_ATTACK2) )
		{
			native_playanim(pPlayer, SHOTGUN_AFTERRELOAD);

			set_pdata_int(iEntity, m_fInSpecialReload, 0, 4);
			
			set_pdata_float(iEntity, m_flNextPrimaryAttack, SHOTGUN_AFTERRELOAD_DUR, 4);
			set_pdata_float(iEntity, m_flNextSecondaryAttack, SHOTGUN_AFTERRELOAD_DUR, 4);
			set_pdata_float(iEntity, m_flTimeWeaponIdle, SHOTGUN_AFTERRELOAD_DUR, 4);
		}
	}
	else
		return HAM_IGNORED;
	
	return HAM_SUPERCEDE;
}

public HamF_Shotgun_Weapon_Reload(iEntity)
{
	if (!IsWeaponFromOriginalCS(iEntity))
		return HAM_IGNORED;
	
	static iId ; iId = get_pdata_int(iEntity, m_iId, 4);
	static iMaxClip ; iMaxClip = get_pcvar_num(cvar_clip[iId]);
	
	if (iMaxClip <= 0)
		return HAM_IGNORED;
	
	new Float:fCurTime;
	global_get(glb_time, fCurTime);
	
	new pPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	if (get_pdata_int(iEntity, m_iClip, 4) >= iMaxClip ||  AMMO_BUCKSHOT <= 0)
		return HAM_SUPERCEDE;

	set_pdata_int(iEntity, m_iShotsFired, 0, 4);
	set_pdata_int(iEntity, m_fInSpecialReload, 1, 4);
	set_pdata_float(pPlayer, m_flNextAttack, SHOTGUN_STARTRELOAD_DUR);
	set_pdata_float(iEntity, m_flNextInsertAnim, fCurTime + SHOTGUN_STARTRELOAD_DUR, 4);
	set_pdata_float(iEntity, m_flNextAddAmmo, fCurTime + SHOTGUN_STARTRELOAD_DUR + SHOTGUN_CHAMBERADD_TIME, 4);

	native_playanim(pPlayer, SHOTGUN_STARTRELOAD);
	return HAM_SUPERCEDE;
}

public HamF_Shotgun_WeaponIdle(iEntity)
{
	return HAM_SUPERCEDE;
}

public HamF_Shotgun_Holster_Post(iEntity)
{
	set_pdata_int(iEntity, m_fInSpecialReload, 0, 4);
}

public HAM_TraceAttack(iVictim, id, Float:fDamage, Float:fDirection[3], tr, iDamageTypes)
{
	if (!is_user_alive(id) || pev_valid(iVictim) != 2)
		return HAM_IGNORED;
	
	if (!g_rgbShooting[id])
		return HAM_IGNORED;
	
	new Float:fKnockMul = get_pcvar_float(cvar_knock[g_rgiIdActiveWeapon[id]]);
	new Float:fDamageMul = get_pcvar_float(cvar_damageMul[g_rgiIdActiveWeapon[id]]);
	new Float:flDamageAdd = get_pcvar_float(cvar_damageAdd[g_rgiIdActiveWeapon[id]]);
	new Float:fMaxShootDist = get_pcvar_float(cvar_maxdist[g_rgiIdActiveWeapon[id]]);
	
	if (fMaxShootDist > 0.0)
	{
		new Float:vecOrigin[3], Float:vecOrigin2[3];
		pev(id, pev_origin, vecOrigin);
		pev(id, pev_view_ofs, vecOrigin2);
		xs_vec_add(vecOrigin, vecOrigin2, vecOrigin);
		get_tr2(tr, TR_vecEndPos, vecOrigin2);
		
		if (get_distance_f(vecOrigin, vecOrigin2) > fMaxShootDist)
		{
			fDamageMul = 0.0;
			flDamageAdd = 0.0;
		}
	}
	
	SetHamParamFloat(3, fDamage * fDamageMul + flDamageAdd);
	
	if (fKnockMul >= 0.0)
	{
		new Float:fVelocity[3];
		pev(iVictim, pev_velocity, fVelocity);
		xs_vec_mul_scalar(fVelocity, fKnockMul, fVelocity);
		set_pev(iVictim, pev_velocity, fVelocity);
	}
	
	return HAM_IGNORED;
}

public HAM_GiveAmmo(pPlayer, iAmount, const szName[], iMax)
{
	new iId = -1;
	for (new i = 0; i < sizeof g_rgszAmmoNameByIndex; i++)
	{
		if (!strcmp(szName, g_rgszAmmoNameByIndex[i]))
		{
			iId = i;
			break;
		}
	}
	
	if (iId <= 0 || get_pcvar_num(cvar_ammomax[iId]) <= 0)
		return HAM_IGNORED;
	
	if (g_bAmmoBufferFix[iId])
	{
		set_pdata_int(pPlayer, m_rgAmmo[iId], g_iAmmoBuffer[iId]);
		g_bAmmoBufferFix[iId] = false;
	}
	
	if (g_bPickingAmmo[pPlayer] && get_pcvar_num(cvar_ammoperbox[iId]) > 0)
	{
		SetHamParamInteger(2, get_pcvar_num(cvar_ammoperbox[iId]));
		g_bPickingAmmo[pPlayer] = false;
	}
	
	SetHamParamInteger(4, get_pcvar_num(cvar_ammomax[iId]));
	return HAM_IGNORED;
}

public Message_WeaponList(msg_id, msg_dest, msg_entity)
{
	/**
	Name:	WeaponList
	Structure:
		string	WeaponName
		byte	PrimaryAmmoID
		byte	PrimaryAmmoMaxAmount
		byte	SecondaryAmmoID
		byte	SecondaryAmmoMaxAmount
		byte	SlotID
		byte	NumberInSlot
		byte	WeaponID
		byte	Flags
	**/
	
	// However, accroading to my research, this message is actually never called after server starts.
	// @client.cpp::ServerActivate() -> WriteSigonMessages();
	// We have to send another message scripted in HamF_Item_AddToPlayer_Post()
	
	new iMaxAmmo = get_pcvar_num(cvar_ammomax[get_msg_arg_int(2)]);
	if (iMaxAmmo <= 0)
		return PLUGIN_CONTINUE;
	
	set_msg_arg_int(3, ARG_BYTE, iMaxAmmo);
	return PLUGIN_CONTINUE;
}

public fw_ClientCommand(pPlayer)
{
	static szCommand[24];
	read_argv(0, szCommand, charsmax(szCommand));
	
	if (!strcmp(szCommand, "primammo") || !strcmp(szCommand, "secammo")
		|| !strcmp(szCommand, "buyammo1") || !strcmp(szCommand, "buyammo2"))	// after the series events of BuyGunAmmo(), I have to make sure that the fake number from situation B handing is cut loose.
	{
		g_bFabricateBPAmmoData = true;	// only allow when you art attempting to buy ammunition.
		// we don't need to consider picking up weapons, as it can be fully handled by HAM_GiveAmmo().
	}
	
	/*if (!strcmp(szCommand, "ammocheck"))
	{
		for (new i = 1; i < sizeof g_rgszAmmoEntityNameByIndex; i++)
			client_print(pPlayer, print_console, "%s: %d", g_rgszAmmoNameByIndex[i], get_pdata_int(pPlayer, m_rgAmmo[i]));
		
		return FMRES_SUPERCEDE;
	}*/
	
	return FMRES_IGNORED;
}

public fw_ClientCommand_Post(pPlayer)
{
	static szCommand[24];
	read_argv(0, szCommand, charsmax(szCommand));
	
	if (!strcmp(szCommand, "primammo") || !strcmp(szCommand, "secammo")
		|| !strcmp(szCommand, "buyammo1") || !strcmp(szCommand, "buyammo2"))	// after the series events of BuyGunAmmo(), I have to make sure that the fake number from situation B handing is cut loose.
	{
		for (new i = 1; i < sizeof g_rgszAmmoNameByIndex; i++)
		{
			if (g_bAmmoBufferFix[i])
			{
				g_bAmmoBufferFix[i] = false;
				set_pdata_int(pPlayer, m_rgAmmo[i], g_iAmmoBuffer[i]);
			}
		}
		
		g_bFabricateBPAmmoData = false;
	}
}

stock native_playanim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id);
	write_byte(iAnim);
	write_byte(pev(id,pev_body));
	message_end();
}

stock native_GiveNamedItem(pPlayer, const pszName[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, pszName));

	if (pev_valid(iEntity))
		return 0;

	new Float:vecOrigin[3];
	pev(pPlayer, pev_origin, vecOrigin);
	set_pev(iEntity, pev_origin, vecOrigin);

	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags)|SF_NORESPAWN);

	dllfunc(DLLFunc_Spawn, iEntity);
	dllfunc(DLLFunc_Touch, iEntity, pPlayer);

	return iEntity;
}

stock UTIL_MsgWeaponList(iPlayer, iId, const szHud[], iMaxAmmo = -1, iSlot = -1, iList = -1)
{
	new const rgGameWeaponAmmoId[CSW_P90 + 1] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }
	new const rgGameWeaponInSlot[CSW_P90 + 1] = { -1, 3, -1, 9, 1, 12, 3, 13, 14, 3, 5, 6, 15, 16, 17, 18, 4, 2, 2, 7, 4, 5, 6, 11, 3, 2, 1, 10, 1, 1, 8 }
	new const rgGameWeaponWhichSlot[CSW_P90 + 1] = { -1, 1, -1, 0, 3, 0, 4, 0, 0, 3, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 3, 1, 0, 0, 2, 0 }
	new const rgGameWeaponAmmoMaxAmount[CSW_P90 + 1] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }
	
	emessage_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), {0,0,0}, iPlayer)
	ewrite_string(szHud)
	ewrite_byte(rgGameWeaponAmmoId[iId])
	ewrite_byte(iMaxAmmo == -1 ? rgGameWeaponAmmoMaxAmount[iId] : iMaxAmmo)
	ewrite_byte(-1)
	ewrite_byte(-1)
	ewrite_byte(iSlot == -1 ? rgGameWeaponWhichSlot[iId] : iSlot-1)
	ewrite_byte(iList == -1 ? rgGameWeaponInSlot[iId] : iList)
	ewrite_byte(iId)
	
	if (iId == CSW_C4 || iId == CSW_HEGRENADE || iId == CSW_FLASHBANG || iId == CSW_SMOKEGRENADE)
		ewrite_byte(ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE)
	else
		ewrite_byte(0)
	
	emessage_end()
}

public fw_BotForwardRegister_Post(iPlayer)
{
	if (!is_user_bot(iPlayer))
		return;

	unregister_forward(FM_PlayerPostThink, g_fwBotForwardRegister, 1);
	
	RegisterHamFromEntity(Ham_TraceAttack, iPlayer, "HAM_TraceAttack");
	RegisterHamFromEntity(Ham_GiveAmmo, iPlayer, "HAM_GiveAmmo");
}

SetAnimation(pPlayer, PLAYER_ANIM:iAnim)
{
	if (is_user_connected(pPlayer))
		OrpheuCallSuper(g_pfn_CBP_SetAnimation, pPlayer, iAnim);
}

ReloadSound(iWeapon)
{
	OrpheuCallSuper(g_pfn_CBPW_ReloadSound, iWeapon);
}

bool:IsWeaponFromOriginalCS(iEntity)
{
	// pev_weapons - DSHGFHDS usually doing this.
	// ammo_buckshot (OFS 11) - Fly's weapon template plugin.
	
	// Notify me if there're others.
	
	return !!(pev(iEntity, pev_weapons) == 0 && get_pdata_int(iEntity, 11, 4) == 0);
}



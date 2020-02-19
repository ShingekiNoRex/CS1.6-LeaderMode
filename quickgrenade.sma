/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <offset>

#define PLUGIN		"Grenade Quick Throw"
#define VERSION		"1.0.1"
#define AUTHOR		"Luna the Reborn"

#define CLASSNAME_GRENADE	"weapon_hegrenade"
#define QTG_VMDL	"models/v_CODhegrenade.mdl"

#define QUICKTHROW_KEY	541368

#define ANIM_PULLPIN	1
#define ANIM_THROW		2
#define TIME_PULLPIN	0.825
#define TIME_THROW		0.467

#define HEG_AMMOTYPE	m_rgAmmo[12]

new g_strQuickHEVMDL;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	
	register_clcmd("+qtg",	"Command_QTGStart");
	register_clcmd("-qtg",	"Command_QTGRelease");
	
	RegisterHam(Ham_Item_Deploy, CLASSNAME_GRENADE, "HamF_Item_Deploy_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, CLASSNAME_GRENADE, "HamF_Weapon_PrimaryAttack");
	RegisterHam(Ham_Weapon_WeaponIdle, CLASSNAME_GRENADE, "HamF_Weapon_WeaponIdle");
	RegisterHam(Ham_Item_Holster, CLASSNAME_GRENADE, "HamF_Item_Holster_Post", 1);
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, QTG_VMDL);
	
	g_strQuickHEVMDL = engfunc(EngFunc_AllocString, QTG_VMDL);
}

public fw_UpdateClientData_Post(pPlayer, iSendWeapon, hCD)
{
	if (get_cd(hCD, CD_DeadFlag) != DEAD_NO)
		return;
	
	if (get_cd(hCD, CD_ID) != CSW_HEGRENADE)
		return;
	
	new iEntity = get_pdata_cbase(pPlayer, m_pActiveItem);
	if (pev(iEntity, pev_iuser4) != QUICKTHROW_KEY && pev(iEntity, pev_iuser3) != QUICKTHROW_KEY)	// don't block normal grenades.
		return;
	
	// reference: client.cpp::void (*UpdateClientData)(const struct edict_s *ent, int sendweapons, struct clientdata_s *cd)
	
	set_cd(hCD, CD_iUser3, 0);	// prevents IUSER3_CANSHOOT
	set_cd(hCD, CD_ID, 0);		// prevents client weapon predicts.
}

public Command_QTGStart(pPlayer)
{
	if (get_pdata_int(pPlayer, HEG_AMMOTYPE) <= 0)
		return PLUGIN_HANDLED;
	
	new iEntity = -1;
	while ((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", CLASSNAME_GRENADE)))
	{
		if (pev_valid(iEntity) != 2)
			continue;
		
		if (get_pdata_cbase(iEntity, m_pPlayer, 4) != pPlayer)
			continue;
		
		// FOUND!
		break;
	}
	
	if (get_pdata_cbase(pPlayer, m_pActiveItem) == iEntity)	// never QGT when player had already take it out.
		return PLUGIN_HANDLED;
	
	set_pev(iEntity, pev_iuser4, QUICKTHROW_KEY);
	engclient_cmd(pPlayer, CLASSNAME_GRENADE);
	return PLUGIN_HANDLED;
}

public Command_QTGRelease(pPlayer)
{
	new iEntity = get_pdata_cbase(pPlayer, m_pActiveItem);
	if (pev_valid(iEntity) != 2)
		return PLUGIN_HANDLED;
	
	if (get_pdata_int(iEntity, m_iId, 4) != CSW_HEGRENADE)
		return PLUGIN_HANDLED;
	
	set_pev(iEntity, pev_iuser3, 0);	// unlock CHEGrenade::WeaponIdle(void)
	return PLUGIN_HANDLED;
}

public HamF_Item_Deploy_Post(iEntity)
{
	if (pev(iEntity, pev_iuser4) != QUICKTHROW_KEY)
		return;
	
	new pPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	set_pev(pPlayer, pev_viewmodel, g_strQuickHEVMDL);
	
	UTIL_ForceWeaponAnim(pPlayer, iEntity, TIME_PULLPIN);
	UTIL_WeaponAnim(pPlayer, ANIM_PULLPIN);
	
	set_pev(iEntity, pev_iuser4, 0);
	set_pev(iEntity, pev_iuser3, QUICKTHROW_KEY);	// lock CHEGrenade::WeaponIdle(void)
	
	// reference: CHEGrenade::PrimaryAttack(void)
	
	set_pdata_float(iEntity, m_flStartThrow, get_gametime(), 4);
	set_pdata_float(iEntity, m_flReleaseThrow, 0.0, 4);
	set_pdata_float(iEntity, m_flTimeWeaponIdle, TIME_PULLPIN, 4);
}

public HamF_Weapon_PrimaryAttack(iEntity)
{
	if (pev(iEntity, pev_iuser4) != QUICKTHROW_KEY)
		return HAM_IGNORED;
	
	return HAM_SUPERCEDE;
}

public HamF_Weapon_WeaponIdle(iEntity)
{
	if (pev(iEntity, pev_iuser3) == QUICKTHROW_KEY)
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public HamF_Item_Holster_Post(iEntity)
{
	set_pev(iEntity, pev_iuser3, 0);
	set_pev(iEntity, pev_iuser4, 0);
}

stock UTIL_WeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, id);
	write_byte(iAnim);
	write_byte(pev(id, pev_body));
	message_end();
}

stock UTIL_ForceWeaponAnim(pPlayer, iEntity, Float:flTime = 0.0)
{
	set_pdata_float(pPlayer, m_flNextAttack,			flTime);
	set_pdata_float(iEntity, m_flNextPrimaryAttack,		flTime, 4);
	set_pdata_float(iEntity, m_flNextSecondaryAttack,	flTime, 4);
	set_pdata_float(iEntity, m_flTimeWeaponIdle,		flTime, 4);
}














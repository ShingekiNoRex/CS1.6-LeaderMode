/* ammx编写头版 by moddev*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Glock18 Attack2"
#define VERSION "1.0"
#define AUTHOR "DSHGFHDS"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_glock18", "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_glock18", "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_glock18", "fw_Weapon_SecondaryAttack")
}

public fw_Weapon_SecondaryAttack(iEntity) return FMRES_SUPERCEDE

public fw_PrimaryAttack(iEntity) set_pdata_int(iEntity, 64, -1, 4)

public fw_PrimaryAttack_Post(iEntity) set_pdata_float(iEntity, 46, 0.1, 4)
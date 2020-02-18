/**

**/

#define SHARPSHOOTER_TEXT	g_rgszRoleNames[Role_Sharpshooter]
#define SHARPSHOOTER_TASK	2643819	// just some random number.

#define SHARPSHOOTER_GRAND_SFX		"leadermode/agent_recruited.wav"
#define SHARPSHOOTER_REVOKE_SFX		"leadermode/attack_out_of_range_01.wav"

new cvar_sharpshooterDeathMarkDur, cvar_sharpshooterCooldown;

public Sharpshooter_Initialize()
{
	cvar_sharpshooterDeathMarkDur	= register_cvar("lm_sharpshooter_deathmark_duration",	"5.0");
	cvar_sharpshooterCooldown		= register_cvar("lm_sharpshooter_cooldown",				"30.0");
	
	g_rgSkillDuration[Role_Sharpshooter] = cvar_sharpshooterDeathMarkDur;
	g_rgSkillCooldown[Role_Sharpshooter] = cvar_sharpshooterCooldown;
}

public Sharpshooter_ExecuteSkill(pPlayer)
{
	set_task(get_pcvar_float(cvar_sharpshooterDeathMarkDur), "Sharpshooter_RevokeSkill", SHARPSHOOTER_TASK + pPlayer);
	
	client_cmd(pPlayer, "spk %s", SHARPSHOOTER_GRAND_SFX);
}

public Sharpshooter_RevokeSkill(iTaskId)
{
	new pPlayer = iTaskId - SHARPSHOOTER_TASK;
	
	if (!is_user_alive(pPlayer))
		return;
	
	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = get_gametime() + get_pcvar_float(cvar_sharpshooterCooldown);
	print_chat_color(pPlayer, BLUECHAT, "技能已结束！");
	client_cmd(pPlayer, "spk %s", SHARPSHOOTER_REVOKE_SFX);
}

public Sharpshooter_TerminateSkill(pPlayer)
{
	remove_task(SHARPSHOOTER_TASK + pPlayer);
	Sharpshooter_RevokeSkill(SHARPSHOOTER_TASK + pPlayer);
}
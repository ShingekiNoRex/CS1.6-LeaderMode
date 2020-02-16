/**

 - 金錢有限，以傷害為準	✔ (LUNA)
 - 死亡總次數有限，復活時間 = 隊長HP / 100 ✔ (LUNA)


策略：全體隊員投票決定隊伍策略。每次有且僅有一項策略生效。策略每20秒得以更換。 ✔ (LUNA)
火力優勢學說：	✔
	彈匣內每秒填充4%的彈藥。
數量優勢學說：	✔
	復活速度固定為1秒。
	兵源消耗減半。
質量優勢學說：	✔
	每5秒獲得50金錢。
	造成傷害及擊殺賞金翻倍。
機動作戰學說：	✔
	增援會部署於指揮官附近。
	可以於任意地點購買裝備。

CT:
指挥官	(1)
(標記黑手位置，自身射速加倍&受傷減半)	✔ (LUNA) (預訂)
(被動：HP 1000，可以发动空袭) ✔ (REX)
S.W.A.T.
(立即填充所有手榴彈，10秒内轉移90%傷害至護甲)
(被動：AP 200)
爆破手
(10秒内无限高爆手雷，爆炸伤害+50%)
(被動：死后爆炸)
神射手
(10秒内强制爆头，命中的目標致盲3秒)
(被動：枪械散射和後座力減半)
医疗兵
(犧牲50%HP將周圍非隊長角色的HP恢復最大值的一半，10秒内手榴彈及煙霧彈改為治療效果)
(被動：移動速度+25%)

TR:
教父	(1)
(將自身HP均分至周圍角色，结束後收回。自身受伤减半) ✔ (LUNA)
(被動：HP 1000，周围友军缓慢恢复生命) ✔ (REX)
狂战士
(血量越低枪械伤害越高，5秒内最低维持1血，5秒后若血量不超过1则死亡)
(被動：擊殺賞金均全額賦予)
疯狂科学家
(電擊彈藥，將瞄準目標吸往自己的方向)
(被動：遭受的AP傷害以電擊雙倍返還)
暗杀者
(消音武器，標記敌方指挥官位置，隱身10秒)
(被動：消音武器有1%的概率暴擊)
纵火犯
(火焰弹药，燃烧伤害附带减速效果)
(被動：高爆手雷改为燃烧瓶)

**/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>
#include <xs>

#define PLUGIN	"CZ Leader"
#define VERSION	"1.8.3"
#define AUTHOR	"ShingekiNoRex & Luna the Reborn"

#define HUD_SHOWMARK	1	//HUD提示消息通道
#define HUD_SHOWHUD		2	//HUD属性信息通道
#define HUD_SHOWGOAL	3	//HUD目标信息通道

#define REDCHAT		1
#define BLUECHAT	2
#define GREYCHAT	3
#define NORMALCHAT	4
#define GREENCHAT	5

#define SCOREATTRIB_DEAD	(1<<0)
#define SCOREATTRIB_BOMB	(1<<1)
#define SCOREATTRIB_VIP		(1<<2)

#define TEAM_UNASSIGNED		0
#define TEAM_TERRORIST		1
#define TEAM_CT				2
#define TEAM_SPECTATOR		3

#define SIGNAL_BUY			(1<<0)
#define SIGNAL_BOMB			(1<<1)
#define SIGNAL_RESCUE		(1<<2)
#define SIGNAL_ESCAPE		(1<<3)
#define SIGNAL_VIPSAFETY	(1<<4)

#define HIDEHUD_WEAPONS		(1<<0)
#define HIDEHUD_FLASHLIGHT	(1<<1)
#define HIDEHUD_ALL			(1<<2)
#define HIDEHUD_HEALTH		(1<<3)
#define HIDEHUD_TIMER		(1<<4)
#define HIDEHUD_MONEY		(1<<5)
#define HIDEHUD_CROSSHAIR	(1<<6)

// weapons redefine
#define CSW_ACR			CSW_AUG
#define CSW_CM901		CSW_GALIL
#define CSW_QBZ95		CSW_FAMAS
#define CSW_SCARL		CSW_SG552
#define CSW_MP7A1		CSW_TMP
#define CSW_PM9			CSW_MAC10
#define CSW_MK46		CSW_M249
#define CSW_KSG12		CSW_M3
#define CSW_STRIKER		CSW_XM1014
#define CSW_ANACONDA	CSW_P228
#define CSW_SVD			CSW_G3SG1
#define CSW_M14EBR		CSW_SG550
#define CSW_P99			CSW_ELITE
#define CSW_M200		CSW_SCOUT

enum TacticalScheme_e
{
	Scheme_UNASSIGNED = 0,	// disputation
	Doctrine_SuperiorFirepower,
	Doctrine_MassAssault,
	Doctrine_GrandBattleplan,
	Doctrine_MobileWarfare,
	
	SCHEMES_COUNT
};

enum Role_e
{
	Role_UNASSIGNED = 0,
	
	Role_Commander = 1,
	Role_SWAT,
	Role_Blaster,
	Role_Sharpshooter,
	Role_Medic,

	Role_Godfather,
	Role_Berserker,
	Role_MadScientist,
	Role_Assassin,
	Role_Arsonist,
	
	ROLE_COUNT
};

stock const g_rgszRoleNames[ROLE_COUNT][] =
{
	"士兵",
	
	"指揮官",
	"S.W.A.T.",
	"爆破手",
	"神射手",
	"軍醫",
	
	"教父",
	"狂戰士",
	"瘋狂科學家",
	"刺客",
	"縱火犯"
};

stock const g_rgszRoleSkills[ROLE_COUNT][] =
{
	"",
	
	"[T]標記教父位置，自身射速加倍&受傷減半",
	"",
	"",
	"",
	"",
	
	"[T]均分HP至周圍角色，结束后收回。自身受傷減半",
	"",
	"",
	"",
	""
};

new const g_rgszTacticalSchemeNames[SCHEMES_COUNT][] = { "舉棋不定", "火力優勢學說", "數量優勢學說", "質量優勢學說", "機動作戰學說" };
new const g_rgszTacticalSchemeDesc[SCHEMES_COUNT][] = { "/y如果多數人/g舉棋不定/y，又或者隊伍內/t存在爭議/y：則全隊/t不會獲得/y任何加成。", "/t每秒/y都會填充當前武器/t最大/y彈容量的/g4%%%%", "/y隊伍/t復活速度/y達到/g極限/y，並且擁有/g雙倍/y人力資源。", "/y緩慢/g補充金錢/y並增加/t造成傷害/y及/t擊殺/y的/g賞金/y。", "/y增援隊員/g部署/y於/t隊長/y附近，並允許在/g任何位置/y購買裝備。" };
new const g_rgiTacticalSchemeDescColor[SCHEMES_COUNT] = { GREYCHAT, REDCHAT, BLUECHAT, BLUECHAT, REDCHAT };

new const g_rgszTeamName[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" };

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

//														 5				  10				  15				  20				  25				30	// if this isn't lined up, please use Notepad++
stock const g_rgiDefaultMaxClip[] = { -1, 13, -1, 10, 1, 7, 1, 30, 30, 1, 30, 20, 25, 20, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 };

new const g_rgszEntityToRemove[][] =
{
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"armoury_entity",
	"game_player_equip",
	"game_player_team"
}

new g_fwBotForwardRegister
new g_iLeader[2], bool:g_bRoundStarted = false, g_szLeaderNetname[2][64], g_rgiTeamMenPower[4];
new Float:g_flNewPlayerScan, bool:g_rgbResurrecting[33], Float:g_flStopResurrectingThink, TacticalScheme_e:g_rgTacticalSchemeVote[33], Float:g_flTeamTacticalSchemeThink, TacticalScheme_e:g_rgTeamTacticalScheme[4], Float:g_rgflTeamTSEffectThink[4], g_rgiBallotBox[4][SCHEMES_COUNT], Float:g_flOpeningBallotBoxes;
new Role_e:g_rgPlayerRole[33], bool:g_rgbUsingSkill[33], bool:g_rgbAllowSkill[33], Float:g_rgflSkillCooldown[33], Float:g_rgflSkillExecutedTime[33];
new cvar_WMDLkilltime, cvar_humanleader, cvar_menpower;
new cvar_TSDmoneyaddinv, cvar_TSDmoneyaddnum, cvar_TSDbountymul, cvar_TSDrefillinv, cvar_TSDrefillratio, cvar_TSDresurrect, cvar_TSVcooldown;

// DIVIDE ET IMPERA
#include "godfather.sma"
#include "commander.sma"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// Ham hooks
	RegisterHam(Ham_Killed, "player", "HamF_Killed");
	RegisterHam(Ham_Killed, "player", "HamF_Killed_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage_Post", 1);
	RegisterHam(Ham_CS_RoundRespawn, "player", "HamF_CS_RoundRespawn_Post", 1);
	
	for (new i = 0; i < sizeof g_rgszWeaponEntity; i++)
	{
		if(!g_rgszWeaponEntity[i][0])
			continue;
		
		if(i == CSW_XM1014 || i == CSW_M3 || i == CSW_C4 || i == CSW_HEGRENADE || i == CSW_KNIFE || i == CSW_SMOKEGRENADE || i == CSW_FLASHBANG)
			continue;

		RegisterHam(Ham_Weapon_PrimaryAttack, g_rgszWeaponEntity[i], "HamF_Weapon_PrimaryAttack_Post", 1);
	}

	// FM hooks
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_StartFrame, "fw_StartFrame_Post", 1);
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	
	// events
	register_logevent("Event_FreezePhaseEnd", 2, "1=Round_Start")
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	
	// messages
	register_message(get_user_msgid("Health"), "Message_Health");
	
	// CVars
	cvar_WMDLkilltime	= register_cvar("lm_dropped_wpn_remove_time",			"60.0");
	cvar_humanleader	= register_cvar("lm_human_player_leadership_priority",	"1");
	cvar_menpower		= register_cvar("lm_starting_menpower_per_player",		"5");
	cvar_TSVcooldown	= register_cvar("lm_TS_voting_cooldown",				"20.0");
	cvar_TSDrefillinv	= register_cvar("lm_TSD_SFD_clip_refill_interval",		"1.0");
	cvar_TSDrefillratio	= register_cvar("lm_TSD_SFD_clip_refill_ratio",			"0.04");
	cvar_TSDresurrect	= register_cvar("lm_TSD_MAD_resurrection_time",			"1.0");
	cvar_TSDmoneyaddinv	= register_cvar("lm_TSD_GBD_account_refill_interval",	"5.0");
	cvar_TSDmoneyaddnum	= register_cvar("lm_TSD_GBD_account_refill_amount",		"200");
	cvar_TSDbountymul	= register_cvar("lm_TSD_GBD_bounty_multiplier",			"2.0");
	
	// client commands
	register_clcmd("vs", "Command_VoteTS");
	register_clcmd("votescheme", "Command_VoteTS");
	register_clcmd("say /votescheme", "Command_VoteTS");
	register_clcmd("say /vs", "Command_VoteTS");
	
	// roles custom initiation
	Godfather_Initialize();
	Commander_Initialize();
	
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1);
}

public plugin_precache()
{
	static szFile[192];
	
	register_forward(FM_Spawn, "fw_Spawn");
	
	// Gamerules
	engfunc(EngFunc_PrecacheSound, "leadermode/start_game_01.wav");
	engfunc(EngFunc_PrecacheSound, "leadermode/start_game_02.wav");
	engfunc(EngFunc_PrecacheSound, "leadermode/unable_manpower_alert.wav");
	
	// Schemes
	engfunc(EngFunc_PrecacheSound, "leadermode/money_in.wav");
	
	for (new i = 1; i <= 7; i++)
	{
		formatex(szFile, charsmax(szFile), "leadermode/infantry_rifle_cartridge_0%d.wav", i);
		engfunc(EngFunc_PrecacheSound, szFile);
	}
	
	// Roles
	engfunc(EngFunc_PrecacheSound, GODFATHER_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, GODFATHER_REVOKE_SFX);
	engfunc(EngFunc_PrecacheSound, COMMANDER_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, COMMANDER_REVOKE_SFX);
}

public client_putinserver(pPlayer)
{
	g_rgbResurrecting[pPlayer] = false;
}

public HamF_Killed(iVictim, iAttacker, bShouldGib)
{
	if (!is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return;
	
	new iVictimTeam = get_pdata_int(iVictim, m_iTeam);
	new iAttackerTeam = get_pdata_int(iAttacker, m_iTeam);
	
	if (g_rgTeamTacticalScheme[iAttackerTeam] == Doctrine_GrandBattleplan && iVictimTeam != iAttackerTeam)
	{
		// for the +600 efx, don't notify client.dll here.
		set_pdata_int(iAttacker, m_iAccount, get_pdata_int(iAttacker, m_iAccount) + floatround(300.0 * (get_pcvar_float(cvar_TSDbountymul) - 1.0)) );
	}
}

public HamF_Killed_Post(victim, attacker, shouldgib)
{
	if (victim == g_iLeader[0])
	{
		print_chat_color(0, REDCHAT, "%s已被擊斃!", g_rgszRoleNames[Role_Godfather]);
		Godfather_TerminateSkill();
		Commander_RevokeSkill(COMMANDER_TASK);
	}
	else if (victim == g_iLeader[1])
	{
		print_chat_color(0, BLUECHAT, "%s陣亡!", g_rgszRoleNames[Role_Commander]);
		Commander_TerminateSkill();
	}

	if (!is_user_connected(victim))
		return;

	new iTeam = get_pdata_int(victim, m_iTeam);
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return;
	
	if (!is_user_alive(g_iLeader[iTeam - 1]))
		return;
	
	new Float:flHealth;
	pev(g_iLeader[iTeam - 1], pev_health, flHealth);
	
	new iResurrectionTime = max(floatround(flHealth / 1000.0 * 10.0), 1);
	if (g_rgTeamTacticalScheme[iTeam] == Doctrine_MassAssault)
		iResurrectionTime = floatround(get_pcvar_float(cvar_TSDresurrect));
	
	set_task(float(iResurrectionTime), "Task_PlayerResurrection", victim);
	UTIL_BarTime(victim, iResurrectionTime);
	g_rgbResurrecting[victim] = true;
}

public HamF_TakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	if (is_user_alive(iVictim) && g_rgbUsingSkill[iVictim])
	{
		if (g_rgPlayerRole[iVictim] == Role_Godfather || g_rgPlayerRole[iVictim] == Role_Commander)
			SetHamParamFloat(4, flDamage * 0.5);
	}
	
	return HAM_IGNORED;
}

public HamF_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	if (!is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return;
	
	new iVictimTeam = get_pdata_int(iVictim, m_iTeam);
	new iAttackerTeam = get_pdata_int(iAttacker, m_iTeam);
	
	if (iVictimTeam != iAttackerTeam)
		UTIL_AddAccount(iAttacker, floatround(flDamage * (g_rgTeamTacticalScheme[iAttackerTeam] == Doctrine_GrandBattleplan ? get_pcvar_float(cvar_TSDbountymul) : 1.0 )) );
	else
		UTIL_AddAccount(iAttacker, -floatround(flDamage * 3.0));
}

public HamF_Weapon_PrimaryAttack_Post(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	// Firerate for CT leader
	if (is_user_alive(iPlayer) && iPlayer == g_iLeader[TEAM_CT-1])
		set_pdata_float(iEntity, m_flNextPrimaryAttack, get_pdata_float(iEntity, m_flNextPrimaryAttack), 4);
}

public HamF_CS_RoundRespawn_Post(pPlayer)
{
	if (!is_user_connected(pPlayer))
		return;
	
	new iTeam = get_pdata_int(pPlayer, m_iTeam);
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return;

	if (!g_bRoundStarted)	// avoid the new round error
		return;
	
	if (g_rgTeamTacticalScheme[iTeam] == Doctrine_MobileWarfare && is_user_alive(g_iLeader[iTeam - 1]))
	{
		new Float:vecCandidates[9][3], Float:vecDest[3], bool:bFind = false;
		for (new i = 0; i < 9; i++)
			pev(g_iLeader[iTeam - 1], pev_origin, vecCandidates[i]);
		
		xs_vec_add(vecCandidates[0], Float:{0.0, 128.0, 0.0}, vecCandidates[0]);
		xs_vec_add(vecCandidates[1], Float:{128.0, 128.0, 0.0}, vecCandidates[1]);
		xs_vec_add(vecCandidates[2], Float:{128.0, 0.0, 0.0}, vecCandidates[2]);
		xs_vec_add(vecCandidates[3], Float:{128.0, -128.0, 0.0}, vecCandidates[3]);
		xs_vec_add(vecCandidates[4], Float:{0.0, -128.0, 0.0}, vecCandidates[4]);
		xs_vec_add(vecCandidates[5], Float:{-128.0, -128.0, 0.0}, vecCandidates[5]);
		xs_vec_add(vecCandidates[6], Float:{-128.0, 0.0, 0.0}, vecCandidates[6]);
		xs_vec_add(vecCandidates[7], Float:{-128.0, 128.0, 0.0}, vecCandidates[7]);
		
		new Float:flFraction, tr[8];
		for (new i = 0; i < 8; i++)
		{
			tr[i] = create_tr2();
			engfunc(EngFunc_TraceHull, vecCandidates[8], vecCandidates[i], DONT_IGNORE_MONSTERS, HULL_HEAD, g_iLeader[iTeam - 1], tr[i]);
			get_tr2(tr[i], TR_flFraction, flFraction);
			
			if (flFraction >= 1.0)
			{
				bFind = true;
				xs_vec_copy(vecCandidates[i], vecDest);
				break;
			}
			
			get_tr2(tr[i], TR_vecEndPos, vecCandidates[i]);
			
			if (UTIL_CheckPassibility(vecCandidates[i]))
			{
				bFind = true;
				xs_vec_copy(vecCandidates[i], vecDest);
				break;
			}
		}
		
		if (bFind)
		{
			set_pev(pPlayer, pev_flags, pev(pPlayer, pev_flags) | FL_DUCKING);
			engfunc(EngFunc_SetSize, pPlayer, {-16.0, -16.0, -18.0}, {16.0, 16.0, 32.0});
			set_pev(pPlayer, pev_view_ofs, {0.0, 0.0, 12.0});
			set_pev(pPlayer, pev_origin, vecDest);
		}
		
		for (new i = 0; i < 8; i++)
			free_tr2(tr[i]);
	}
}

public fw_AddToFullPack_Post(ES_Handle, e, iEntity, iHost, iHostFlags, iPlayer, iSet)
{
	if (!is_user_connected(iHost))
		return
	
	if (is_user_bot(iHost))
		return
	
	if (iPlayer && is_user_alive(iHost))
	{
		if (iEntity == g_iLeader[0])
		{
			set_es(ES_Handle, ES_RenderFx, kRenderFxGlowShell)
			set_es(ES_Handle, ES_RenderColor, {255, 0, 0})
			set_es(ES_Handle, ES_RenderAmt, 1)
			set_es(ES_Handle, ES_RenderMode, kRenderNormal)
		}
		if (iEntity == g_iLeader[1])
		{
			set_es(ES_Handle, ES_RenderFx, kRenderFxGlowShell)
			set_es(ES_Handle, ES_RenderColor, {0, 0, 255})
			set_es(ES_Handle, ES_RenderAmt, 1)
			set_es(ES_Handle, ES_RenderMode, kRenderNormal)
		}
	}
}

public fw_SetModel(iEntity, szModel[])
{
	if (strlen(szModel) < 8)
		return FMRES_IGNORED
	
	if (szModel[7] != 'w' || szModel[8] != '_')
		return FMRES_IGNORED
	
	static classname[32]
	pev(iEntity, pev_classname, classname, charsmax(classname))
	
	if (strcmp(classname, "weaponbox"))
		return FMRES_IGNORED
	
	set_pev(iEntity, pev_nextthink, get_gametime() + get_pcvar_float(cvar_WMDLkilltime));
	
	return FMRES_IGNORED
}

public fw_StartFrame_Post()
{
	static Float:fCurTime;
	global_get(glb_time, fCurTime);
	
	if (g_bRoundStarted && g_flNewPlayerScan <= fCurTime)
	{
		g_flNewPlayerScan = fCurTime + 3.0;
		
		if (!is_user_connected(g_iLeader[TEAM_CT - 1]) || !is_user_connected(g_iLeader[TEAM_TERRORIST - 1]))
			goto TAG_SKIP_NEW_PLAYER_SCAN;
		
		new Float:flHealth[4];
		pev(g_iLeader[TEAM_CT - 1], pev_health, flHealth[TEAM_CT]);
		pev(g_iLeader[TEAM_TERRORIST - 1], pev_health, flHealth[TEAM_TERRORIST]);
		
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (!is_user_connected(i))
				continue;
			
			if (is_user_alive(i))
				continue;
			
			if (g_rgbResurrecting[i])
				continue;
			
			new iTeam = get_pdata_int(i, m_iTeam);
			if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
				return;
		
			if (!is_user_alive(g_iLeader[0]) && iTeam == TEAM_TERRORIST)
				return;
			
			if (!is_user_alive(g_iLeader[1]) && iTeam == TEAM_CT)
				return;

			new iResurrectionTime = max(floatround(flHealth[iTeam] / 1000.0 * 10.0), 1);
			if (g_rgTeamTacticalScheme[iTeam] == Doctrine_MassAssault)
				iResurrectionTime = floatround(get_pcvar_float(cvar_TSDresurrect));

			set_task(float(iResurrectionTime), "Task_PlayerResurrection", i);
			UTIL_BarTime(i, iResurrectionTime);
			g_rgbResurrecting[i] = true;
		}
TAG_SKIP_NEW_PLAYER_SCAN:
	}
	
	if (g_flStopResurrectingThink <= fCurTime)
	{
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (!is_user_connected(i))
				continue;
			
			if (is_user_bot(i))
				continue;
			
			if (!g_rgbResurrecting[i])
				continue;
			
			new iTeam = get_pdata_int(i, m_iTeam);
			
			if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
				continue;
			
			if (!is_user_alive(g_iLeader[iTeam - 1]) || g_rgiTeamMenPower[iTeam] <= 0)
			{
				UTIL_BarTime(i, 0);	// hide the bartime.
				g_rgbResurrecting[i] = false;
			}
		}
		
		g_flStopResurrectingThink = fCurTime + 0.1;
	}
	
	if (g_flOpeningBallotBoxes <= fCurTime)
	{
		g_flOpeningBallotBoxes = fCurTime + 0.1;
		
		for (new i = 0; i < 4; i++)
			for (new TacticalScheme_e:j = Scheme_UNASSIGNED; j < SCHEMES_COUNT; j++)
				g_rgiBallotBox[i][j] = 0;	// re-zero before each vote.
		
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (!is_user_connected(i))
				continue;
			
			if (is_user_bot(i))	// TODO: shall bots get to vote?
				continue;
			
			new iTeam = get_pdata_int(i, m_iTeam);
			if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
				continue;
			
			g_rgiBallotBox[iTeam][g_rgTacticalSchemeVote[i]]++;
		}
	}
	
	if (g_flTeamTacticalSchemeThink <= fCurTime)	// Team Tactical Scheme Voting Think
	{
		g_flTeamTacticalSchemeThink = fCurTime + (g_bRoundStarted ? get_pcvar_float(cvar_TSVcooldown) : 0.2);
		
		for (new j = TEAM_TERRORIST; j <= TEAM_CT; j++)
		{
			new TacticalScheme_e:iSavedTS = g_rgTeamTacticalScheme[j];
			
			for (new TacticalScheme_e:i = Scheme_UNASSIGNED; i < SCHEMES_COUNT; i++)
			{
				if (g_rgiBallotBox[j][i] > g_rgiBallotBox[j][g_rgTeamTacticalScheme[j]])
					g_rgTeamTacticalScheme[j] = i;
				else if (g_rgTeamTacticalScheme[j] != i && g_rgiBallotBox[j][i] > 0 && g_rgiBallotBox[j][i] == g_rgiBallotBox[j][g_rgTeamTacticalScheme[j]])	// disputation
					g_rgTeamTacticalScheme[j] = Scheme_UNASSIGNED;
			}
			
			if (iSavedTS != g_rgTeamTacticalScheme[j])	// announce new scheme.
			{
				new rgColor[3] = { 255, 100, 255 };
				new Float:flCoordinate[2] = { -1.0, 0.30 };
				new Float:rgflTime[4] = { 6.0, 6.0, 0.1, 0.2 };
				
				for (new i = 1; i <= global_get(glb_maxClients); i++)
				{
					if (!is_user_connected(i))
						continue;
					
					if (is_user_bot(i))
						continue;
					
					if (get_pdata_int(i, m_iTeam) == j)
						ShowHudMessage(i, rgColor, flCoordinate, 0, rgflTime, -1, "已開始執行新團隊策略: %s", g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[j]]);
				}
				
				// the effect of Doctrine_MassAssault is here instead of below.
				if (g_rgTeamTacticalScheme[j] == Doctrine_MassAssault)	// switching to Doctrine_MassAssault
					g_rgiTeamMenPower[j] *= 2;
				else if (iSavedTS == Doctrine_MassAssault)	// switching to others
					g_rgiTeamMenPower[j] /= 2;
			}
		}
	}
	
	for (new j = TEAM_TERRORIST; j <= TEAM_CT; j++)	// Team Tactical Scheme Effect Think
	{
		if (g_rgflTeamTSEffectThink[j] <= fCurTime && g_rgTeamTacticalScheme[j] != Scheme_UNASSIGNED)
		{
			for (new i = 1; i <= global_get(glb_maxClients); i++)
			{
				if (!is_user_connected(i))
					continue;
				
				if (get_pdata_int(i, m_iTeam) != j)
					continue;
				
				switch (g_rgTeamTacticalScheme[j])
				{
					case Doctrine_GrandBattleplan:
					{
						if (get_pdata_int(i, m_iAccount) < 16000)
						{
							UTIL_AddAccount(i, get_pcvar_num(cvar_TSDmoneyaddnum));
							client_cmd(i, "spk %s", "leadermode/money_in.wav");
						}
					}
						
					case Doctrine_SuperiorFirepower:
					{
						new iEntity = get_pdata_cbase(i, m_pActiveItem);
						if (pev_valid(iEntity))
						{
							new iId = get_pdata_int(iEntity, m_iId, 4);
							if (iId != CSW_C4 && iId != CSW_HEGRENADE && iId != CSW_KNIFE && iId != CSW_SMOKEGRENADE && iId != CSW_FLASHBANG && get_pdata_int(iEntity, m_iClip, 4) < 127)	// these weapons are not allowed to have clip.
							{
								set_pdata_int(iEntity, m_iClip, get_pdata_int(iEntity, m_iClip, 4) + floatround(float(g_rgiDefaultMaxClip[iId]) * get_pcvar_float(cvar_TSDrefillratio)), 4);
								
								if (!random_num(0, 3))	// constant sound makes player annoying.
								{
									static szSound[64];
									formatex(szSound, charsmax(szSound), "leadermode/infantry_rifle_cartridge_0%d.wav", random_num(1, 7));
									client_cmd(i, "spk %s", szSound);
								}
							}
						}
					}
					
					default:
						continue;
				}
			}
			
			switch (g_rgTeamTacticalScheme[j])
			{
				case Doctrine_GrandBattleplan:
					g_rgflTeamTSEffectThink[j] = fCurTime + get_pcvar_float(cvar_TSDmoneyaddinv);
				
				case Doctrine_SuperiorFirepower:
					g_rgflTeamTSEffectThink[j] = fCurTime + get_pcvar_float(cvar_TSDrefillinv);
				
				default:
					g_rgflTeamTSEffectThink[j] = fCurTime + 5.0;
			}
		}
	}
}

public fw_PlayerPostThink_Post(pPlayer)
{
	if (!is_user_connected(pPlayer))
		return;
	
	new iTeam = get_pdata_int(pPlayer, m_iTeam);
	
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return;
	
	// HUD
	if (!is_user_bot(pPlayer))
	{
		new rgColor[3] = { 255, 255, 0 };
		new Float:flCoordinate[2] = { -1.0, 0.90 };
		new Float:rgflTime[4] = { 0.1, 0.1, 0.0, 0.0 };
		
		static szText[192], szSkillText[192], szGoal[192];
		formatex(szSkillText, charsmax(szSkillText), "");	// have to clear it each frame, or the strcpy() will fuck everything up.
		
		if (!g_rgbAllowSkill[pPlayer] && !g_rgbUsingSkill[pPlayer])	// Cooling down
		{
			new Float:flCooldownTimeLeft = g_rgflSkillCooldown[pPlayer] - get_gametime();
			if (flCooldownTimeLeft > 0.0)
			{
				new Float:flCooldownLength = 60.0;	// UNDONE: what about others?
				new iDotNum = floatround((flCooldownTimeLeft / flCooldownLength) * 20.0);	// keep the 20.0 sync with the 20 below.
				new iLineNum = max(20 - iDotNum, 0);
				
				for (new i = 0; i < iLineNum; i++)
					strcat(szSkillText, "|", charsmax(szSkillText));
				
				for (new i = 0; i < iDotNum; i++)
					strcat(szSkillText, "•", charsmax(szSkillText));
			}
		}
		else if (!g_rgbAllowSkill[pPlayer] && g_rgbUsingSkill[pPlayer])	// still working
		{
			new Float:flSkillEffectLeft = get_gametime() - g_rgflSkillExecutedTime[pPlayer];	// YES, these two are reverted. think it through logic.
			if (flSkillEffectLeft > 0.0)
			{
				new Float:flSkillEffectLength = 20.0;	// UNDONE: what about others?
				new iDotNum = floatround((flSkillEffectLeft / flSkillEffectLength) * 20.0);
				new iLineNum = max(20 - iDotNum, 0);
				
				for (new i = 0; i < iLineNum; i++)
					strcat(szSkillText, "|", charsmax(szSkillText));
				
				for (new i = 0; i < iDotNum; i++)
					strcat(szSkillText, "•", charsmax(szSkillText));
			}
		}
		
		if (!strlen(szSkillText))
			copy(szSkillText, charsmax(szSkillText), g_rgszRoleSkills[g_rgPlayerRole[pPlayer]]);
		
		if (!is_user_alive(g_iLeader[iTeam - 1]) && g_iLeader[iTeam - 1] > 0)	// prevent this text appears in freezing phase.
			formatex(szText, charsmax(szText), "身份: %s^n%s^n%s已陣亡|兵源補給中斷|%s", g_rgszRoleNames[g_rgPlayerRole[pPlayer]], szSkillText, g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[iTeam]]);
		else
			formatex(szText, charsmax(szText), "身份: %s^n%s^n%s: %s|兵源剩餘: %d|%s", g_rgszRoleNames[g_rgPlayerRole[pPlayer]], szSkillText, g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_szLeaderNetname[iTeam - 1], g_rgiTeamMenPower[iTeam], g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[iTeam]]);
		
		if (!is_user_alive(g_iLeader[2 - iTeam]) && g_iLeader[2 - iTeam] > 0)
			formatex(szGoal, charsmax(szGoal), "任务目标：扫荡残敌");
		else
			formatex(szGoal, charsmax(szGoal), "任务目标：击杀敌方%s %s", g_rgszRoleNames[g_iLeader[2 - iTeam], g_szLeaderNetname[2 - iTeam]]);

		ShowHudMessage(pPlayer, rgColor, flCoordinate, 0, rgflTime, HUD_SHOWHUD, szText);
		ShowHudMessage(pPlayer, rgColor, { -1.0， 0.10 }, 0, rgflTime, HUD_SHOWGOAL, szGoal);
	}
	
	if (g_rgTeamTacticalScheme[iTeam] == Doctrine_MobileWarfare)
	{
		/**
		// copy from player.h
		class CUnifiedSignals
		{
		public:
			CUnifiedSignals(void)
			{
				m_flSignal = 0;
				m_flState = 0;
			}

		public:
			void Update(void)
			{
				m_flState = m_flSignal;
				m_flSignal = 0;
			}

			void Signal(int flags) { m_flSignal |= flags; }
			int GetSignal(void) { return m_flSignal; }
			int GetState(void) { return m_flState; }

		private:
			int m_flSignal;	// this is m_signals[0]
			int m_flState;	// this is m_signals[1]
		};
		**/
		
		// Doctrine_MobileWarfare allows player to buying everywhere.
		// this signal flag will be cancelled automatically if you have another scheme executed.
		set_pdata_int(pPlayer, m_signals[0], get_pdata_int(pPlayer, m_signals[0]) | SIGNAL_BUY);
	}

	if (!g_rgbUsingSkill[pPlayer] && !g_rgbAllowSkill[pPlayer])
	{
		static Float:fCurTime;
		global_get(glb_time, fCurTime);
		if (g_rgflSkillCooldown[pPlayer] <= fCurTime)
		{
			g_rgbAllowSkill[pPlayer] = true;
			print_chat_color(pPlayer, GREENCHAT, "技能冷卻完毕！");
		}
	}
	
	if (iTeam == TEAM_CT)	// Commander's skill
	{
		Commander_SkillThink(pPlayer);
	}
}

public fw_Spawn(iEntity)	// 移除任务实体
{
	if (!pev_valid(iEntity))
		return FMRES_IGNORED
	
	static classname[32]
	pev(iEntity, pev_classname, classname, charsmax(classname))
	
	for (new i = 0; i < sizeof g_rgszEntityToRemove; i ++)
	{
		if (equal(classname, g_rgszEntityToRemove[i]))
		{
			engfunc(EngFunc_RemoveEntity, iEntity)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public fw_CmdStart(iPlayer, uc_handle, seed)
{
	if(!is_user_alive(iPlayer))
		return FMRES_IGNORED;

	if(get_uc(uc_handle, UC_Impulse) != 201)
		return FMRES_IGNORED;

	if(g_rgbUsingSkill[iPlayer])
	{
		print_chat_color(iPlayer, GREYCHAT, "技能正在使用中！");
		return FMRES_IGNORED;
	}

	if(!g_rgbAllowSkill[iPlayer])
	{
		print_chat_color(iPlayer, GREYCHAT, "技能正在冷卻中！");
		return FMRES_IGNORED;
	}

	switch (g_rgPlayerRole[iPlayer])
	{
		case Role_Godfather:
		{
			Godfather_ExecuteSkill(iPlayer);
		}
		case Role_Commander:
		{
			Commander_ExecuteSkill(iPlayer);
		}
		default:
			return FMRES_IGNORED;
	}

	print_chat_color(iPlayer, GREENCHAT, "技能已施放！");
	g_rgbUsingSkill[iPlayer] = true;
	g_rgbAllowSkill[iPlayer] = false;
	set_uc(uc_handle, UC_Impulse, 0);

	return FMRES_IGNORED;
}

public Task_PlayerResurrection(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return;
	
	if (is_user_alive(iPlayer))
		return;
	
	new iTeam = get_pdata_int(iPlayer, m_iTeam);
	
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)	// this is a spectator
		return;
	
	if (!is_user_alive(g_iLeader[iTeam - 1]))
		return;
	
	if (g_rgiTeamMenPower[iTeam] <= 0)
		return;
	
	ExecuteHamB(Ham_CS_RoundRespawn, iPlayer);
	g_rgbResurrecting[iPlayer] = false;
	g_rgiTeamMenPower[iTeam] --;
	
	if (!g_rgiTeamMenPower[iTeam])
	{
		new rgColor[3] = { 255, 100, 255 };
		new Float:flCoordinate[2] = { -1.0, 0.30 };
		new Float:rgflTime[4] = { 6.0, 6.0, 0.1, 0.2 };
		
		ShowHudMessage(0, rgColor, flCoordinate, 0, rgflTime, -1, "%s可用兵源已經耗盡!", g_rgszTeamName[iTeam]);
		client_cmd(0, "spk %s", "leadermode/unable_manpower_alert.wav");
	}
}

public Event_FreezePhaseEnd()
{
	g_iLeader[0] = -1;
	g_iLeader[1] = -1;
	
	new szPlayer[2][33], iAmount[2], bHumanPriority = get_pcvar_num(cvar_humanleader);
	for (new i = 1; i < 33; i++)
	{
		if (!is_user_alive(i))
			continue;
		
		if (bHumanPriority && is_user_bot(i))	// select human player first.
			continue;
		
		if (get_pdata_int(i, m_iTeam) == TEAM_TERRORIST)
		{
			iAmount[0] ++;
			szPlayer[0][iAmount[0]] = i;
		}
		else if (get_pdata_int(i, m_iTeam) == TEAM_CT)
		{
			iAmount[1] ++;
			szPlayer[1][iAmount[1]] = i;
		}
	}
	
	if (!iAmount[0])
	{
		for (new i = 1; i < 33; i++)
		{
			if (!is_user_alive(i))
				continue;
			
			if (get_pdata_int(i, m_iTeam) == TEAM_TERRORIST)
			{
				iAmount[0] ++;
				szPlayer[0][iAmount[0]] = i;
			}
		}
	}
	
	if (!iAmount[1])
	{
		for (new i = 1; i < 33; i++)
		{
			if (!is_user_alive(i))
				continue;
			
			if (get_pdata_int(i, m_iTeam) == TEAM_CT)
			{
				iAmount[1] ++;
				szPlayer[1][iAmount[1]] = i;
			}
		}
	}
	
	if (!iAmount[0] || !iAmount[1])
		return;
	
	g_iLeader[0] = szPlayer[0][random_num(1, iAmount[0])];
	g_iLeader[1] = szPlayer[1][random_num(1, iAmount[1])];
	pev(g_iLeader[0], pev_netname, g_szLeaderNetname[0], charsmax(g_szLeaderNetname[]));
	pev(g_iLeader[1], pev_netname, g_szLeaderNetname[1], charsmax(g_szLeaderNetname[]));
	set_pev(g_iLeader[0], pev_health, 1000.0);
	set_pev(g_iLeader[0], pev_max_health, 1000.0);
	set_pev(g_iLeader[1], pev_health, 1000.0);
	set_pev(g_iLeader[1], pev_max_health, 1000.0);
	
	new rgColor[3] = { 255, 100, 255 };
	new Float:flCoordinate[2] = { -1.0, 0.30 };
	new Float:rgflTime[4] = { 6.0, 6.0, 0.1, 0.2 };
	
	g_rgPlayerRole[g_iLeader[0]] = Role_Godfather;
	ShowHudMessage(g_iLeader[0], rgColor, flCoordinate, 0, rgflTime, -1, "你已被選定為%s!", g_rgszRoleNames[Role_Godfather]);
	g_rgPlayerRole[g_iLeader[1]] = Role_Commander;
	ShowHudMessage(g_iLeader[1], rgColor, flCoordinate, 0, rgflTime, -1, "你已被選定為%s!", g_rgszRoleNames[Role_Commander]);
	
	g_bRoundStarted = true;

	new iPlayerAmount = 0;
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_alive(i))
			continue;
		
		iPlayerAmount ++;
		
		if (is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) == TEAM_TERRORIST)	// for TRs
		{
			print_chat_color(i, REDCHAT, "%s是%s, 殺死他以切斷%s兵源補給!", g_szLeaderNetname[TEAM_CT - 1], g_rgszRoleNames[Role_Commander], g_rgszTeamName[TEAM_CT]);
		}
		else if (get_pdata_int(i, m_iTeam) == TEAM_CT)	// for CTs
		{
			print_chat_color(i, BLUECHAT, "%s是%s, 殺死他以切斷%s兵源補給!", g_szLeaderNetname[TEAM_TERRORIST - 1], g_rgszRoleNames[Role_Godfather], g_rgszTeamName[TEAM_TERRORIST]);
		}
		
		set_pdata_int(i, m_iHideHUD, get_pdata_int(i, m_iHideHUD) | HIDEHUD_TIMER);
	}
	
	emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"));
	ewrite_byte(g_iLeader[0]);	// head of TRs
	ewrite_byte(SCOREATTRIB_BOMB);
	emessage_end();
	
	emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"));
	ewrite_byte(g_iLeader[1]);	// head of CTs
	ewrite_byte(SCOREATTRIB_VIP);
	emessage_end();
	
	g_rgiTeamMenPower[TEAM_CT] = get_pcvar_num(cvar_menpower) * iPlayerAmount;
	g_rgiTeamMenPower[TEAM_TERRORIST] = get_pcvar_num(cvar_menpower) * iPlayerAmount;
	
	for (new i = TEAM_TERRORIST; i <= TEAM_CT; i++)
		if (g_rgTeamTacticalScheme[i] == Doctrine_MassAssault)
			g_rgiTeamMenPower[i] *= 2;
	
	client_cmd(0, "spk %s", random_num(0, 1) ? "leadermode/start_game_01.wav" : "leadermode/start_game_02.wav");
}

public Event_HLTV()
{
	g_iLeader[0] = -1;
	g_iLeader[1] = -1;
	
	formatex(g_szLeaderNetname[0], charsmax(g_szLeaderNetname[]), "未揭示");
	formatex(g_szLeaderNetname[1], charsmax(g_szLeaderNetname[]), "未揭示");
	
	for (new i = 0; i < 33; i++)
		g_rgbResurrecting[i] = false;
	
	g_bRoundStarted = false;
	
	// custom role HLTV events
	Godfather_TerminateSkill();
	Commander_TerminateSkill();

	for (new i = 1; i <= global_get(glb_maxClients); i ++)
	{
		if (is_user_connected(i))
		{
			g_rgPlayerRole[i] = Role_UNASSIGNED;
			g_rgbUsingSkill[i] = false;
			g_rgflSkillCooldown[i] = 0.0;
			
			set_pdata_int(i, m_iHideHUD, get_pdata_int(i, m_iHideHUD) & ~HIDEHUD_TIMER);
		}
	}
}

public Message_Health(msg_id, msg_dest, msg_entity)
{
	if (!is_user_alive(msg_entity))
		return PLUGIN_CONTINUE;
	
	if (msg_entity != g_iLeader[0] && msg_entity != g_iLeader[1])
		return PLUGIN_CONTINUE;

	new Float:flHealth;
	pev(msg_entity, pev_health, flHealth);

	set_msg_arg_int(1, ARG_BYTE, max(floatround(flHealth / 1000.0 * 100.0), 1));
	return PLUGIN_CONTINUE;
}

public Command_VoteTS(pPlayer)
{
	if (!is_user_connected(pPlayer))
		return PLUGIN_HANDLED;
	
	new iTeam = get_pdata_int(pPlayer, m_iTeam);
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return PLUGIN_HANDLED;
	
	new szBuffer[192];
	formatex(szBuffer, charsmax(szBuffer), "\r當前策略: \y%s^n\w投票以變更團隊策略:", g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[iTeam]]);
	
	new hMenu = menu_create(szBuffer, "MenuHandler_VoteTS");
	
	new szItem[SCHEMES_COUNT][64];
	for (new TacticalScheme_e:i = Scheme_UNASSIGNED; i < SCHEMES_COUNT; i++)
		formatex(szItem[i], charsmax(szItem[]), "\w%s (\y%d\w人支持)", g_rgszTacticalSchemeNames[i], g_rgiBallotBox[iTeam][i]);
	
	strcat(szItem[g_rgTacticalSchemeVote[pPlayer]], " - 已投票", charsmax(szItem[]))
	
	for (new TacticalScheme_e:i = Scheme_UNASSIGNED; i < SCHEMES_COUNT; i++)
		menu_additem(hMenu, szItem[i]);
	
	menu_setprop(hMenu, MPROP_EXIT, MEXIT_ALL);
	menu_display(pPlayer, hMenu, 0);
	return PLUGIN_HANDLED;
}

public MenuHandler_VoteTS(pPlayer, hMenu, iItem)
{
	if (iItem >= 0)	// for example, MENU_EXIT is -3... you can see the pattern.
	{
		g_rgTacticalSchemeVote[pPlayer] = TacticalScheme_e:iItem;
		UTIL_ColorfulPrintChat(pPlayer, g_rgszTacticalSchemeDesc[TacticalScheme_e:iItem], g_rgiTacticalSchemeDescColor[TacticalScheme_e:iItem]);
	}
	
	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}

public fw_BotForwardRegister_Post(iPlayer)
{
	if (is_user_bot(iPlayer))
	{
		unregister_forward(FM_PlayerPostThink, g_fwBotForwardRegister, 1);
		
		RegisterHamFromEntity(Ham_Killed, iPlayer, "HamF_Killed");
		RegisterHamFromEntity(Ham_Killed, iPlayer, "HamF_Killed_Post", 1);
		RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "HamF_TakeDamage_Post", 1);
		RegisterHamFromEntity(Ham_CS_RoundRespawn, iPlayer, "HamF_CS_RoundRespawn_Post", 1);
	}
}

stock print_chat_color(const iPlayer, const Color, const Message[], any:...)
{
	static buffer[192]
	if (1 <= Color <= 3) buffer[0] = 0x03
	else if (Color == 4) buffer[0] = 0x01
	else if (Color == 5) buffer[0] = 0x04
	vformat(buffer[1], charsmax(buffer), Message, 4)
	ShowChat(iPlayer, Color, buffer)
}

stock ShowChat(const iPlayer, const Color, const Message[])
{
	new Client
	
	if (!iPlayer)
	{
		for (Client = 1; Client < 33; Client ++)
		{
			if (!is_user_connected(Client))
				continue
	
			break
		}
	}
	
	Client = max(Client, iPlayer)
	if (!is_user_connected(Client))
		return	

	if (1 <= Color <= 3)
	{
		message_begin(iPlayer ? MSG_ONE : MSG_BROADCAST, get_user_msgid("TeamInfo"), _, Client)
		write_byte(Client)
		write_string(g_rgszTeamName[Color])
		message_end()
	}
	
	message_begin(iPlayer ? MSG_ONE : MSG_BROADCAST, get_user_msgid("SayText"), _, Client)
	write_byte(Client)
	write_string(Message)
	message_end()
	
	if (1 <= Color <= 3)
	{
		message_begin(iPlayer ? MSG_ONE : MSG_BROADCAST, get_user_msgid("TeamInfo"), _, Client)
		write_byte(Client)
		write_string(g_rgszTeamName[get_pdata_int(Client, m_iTeam, 5)])
		message_end()
	}
}

stock UTIL_ColorfulPrintChat(pPlayer, const szText[], iTeamColor = 0, any:...)
{
	static szBuffer[192];
	vformat(szBuffer, charsmax(szBuffer), szText, 4);
	
	replace_all(szBuffer, charsmax(szBuffer), "/y", "^1");	// yellow
	replace_all(szBuffer, charsmax(szBuffer), "/t", "^3");	// team
	replace_all(szBuffer, charsmax(szBuffer), "/g", "^4");	// green
	
	new bool:bAll = !(pPlayer > 0);
	if (!is_user_connected(pPlayer))
	{
		bAll = true;
		
		for (pPlayer = 1; pPlayer <= global_get(glb_maxClients); pPlayer++)
		{
			if (is_user_connected(pPlayer))
				break;	// the "tool-ish guy"
		}
	}
	
	if (REDCHAT <= iTeamColor <= GREYCHAT)
	{
		message_begin(bAll ? MSG_ALL : MSG_ONE, get_user_msgid("TeamInfo"), _, pPlayer);
		write_byte(pPlayer);
		write_string(g_rgszTeamName[iTeamColor]);
		message_end();
	}
	
	message_begin(bAll ? MSG_ALL : MSG_ONE, get_user_msgid("SayText"), _, pPlayer);
	write_byte(pPlayer);
	write_string(szBuffer);
	message_end();
	
	if (REDCHAT <= iTeamColor <= GREYCHAT)
	{
		message_begin(bAll ? MSG_ALL : MSG_ONE, get_user_msgid("TeamInfo"), _, pPlayer);
		write_byte(pPlayer);
		write_string(g_rgszTeamName[get_pdata_int(pPlayer, m_iTeam)]);
		message_end();
	}
}

stock fm_set_user_money(index, iMoney, bool:bSignal = true)
{
	if (!is_user_connected(index))
		return;
	
	if (iMoney > 16000)
		iMoney = 16000;
	else if (iMoney < 800)
		iMoney = 800;

	set_pdata_int(index, m_iAccount, iMoney);

	emessage_begin(MSG_ONE, get_user_msgid("Money"), {0,0,0}, index);
	ewrite_long(iMoney);
	ewrite_byte(bSignal);
	emessage_end();
}

stock UTIL_AddAccount(pPlayer, iAmount, bool:bSignal = true)
{
	fm_set_user_money(pPlayer, get_pdata_int(pPlayer, m_iAccount) + iAmount, bSignal);
}

stock UTIL_BarTime(pPlayer, iTime)
{
	emessage_begin(MSG_ONE, get_user_msgid("BarTime"), _, pPlayer);
	ewrite_short(iTime);
	emessage_end();
}

stock ShowHudMessage(iPlayer, const Color[3], const Float:Coordinate[2], const Effects, const Float:Time[4], const Channel, const Message[], any:...)
{
	static buffer[192];
	vformat(buffer, charsmax(buffer), Message, 8);
	
	set_hudmessage(Color[0], Color[1], Color[2], Coordinate[0], Coordinate[1], Effects, Time[0], Time[1], Time[2], Time[3], Channel);
	show_hudmessage(iPlayer, buffer);
}

stock DEBUG_LOG_TXT(const szText[], any:...)
{
	static bool:bInitiated;
	static hFile;
	
	if (!bInitiated)
	{
		static file[256], logs[32];
		get_localinfo("amxx_logs", logs, charsmax(logs));
		formatex(file, charsmax(file), "%s/DEBUG_cz_leader.txt", logs);
		
		hFile = fopen(file, "at+");
		bInitiated = true;
	}
	
	if (!hFile)
		return;
	
	static buffer[192];
	vformat(buffer, charsmax(buffer), szText, 2);
	
	fputs(hFile, szText);
}

stock bool:is_user_stucked(iPlayer)
{
	static Float:vecOrigin[3]
	pev(iPlayer, pev_origin, vecOrigin)
	
	static tr;
	if (!tr)
		tr = create_tr2();
	
	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, DONT_IGNORE_MONSTERS, (pev(iPlayer, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, iPlayer, tr);
	
	return !!(get_tr2(tr, TR_StartSolid) || get_tr2(tr, TR_AllSolid) || !get_tr2(tr, TR_InOpen));
}

stock bool:UTIL_CheckPassibility(const Float:vecOrigin[3])
{
	static tr;
	if (!tr)
		tr = create_tr2();
	
	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, DONT_IGNORE_MONSTERS, HULL_HEAD, 0, tr);
	
	return !!(get_tr2(tr, TR_StartSolid) || get_tr2(tr, TR_AllSolid) || !get_tr2(tr, TR_InOpen));
}





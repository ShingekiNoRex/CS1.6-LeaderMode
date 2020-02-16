/**

 - 金錢有限，以傷害為準	✔ (LUNA)
 - 死亡總次數有限，復活時間 = 隊長HP / 100 ✔ (LUNA)


策略：全體隊員投票決定隊伍策略。每次有且僅有一項策略生效。 ✔ (LUNA)
火力優勢學說：彈匣內子彈自動填充		✔
數量優勢學說：復活速度固定為最低值		✔
質量優勢學說：金錢緩慢補充、賞金增加	✔
機動作戰學說：隊員重生時部署於隊長附近	✔

CT:
指挥官	(1)
(標記黑手位置，10秒内自身射速加倍&受傷減半)
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
(周围友军瞬间恢复生命，10秒内自身受伤减半)
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
#define VERSION	"1.6.3"
#define AUTHOR	"ShingekiNoRex & Luna the Reborn"

#define HUD_SHOWMARK	1	//HUD提示消息通道
#define HUD_SHOWHUD		2	//HUD属性信息通道

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
	"觀察者",
	
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

new const g_rgszTacticalSchemeNames[SCHEMES_COUNT][] = { "舉棋不定", "火力優勢學說", "數量優勢學說", "質量優勢學說", "機動作戰學說" };
new const g_rgszTacticalSchemeDesc[SCHEMES_COUNT][] = { "未决定策略", "彈匣子彈自動填充", "快速復活", "金錢緩慢補充、賞金增加", "隊員部署於隊長附近、全图购买" };

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
new Float:g_flNewPlayerScan, bool:g_rgbResurrecting[33], Float:g_flStopResurrectingThink, TacticalScheme_e:g_rgTacticalSchemeVote[33], Float:g_flTeamTacticalSchemeThink, TacticalScheme_e:g_rgTeamTacticalScheme[4], Float:g_rgflTeamTSEffectThink[4], g_rgiBallotBox[4][SCHEMES_COUNT];
new Role_e:g_rgPlayerRole[33], bool:g_rgbUsingSkill[33], bool:g_rgbAllowSkill[33], Float:g_rgflSkillCountdown[33], Float:g_rgflSkillCooldown[33];
new cvar_SkillCountdown, cvar_SkillCooldown;
new cvar_WMDLkilltime, cvar_humanleader, cvar_menpower, cvar_TSDmoneyaddinv, cvar_TSDmoneyaddnum, cvar_TSDbountymul, cvar_TSDrefillinv, cvar_TSDrefillratio, cvar_TSDresurrect, cvar_TSVcooldown;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// Ham hooks
	RegisterHam(Ham_Killed, "player", "HamF_Killed");
	RegisterHam(Ham_Killed, "player", "HamF_Killed_Post", 1);
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
	cvar_SkillCountdown	= register_cvar("lm_skill_countdown",					"10.0");
	cvar_SkillCooldown	= register_cvar("lm_skill_cooldown",					"60.0");
	
	// client commands
	register_clcmd("vs", "Command_VoteTS");
	register_clcmd("votescheme", "Command_VoteTS");
	register_clcmd("say /votescheme", "Command_VoteTS");
	register_clcmd("say /vs", "Command_VoteTS");
	
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1);
}

public plugin_precache()
{
	register_forward(FM_Spawn, "fw_Spawn");
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
		print_chat_color(0, BLUECHAT, "恐怖分子首领已被击毙。(The leader of Terrorist has been killed.)");
	}
	else if (victim == g_iLeader[1])
	{
		print_chat_color(0, BLUECHAT, "反恐精英领袖已被击毙。(The leader of CT has been killed.)");
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

public HamF_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	if (!is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return;
	
	new iVictimTeam = get_pdata_int(iVictim, m_iTeam);
	new iAttackerTeam = get_pdata_int(iAttacker, m_iTeam);
	
	if (iVictimTeam != iAttackerTeam)
		UTIL_AddAccount(iAttacker, floatround(flDamage * (g_rgTeamTacticalScheme[iAttacker] == Doctrine_GrandBattleplan ? get_pcvar_float(cvar_TSDbountymul) : 1.0 )) );
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
		
		xs_vec_add(vecCandidates[0], Float:{0.0, 64.0, 0.0}, vecCandidates[0]);
		xs_vec_add(vecCandidates[1], Float:{64.0, 64.0, 0.0}, vecCandidates[1]);
		xs_vec_add(vecCandidates[2], Float:{64.0, 0.0, 0.0}, vecCandidates[2]);
		xs_vec_add(vecCandidates[3], Float:{64.0, -64.0, 0.0}, vecCandidates[3]);
		xs_vec_add(vecCandidates[4], Float:{0.0, -64.0, 0.0}, vecCandidates[4]);
		xs_vec_add(vecCandidates[5], Float:{-64.0, -64.0, 0.0}, vecCandidates[5]);
		xs_vec_add(vecCandidates[6], Float:{-64.0, 0.0, 0.0}, vecCandidates[6]);
		xs_vec_add(vecCandidates[7], Float:{-64.0, 64.0, 0.0}, vecCandidates[7]);
		
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
	
	if (g_flTeamTacticalSchemeThink <= fCurTime)	// Team Tactical Scheme Voting Think
	{
		g_flTeamTacticalSchemeThink = fCurTime + (g_bRoundStarted ? get_pcvar_float(cvar_TSVcooldown) : 0.1);
		
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
						UTIL_AddAccount(i, get_pcvar_num(cvar_TSDmoneyaddnum));
						
					case Doctrine_SuperiorFirepower:
					{
						new iEntity = get_pdata_cbase(i, m_pActiveItem);
						if (pev_valid(iEntity))
						{
							new iId = get_pdata_int(iEntity, m_iId, 4);
							if (iId != CSW_C4 && iId != CSW_HEGRENADE && iId != CSW_KNIFE && iId != CSW_SMOKEGRENADE && iId != CSW_FLASHBANG)	// these weapons are not allowed to have clip.
								set_pdata_int(iEntity, m_iClip, get_pdata_int(iEntity, m_iClip, 4) + floatround(float(g_rgiDefaultMaxClip[iId]) * get_pcvar_float(cvar_TSDrefillratio)), 4);
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
	
	new Float:fCurTime;
	global_get(glb_time, fCurTime);
	
	// HUD
	if (!is_user_bot(pPlayer))
	{
		new rgColor[3] = { 255, 255, 0 };
		new Float:flCoordinate[2] = { -1.0, 0.90 };
		new Float:rgflTime[4] = { 0.1, 0.1, 0.0, 0.0 };
		
		static szText[192];
		if (!is_user_alive(g_iLeader[iTeam - 1]) && g_iLeader[iTeam - 1] > 0)	// prevent this text appears in freezing phase.
			formatex(szText, charsmax(szText), "隊長已陣亡|兵源補給中斷|%s", g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[iTeam]]);
		else
			formatex(szText, charsmax(szText), "隊長:%s|兵源剩餘:%d|%s", g_szLeaderNetname[iTeam - 1], g_rgiTeamMenPower[iTeam], g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[iTeam]]);
		
		ShowHudMessage(pPlayer, rgColor, flCoordinate, 0, rgflTime, HUD_SHOWHUD, szText);
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
	
	if (g_rgbUsingSkill[pPlayer])
	{
		if (g_rgflSkillCountdown[pPlayer] <= fCurTime)
		{
			g_rgbUsingSkill[pPlayer] = false;
			g_rgflSkillCooldown[pPlayer] = fCurTime + get_pcvar_float(cvar_SkillCooldown);
		}
	}
	else if (!g_rgbAllowSkill[pPlayer])
	{
		if (g_rgflSkillCooldown[pPlayer] <= fCurTime)
		{
			g_rgbAllowSkill[pPlayer] = true;
			print_chat_color(iPlayer, GREENCHAT, "技能冷卻完毕！");
		}
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

	g_rgbUsingSkill[iPlayer] = true;
	g_rgbAllowSkill[iPlayer] = false;
	
	new Float:fCurTime;
	global_get(glb_time, fCurTime);
	
	g_rgflSkillCountdown[iPlayer] = fCurTime + get_pcvar_float(cvar_SkillCountdown);
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
	
	g_iLeader[0] = szPlayer[0][random_num(1, iAmount[0])]
	g_iLeader[1] = szPlayer[1][random_num(1, iAmount[1])]
	pev(g_iLeader[0], pev_netname, g_szLeaderNetname[0], charsmax(g_szLeaderNetname[]));
	pev(g_iLeader[1], pev_netname, g_szLeaderNetname[1], charsmax(g_szLeaderNetname[]));
	set_pev(g_iLeader[0], pev_health, 1000.0)
	set_pev(g_iLeader[1], pev_health, 1000.0)
	
	new rgColor[3] = { 255, 100, 255 };
	new Float:flCoordinate[2] = { -1.0, 0.30 };
	new Float:rgflTime[4] = { 6.0, 6.0, 0.1, 0.2 };
	
	ShowHudMessage(g_iLeader[0], rgColor, flCoordinate, 0, rgflTime, -1, "你已被選定為%s隊長!", g_rgszTeamName[TEAM_TERRORIST]);
	ShowHudMessage(g_iLeader[1], rgColor, flCoordinate, 0, rgflTime, -1, "你已被選定為%s隊長!", g_rgszTeamName[TEAM_CT]);
	
	g_bRoundStarted = true;

	for (new i = 1; i < global_get(glb_maxClients); i++)
	{
		if (!is_user_alive(i))
			continue
			
		if (is_user_bot(i))
			continue
			
		if (get_pdata_int(i, m_iTeam) == TEAM_TERRORIST)	// for TRs
		{
			print_chat_color(i, REDCHAT, "%s是反恐精英领袖，击杀他以阻止反恐精英重生。(%s is the leader of CT. Kill him to stop their respawn.)", g_szLeaderNetname[1], g_szLeaderNetname[1]);
		}
		else if (get_pdata_int(i, m_iTeam) == TEAM_CT)	// for CTs
		{
			print_chat_color(i, REDCHAT, "%s是恐怖分子首领，击杀他以阻止恐怖分子重生。(%s is the leader of Terrorist. Kill him to stop their respawn.)", g_szLeaderNetname[0], g_szLeaderNetname[0]);
		}
	}
	
	emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"));
	ewrite_byte(g_iLeader[0]);	// head of TRs
	ewrite_byte(SCOREATTRIB_BOMB);
	emessage_end();
	
	emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"));
	ewrite_byte(g_iLeader[1]);	// head of CTs
	ewrite_byte(SCOREATTRIB_VIP);
	emessage_end();
	
	new iPlayerAmount = 0;
	for (new i = 1; i < global_get(glb_maxClients); i ++)
		if (is_user_alive(i))
			iPlayerAmount ++;
	
	g_rgiTeamMenPower[TEAM_CT] = get_pcvar_num(cvar_menpower) * iPlayerAmount;
	g_rgiTeamMenPower[TEAM_TERRORIST] = get_pcvar_num(cvar_menpower) * iPlayerAmount;
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
		formatex(szItem[i], charsmax(szItem[]), "\w%s - %s (\y%d\w人支持)", g_rgszTacticalSchemeNames[i], g_rgszTacticalSchemeDesc[i], g_rgiBallotBox[iTeam][i]);
	
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
		g_rgTacticalSchemeVote[pPlayer] = TacticalScheme_e:iItem;
	
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





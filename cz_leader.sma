/**

 - 金錢有限，以傷害為準
 - 死亡總次數有限，復活時間 = 隊長HP / 100
 - 


策略：
火力優勢學說：彈匣內子彈自動填充
數量優勢學說：復活速度固定4秒
質量優勢學說：金錢自動增加

CT:
突擊隊長	(1)
(輕機槍，標記黑手位置，射速加倍&受傷減半)
(被動：HP 1000)
重裝步兵
(步槍，立即填充所有手榴彈，轉移90%傷害至護甲)
(被動：AP 200)
霰彈槍手
(霰彈槍，一擊必殺200英尺內所有普通敵人，霰彈改為寒冰彈藥)
(被動：
狙擊手
(狙擊槍，強制命中頭部3秒，命中的目標致盲3秒)
(被動：狙擊槍散射和後座力減半)
軍醫
(衝鋒槍，犧牲50%HP將周圍非隊長角色的HP恢復最大值的一半，手榴彈及煙霧彈改為治療效果)
(被動：移動速度+25%)

TR:
黑手(隊長)	(1)
(手槍，將HP均分至周圍角色10秒，手槍改為燃燒彈藥)
(被動：HP 1000)
暴徒
(步槍，將步槍轉換為霰彈槍5秒，手榴彈改為燃燒，煙霧彈改為毒霧)
(被動：擊殺賞金均全額賦予)
技師
(衝鋒槍，衝鋒槍改為電擊彈藥，將瞄準目標吸往自己的方向)
(被動：遭受的AP傷害以電擊雙倍返還)
幽靈
(消音武器，標記突擊隊長位置，隱身10秒)
(被動：消音武器有1%的概率暴擊)
逃犯
(輕機槍/部分步槍/霰彈槍，將損失的HP的35%轉換為傷害，主動絕唱6秒立刻死亡)
(被動：裝備價格折扣35%)

**/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>

#define PLUGIN	"CZ Leader"
#define VERSION	"1.5"
#define AUTHOR	"ShingekiNoRex & Hydrogen"

#define HUD_SHOWMARK	1	//HUD提示消息通道
#define HUD_SHOWHUD		2	//HUD属性信息通道

#define REDCHAT		1
#define BLUECHAT	2
#define GREYCHAT	3
#define NORMALCHAT  4
#define GREENCHAT   5

#define SCOREATTRIB_DEAD	(1<<0)
#define SCOREATTRIB_BOMB	(1<<1)
#define SCOREATTRIB_VIP		(1<<2)

#define TEAM_UNASSIGNED		0
#define TEAM_TERRORIST		1
#define TEAM_CT				2
#define TEAM_SPECTATOR		3

new const teamname[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR"}

//地图实体
new const g_objective_ents[][] =
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
new g_iLeader[2], g_iHumanResource[2], bool:g_bRoundStarted = false, g_szLeaderNetname[2][64];
new Float:g_flNewPlayerScan, bool:g_rgbResurrecting[33];
new cvar_WMDLkilltime, cvar_humanleader, cvar_humanresource;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Ham hooks
	RegisterHam(Ham_Killed, "player", "HamF_Killed_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage_Post", 1);
	
	// FM hooks
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_StartFrame, "fw_StartFrame_Post", 1);
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink_Post", 1);
	
	// events
	register_logevent("Event_FreezePhaseEnd", 2, "1=Round_Start")
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	
	// messages
	register_message(get_user_msgid("Health"), "Message_Health");
	
	// CVars
	cvar_WMDLkilltime	= register_cvar("lm_dropped_wpn_remove_time",			"60.0");
	cvar_humanleader	= register_cvar("lm_human_player_leadership_priority",	"1");
	cvar_humanresource	= register_cvar("lm_human_resource_multi",				"10");
	
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1)
}

public plugin_precache()
{
	register_forward(FM_Spawn, "fw_Spawn")
}

public client_putinserver(pPlayer)
{
	g_rgbResurrecting[pPlayer] = false;
}

public HamF_Killed_Post(victim, attacker, shouldgib)
{
	if (victim == g_iLeader[0])
	{
		print_chat_color(0, BLUECHAT, "恐怖分子首领已被击毙。(The leader of Terrorist has been killed.)")
		
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (!is_user_connected(i))
				continue;
			
			if (is_user_bot(i))
				continue;
			
			if (get_pdata_int(i, m_iTeam) == TEAM_TERRORIST)
				UTIL_BarTime(i, 0);	// hide the bartime.
		}
		
		g_bRoundStarted = false;
	}
	
	if (victim == g_iLeader[1])
	{
		print_chat_color(0, BLUECHAT, "反恐精英领袖已被击毙。(The leader of CT has been killed.)")
		
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (!is_user_connected(i))
				continue;
			
			if (is_user_bot(i))
				continue;
			
			if (get_pdata_int(i, m_iTeam) == TEAM_CT)
				UTIL_BarTime(i, 0);	// hide the bartime.
		}
		
		g_bRoundStarted = false;
	}

	if (!is_user_connected(victim))
		return;

	new iTeam = get_pdata_int(victim, m_iTeam);
	
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return;
	
	if (!is_user_alive(g_iLeader[0]) && iTeam == TEAM_TERRORIST)
		return;
	
	if (!is_user_alive(g_iLeader[1]) && iTeam == TEAM_CT)
		return;
	
	new Float:flHealth;
	pev(g_iLeader[iTeam - 1], pev_health, flHealth);
	
	new iResurrectionTime = max(floatround(flHealth / 1000.0 * 10.0), 1);
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
		UTIL_AddAccount(iAttacker, floatround(flDamage));
	else
		UTIL_AddAccount(iAttacker, -floatround(flDamage));
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
			set_task(float(iResurrectionTime), "Task_PlayerResurrection", i);
			UTIL_BarTime(i, iResurrectionTime);
			g_rgbResurrecting[i] = true;
		}
		
		g_flNewPlayerScan = fCurTime + random_float(3.0, 5.0);
	}
}

public fw_PlayerPostThink_Post(pPlayer)
{
	if (!is_user_connected(pPlayer) || is_user_bot(pPlayer))
		return;
	
	new iTeam = get_pdata_int(pPlayer, m_iTeam);
	
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return;
	
	new rgColor[3] = { 255, 255, 0 };
	new Float:flCoordinate[2] = { -1.0, 0.90 };
	new Float:rgflTime[4] = { 0.1, 0.1, 0.0, 0.0 };
	
	ShowHudMessage(pPlayer, rgColor, flCoordinate, 0, rgflTime, HUD_SHOWHUD, "隊長:%s|人力剩餘:%d", g_szLeaderNetname[iTeam - 1], g_iHumanResource[iTeam - 1]);
}

public fw_Spawn(iEntity)	//移除任务实体
{
	if (!pev_valid(iEntity))
		return FMRES_IGNORED
	
	static classname[32]
	pev(iEntity, pev_classname, classname, charsmax(classname))
	
	for (new i = 0; i < sizeof g_objective_ents; i ++)
	{
		if (equal(classname, g_objective_ents[i]))
		{
			engfunc(EngFunc_RemoveEntity, iEntity)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public Task_PlayerResurrection(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return;
	
	if (is_user_alive(iPlayer))
		return;
	
	new iTeam = get_pdata_int(iPlayer, m_iTeam);
	
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)	// this is a spector
		return;
	
	if (!is_user_alive(g_iLeader[0]) && iTeam == TEAM_TERRORIST)
		return;
	
	if (!is_user_alive(g_iLeader[1]) && iTeam == TEAM_CT)
		return;
	
	if (g_iHumanResource[iTeam - 1] <= 0)
		return;
	
	ExecuteHamB(Ham_CS_RoundRespawn, iPlayer);
	g_rgbResurrecting[iPlayer] = false;
	g_iHumanResource[iTeam - 1] --;
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
		
		//fm_set_user_money(i, 16000)
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
	
	g_bRoundStarted = true;

	for (new i = 1; i < 33; i++)
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
	for (new i = 1; i < 33; i ++)
		if (is_user_alive(i))
			iPlayerAmount ++;

	g_iHumanResource[0] = get_pcvar_num(cvar_humanresource) * iPlayerAmount;
	g_iHumanResource[1] = get_pcvar_num(cvar_humanresource) * iPlayerAmount;
}

public Event_HLTV()
{
	g_iLeader[0] = -1;
	g_iLeader[1] = -1;
	
	formatex(g_szLeaderNetname[0], charsmax(g_szLeaderNetname[]), "未揭示");
	formatex(g_szLeaderNetname[1], charsmax(g_szLeaderNetname[]), "未揭示");
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

public fw_BotForwardRegister_Post(iPlayer)
{
	if (is_user_bot(iPlayer))
	{
		unregister_forward(FM_PlayerPostThink, g_fwBotForwardRegister, 1)
		RegisterHamFromEntity(Ham_Killed, iPlayer, "HamF_Killed_Post", 1)
		RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "HamF_TakeDamage_Post", 1);
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
		write_string(teamname[Color])
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
		write_string(teamname[get_pdata_int(Client, m_iTeam, 5)])
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
	if (!is_user_connected(pPlayer))
		return;

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

stock DEBUG_LOG(const szText[], any:...)
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
	
	fprintf(hFile, szText);
}

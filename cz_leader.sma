#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "CZ Leader"
#define VERSION "1.0"
#define AUTHOR "REX"

#define REDCHAT     1
#define BLUECHAT    2
#define GREYCHAT    3
#define NORMALCHAT  4
#define GREENCHAT   5

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
new g_iLeader[2]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	RegisterHam(Ham_Killed, "player", "HAM_PlayerKilled_Post", 1)
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_event("ShowMenu","TeamSelect","b","4&Team_Select")
	register_event("VGUIMenu","TeamSelect","b","1=2")
	register_logevent("roundbegin_logevent", 2, "1=Round_Start")
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1)
}

public plugin_precache()
{
    register_forward(FM_Spawn, "fw_Spawn")
}

public fw_BotForwardRegister_Post(iPlayer)
{
    if(is_user_bot(iPlayer))
    {
        unregister_forward(FM_PlayerPostThink, g_fwBotForwardRegister, 1)
        RegisterHamFromEntity(Ham_Killed, iPlayer, "HAM_PlayerKilled_Post")
    }
}

public HAM_PlayerKilled_Post(victim, attacker, shouldgib)
{
	if (victim == g_iLeader[0]) print_chat_color(0, BLUECHAT, "恐怖分子首领已被击毙。(The leader of Terrorist has been killed.)")
	if (victim == g_iLeader[1]) print_chat_color(0, BLUECHAT, "反恐精英领袖已被击毙。(The leader of CT has been killed.)")

	if (!is_user_alive(g_iLeader[0]) && get_pdata_int(victim, 114) == 1)
		return
		
	if (!is_user_alive(g_iLeader[1]) && get_pdata_int(victim, 114) == 2)
		return
		
	set_task(1.5, "respawn", victim)
}

public TeamSelect(iPlayer) set_task(5.0, "respawn", iPlayer)

//移除任务实体 & 修改出生点
public fw_Spawn(iEntity)
{
    if(!pev_valid(iEntity))
    return FMRES_IGNORED
    
    static classname[32]
    pev(iEntity, pev_classname, classname, sizeof classname - 1)
    
    for(new i = 0; i < sizeof g_objective_ents; i ++)
    {
        if(equal(classname, g_objective_ents[i]))
        {
            engfunc(EngFunc_RemoveEntity, iEntity)
            return FMRES_SUPERCEDE
        }
    }
    return FMRES_IGNORED
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

public respawn(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return
	
	if (is_user_alive(iPlayer))
		return 
    
	if (!is_user_alive(g_iLeader[0]) && get_pdata_int(iPlayer, 114) == 1)
		return
		
	if (!is_user_alive(g_iLeader[1]) && get_pdata_int(iPlayer, 114) == 2)
		return
		
	ExecuteHam(Ham_CS_RoundRespawn, iPlayer)
	fm_set_user_money(iPlayer, 16000)
}

public roundbegin_logevent()
{
	g_iLeader[0] = 0
	g_iLeader[1] = 0
	new szPlayer[2][33], iAmount[2]
	for (new i = 1; i < 33; i++)
	{
		if (!is_user_alive(i))
			continue
		
		if (get_pdata_int(i, 114) == 1)
		{
			iAmount[0] ++
			szPlayer[0][iAmount[0]] = i
		}
		else if (get_pdata_int(i, 114) == 2)
		{
			iAmount[1] ++
			szPlayer[1][iAmount[1]] = i
		}
		fm_set_user_money(i, 16000)
	}
	
	if (!iAmount[0] || !iAmount[1])
		return
	
	new szName[64], szName2[64]
	g_iLeader[0] = szPlayer[0][random_num(1, iAmount[0])]
	g_iLeader[1] = szPlayer[1][random_num(1, iAmount[1])]
	pev(g_iLeader[0], pev_netname, szName, charsmax(szName))
	pev(g_iLeader[1], pev_netname, szName2, charsmax(szName2))
	set_pev(g_iLeader[0], pev_health, 1000.0)
	set_pev(g_iLeader[1], pev_health, 1000.0)

	for (new i = 1; i < 33; i++)
	{
		if (!is_user_alive(i))
			continue
			
		if (is_user_bot(i))
			continue
			
		if (get_pdata_int(i, 114) == 1)
		{
			print_chat_color(i, REDCHAT, "%s是反恐精英领袖，击杀他以阻止反恐精英重生。(%s is the leader of CT. Kill him to stop their respawn.)", szName2, szName2)
		}
		else if (get_pdata_int(i, 114) == 2)
		{
			print_chat_color(i, REDCHAT, "%s是恐怖分子首领，击杀他以阻止恐怖分子重生。(%s is the leader of Terrorist. Kill him to stop their respawn.)", szName, szName)
		}
	}
}

stock print_chat_color(const iPlayer, const Color, const Message[], any:...)
{
    static buffer[192]
    if(1 <= Color <= 3) buffer[0] = 0x03
    else if(Color == 4) buffer[0] = 0x01
    else if(Color == 5) buffer[0] = 0x04
    vformat(buffer[1], charsmax(buffer), Message, 4)
    ShowChat(iPlayer, Color, buffer)
}

stock ShowChat(const iPlayer, const Color, const Message[])
{
    new Client
    
    if(!iPlayer)
    {
        for(Client = 1; Client < 33; Client ++)
        {
            if(!is_user_connected(Client))
            continue
    
            break
        }
    }
    
    Client = max(Client, iPlayer)
    
    if(1 <= Color <= 3)
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
    
    if(1 <= Color <= 3)
    {
        message_begin(iPlayer ? MSG_ONE : MSG_BROADCAST, get_user_msgid("TeamInfo"), _, Client)
        write_byte(Client)
        write_string(teamname[get_pdata_int(Client, 114, 5)])
        message_end()
    }
}

stock fm_set_user_money(index, money)
{
    set_pdata_int(index, 115, money);
    
    message_begin(MSG_ONE, get_user_msgid("Money"), {0,0,0}, index);
    write_long(money);
    write_byte(1);
    message_end();
}
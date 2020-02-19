/**

 - 金錢有限，以傷害為準	✔ (LUNA)
 - 死亡總次數有限，復活時間 = 隊長HP / 100 ✔ (LUNA)
 - 不信任動議投票 (罷免指揮官)
 - 選舉(指揮官任命?)職業，職業人數限制
 - 購買手槍默認全員允許


策略：全體隊員投票決定隊伍策略。每次有且僅有一項策略生效。策略每20秒得以更換。 ✔ (LUNA)
火力優勢學說：	✔
	彈匣內每秒填充4%的彈藥。
數量優勢學說：	✔
	復活速度固定為1秒。
	兵源消耗減半。
質量優勢學說：	✔
	每5秒獲得50金錢。
	造成傷害及擊殺賞金翻倍。
	初始裝備包含護甲和各類手榴彈。
機動作戰學說：	✔
	增援會部署於隊長附近。
	可以於任意地點購買裝備。


叮噹貓：什麼都可以買。

CT:
指挥官	(1)
(半自動狙擊槍與輕機槍帶有懲罰，允許其餘武器)
(標記黑手位置，自身射速加倍&受傷減半)	✔ (LUNA)
(被動：HP 1000，可以发动空袭) (UNDONE: 空袭)
S.W.A.T.
(優惠霰彈槍、衝鋒槍、煙霧彈和閃光彈，允許突擊步槍)
(立即填充所有手榴彈、彈藥和護甲，10秒内轉移90%傷害至護甲)
(被動：AP 200，周围友军缓慢恢复护甲)
爆破手
(優惠投擲物、霰彈槍、MP7、PM9，允許衝鋒槍)
(10秒内无限高爆手雷，爆炸伤害+50%)	✔ (REX)
(被動：死后爆炸) ✔ (REX)
神射手
(優惠M200、手榴彈和ANACONDA，允許AWP、半自動狙擊槍、煙霧彈和閃光彈，突擊步槍帶有懲罰)
(10秒内强制爆头，命中的目標致盲3秒)	✔ (LUNA)
(被動：冰凍手榴彈) ✔ (REX)
医疗兵
(優惠G18C、ANACONDA、衝鋒槍和煙霧彈，允許霰彈槍、CM901和QBZ95)
(犧牲50%HP將周圍非隊長角色的HP恢復最大值的一半)
(被動：煙霧彈具有治療效果)

TR:
教父	(1)
(優惠手槍，半自動狙擊槍與輕機槍帶有懲罰，允許其餘武器)
(將自身HP均分至周圍角色，结束後收回。自身受伤减半) ✔ (LUNA)
(被動：HP 1000，周围友军缓慢恢复生命) ✔ (REX)
狂战士
(優惠輕機槍、自動步槍、衝鋒槍、霰彈槍)
(5秒内最低维持1血，5秒后若血量不超过1则死亡)	✔ (REX)
(被動：血量越低枪械伤害越高)	(UNDONE)
疯狂科学家
(優惠G18C、ANACONDA和煙霧彈，允許KSG、PM9和MP7)
(遭受的傷害(HP+AP)以電擊形式返還，將瞄準目標吸往自己的方向)
(被動：煙霧彈更換為毒氣彈、30%概率發射電擊彈藥(減速，扳機和視角不受控制))
暗杀者
(優惠USP、MP7、M200，允許衝鋒槍、煙霧彈和閃光彈，M14EBR帶有懲罰)
(消音武器，標記敌方指挥官位置，隱身10秒) ✔ (LUNA)
(被動：消音武器有1%的概率暴擊) ✔ (LUNA)
纵火犯
(優惠霰彈槍和手榴彈，允許衝鋒槍、突擊步槍)
(火焰弹药，燃烧伤害附带减速效果)
(被動：高爆手雷改为燃烧瓶)

**/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>
#include <xs>
#include <orpheu>
#include <celltrie>

#define PLUGIN	"CZ Leader"
#define VERSION	"1.11.1"
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

#define DISCARD	2
#define TRUST	1
#define DEPRIVE	0

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
#define CSW_RADIO		2

#define WPN_P	-1	// penalty: price * 2
#define WPN_F	0	// forbidden: price * 99999
#define WPN_A	1	// allowed: price * 1
#define WPN_D	2	// discounted: price * 0.5

// airsupport
//#define AIR_SUPPORT_ENABLE
#if defined AIR_SUPPORT_ENABLE
#define ANIM_RADIO_DRAW		1
#define ANIM_RADIO_USE		3
#define ANIMTIME_RADIO_DRAW	1.033
#define ANIMTIME_RADIO_USE	2.756
#endif

enum TacticalScheme_e
{
	Scheme_UNASSIGNED = 0,	// disputation
	Doctrine_SuperiorFirepower,
	Doctrine_MassAssault,
	Doctrine_GrandBattleplan,
	Doctrine_MobileWarfare,
	
	SCHEMES_COUNT
};

new const g_rgszTacticalSchemeNames[SCHEMES_COUNT][] =
{
	"舉棋不定",
	"火力優勢學說",
	"數量優勢學說",
	"質量優勢學說",
	"機動作戰學說"
};

new const g_rgszTacticalSchemeDesc[SCHEMES_COUNT][] =
{
	"/y如果多數人/g舉棋不定/y，又或者隊伍內/t存在爭議/y: 則全隊/t不會獲得/y任何加成。",
	"/g火力優勢學說/y: /t每秒/y都會填充當前武器/t最大/y彈容量的/g4%%%%",
	"/g數量優勢學說/y: 隊伍/t復活速度/y達到/g極限/y，並且擁有/g雙倍/y人力資源。",
	"/g質量優勢學說/y: 緩慢/g補充金錢/y、增加/t造成傷害/y及/t擊殺/y的/g賞金/y以及為/t增援兵源/y購置/g基礎裝備/y。",
	"/g機動作戰學說/y: 增援隊員/g部署/y於/t隊長/y附近，並允許在/g任何位置/y購買裝備。"
};

new const g_rgiTacticalSchemeDescColor[SCHEMES_COUNT] = { GREYCHAT, REDCHAT, BLUECHAT, BLUECHAT, REDCHAT };

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
	"[T]无限手榴彈，爆炸伤害+50%%%%",
	"[T]狙擊槍強制命中頭部，並造成目標失明",
	"",
	
	"[T]均分HP至周圍角色，结束后收回。自身受傷減半",
	"[T]提升移速，承受致命伤不会立刻死亡",
	"",
	"[T]標記指揮官位置並隱身",
	""
};

stock const g_rgszRolePassiveSkills[ROLE_COUNT][] =
{
	"",
	
	"",
	"",
	"[被动]减少受到的爆炸伤害，死后爆炸",
	"[被动]冰冻手雷",
	"",
	
	"[被动]周围友军缓慢恢复生命",
	"[被动]血量越低伤害越高",
	"",
	"[被动]消音武器有1%%%%的概率暴擊",
	""
};

stock g_rgSkillDuration[ROLE_COUNT] =
{
	-1,
	
	-1,
	-1,
	-1,
	-1,
	-1,
	
	-1,
	-1,
	-1,
	-1,
	-1
};

stock g_rgSkillCooldown[ROLE_COUNT] =
{
	-1,
	
	-1,
	-1,
	-1,
	-1,
	-1,
	
	-1,
	-1,
	-1,
	-1,
	-1
};

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

stock const g_rgszWeaponName[][] =
{
	"",
	"Colt Anaconda",
	"",
	"CheyTac Intervention M200",
	"手榴彈",
	"Armsel Striker",
	"定時炸彈",
	"Minebea PM-9",
	"Remington ACR",
	"煙霧彈",
	"雙持Walther P99",
	"FiveseveN",
	"H&K UMP45",
	"Mk.14 EBR",
	"Colt CM901",
	"Norinco QBZ95",
	"H&K USP.45",
	"Glock 18C",
	"A.I. Arctic Warfare",
	"H&K MP5",
	"Mk.46 Mod.0",
	"Kel-Tec KSG-12",
	"Colt M4A1",
	"H&K MP7A1",
	"Dragunov SVD",
	"閃光彈",
	"IMI Desert Eagle",
	"FN SCAR-L",
	"Автомат Калашникова",
	"匕首",
	"FN P90"
};

//												5			   10			  15			 20				25			   30	// if this isn't lined up, please use Notepad++
stock const g_rgiClipRegen[] = { 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 4, 0, 1, 2, 0, 0, 0, 1, 1, 0, 2 };

stock const g_rgiWeaponDefaultCost[] = { -1, 600, -1, 2750, 300, 3000, 0, 1400, 3500, 300, 800, 750, 1700, 4200, 2000, 2250, 500, 400, 4750, 1500, 5750, 1700, 3100, 1250, 5000, 200, 650, 3500, 2500, 0, 2350 };
stock const g_rgiWeaponDefaultSlot[] = { -1, 1, -1, 0, 3, 0, 4, 0, 0, 3, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 3, 1, 0, 0, 2, 0 };
stock const g_rgRoleWeaponsAccessibility[ROLE_COUNT][CSW_P90 + 1] =
{
//					      0                                  5                                  10                                 15                                 20                                 25                                 30
//					      NONE   ANACO  UNUSED M200   HE     M1014  C4     PM9    ACR    S_GR   P99    FN57   UMP45  M14    CM901  QBZ95  USP    G18C   AWP    MP5    MK46   KSG    M4A1   MP7A1  SVD    FBang  DEAGLE SG552  AK74   KNIFE  P90
/*Role_UNASSIGNED*/		{ WPN_F, WPN_A, WPN_F, WPN_A, WPN_A, WPN_A, WPN_F, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_F, WPN_A },

/*Role_Commander = 1*/	{ WPN_F, WPN_A, WPN_F, WPN_A, WPN_A, WPN_A, WPN_F, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_P, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_A, WPN_P, WPN_A, WPN_A, WPN_A, WPN_P, WPN_A, WPN_A, WPN_A, WPN_A, WPN_F, WPN_A },
/*Role_SWAT*/			{ WPN_F, WPN_A, WPN_F, WPN_F, WPN_F, WPN_D, WPN_F, WPN_D, WPN_A, WPN_D, WPN_A, WPN_A, WPN_D, WPN_F, WPN_A, WPN_A, WPN_A, WPN_A, WPN_F, WPN_D, WPN_F, WPN_D, WPN_A, WPN_D, WPN_F, WPN_D, WPN_A, WPN_A, WPN_A, WPN_F, WPN_D },
/*Role_Blaster*/		{ WPN_F, WPN_A, WPN_F, WPN_F, WPN_D, WPN_D, WPN_F, WPN_D, WPN_F, WPN_D, WPN_A, WPN_A, WPN_A, WPN_F, WPN_F, WPN_F, WPN_A, WPN_A, WPN_F, WPN_A, WPN_F, WPN_D, WPN_F, WPN_D, WPN_F, WPN_D, WPN_A, WPN_F, WPN_F, WPN_F, WPN_A },
/*Role_Sharpshooter*/	{ WPN_F, WPN_D, WPN_F, WPN_D, WPN_D, WPN_F, WPN_F, WPN_F, WPN_P, WPN_A, WPN_A, WPN_A, WPN_F, WPN_A, WPN_P, WPN_P, WPN_A, WPN_A, WPN_A, WPN_F, WPN_F, WPN_F, WPN_P, WPN_F, WPN_A, WPN_A, WPN_A, WPN_P, WPN_P, WPN_F, WPN_F },
/*Role_Medic = 5*/		{ WPN_F, WPN_D, WPN_F, WPN_F, WPN_F, WPN_A, WPN_F, WPN_D, WPN_F, WPN_D, WPN_A, WPN_A, WPN_D, WPN_F, WPN_A, WPN_A, WPN_A, WPN_D, WPN_F, WPN_D, WPN_F, WPN_A, WPN_F, WPN_D, WPN_F, WPN_F, WPN_A, WPN_F, WPN_F, WPN_F, WPN_D },

/*Role_Godfather = 6*/	{ WPN_F, WPN_D, WPN_F, WPN_A, WPN_A, WPN_A, WPN_F, WPN_A, WPN_A, WPN_A, WPN_D, WPN_D, WPN_A, WPN_P, WPN_A, WPN_A, WPN_D, WPN_D, WPN_A, WPN_A, WPN_P, WPN_A, WPN_A, WPN_A, WPN_P, WPN_A, WPN_D, WPN_A, WPN_A, WPN_F, WPN_A },
/*Role_Berserker*/		{ WPN_F, WPN_A, WPN_F, WPN_F, WPN_F, WPN_D, WPN_F, WPN_D, WPN_D, WPN_F, WPN_A, WPN_A, WPN_D, WPN_F, WPN_D, WPN_D, WPN_A, WPN_A, WPN_F, WPN_D, WPN_D, WPN_D, WPN_D, WPN_D, WPN_F, WPN_F, WPN_A, WPN_D, WPN_D, WPN_F, WPN_D },
/*Role_MadScientist*/	{ WPN_F, WPN_D, WPN_F, WPN_F, WPN_F, WPN_F, WPN_F, WPN_A, WPN_F, WPN_D, WPN_A, WPN_A, WPN_F, WPN_F, WPN_F, WPN_F, WPN_A, WPN_D, WPN_F, WPN_F, WPN_F, WPN_A, WPN_F, WPN_A, WPN_F, WPN_F, WPN_A, WPN_F, WPN_F, WPN_F, WPN_F },
/*Role_Assassin*/		{ WPN_F, WPN_A, WPN_F, WPN_D, WPN_F, WPN_F, WPN_F, WPN_A, WPN_F, WPN_A, WPN_A, WPN_A, WPN_A, WPN_P, WPN_F, WPN_F, WPN_D, WPN_A, WPN_F, WPN_A, WPN_F, WPN_F, WPN_F, WPN_D, WPN_F, WPN_A, WPN_A, WPN_F, WPN_F, WPN_F, WPN_A },
/*Role_Arsonist = 10*/	{ WPN_F, WPN_A, WPN_F, WPN_F, WPN_D, WPN_D, WPN_F, WPN_A, WPN_A, WPN_F, WPN_A, WPN_A, WPN_A, WPN_F, WPN_A, WPN_A, WPN_A, WPN_A, WPN_F, WPN_A, WPN_F, WPN_D, WPN_A, WPN_A, WPN_F, WPN_F, WPN_A, WPN_A, WPN_A, WPN_F, WPN_A }
};

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

stock const g_rgszCnfdnceMtnText[][] = { "罷免", "信任", "棄權" };

new g_fwBotForwardRegister;
new g_iLeader[2], bool:g_bRoundStarted = false, g_szLeaderNetname[2][64], g_rgiTeamMenPower[4];
new Float:g_rgflHUDThink[33], g_rgszLastHUDText[33][2][192];
new Float:g_flNewPlayerScan, bool:g_rgbResurrecting[33], Float:g_flStopResurrectingThink;
new TacticalScheme_e:g_rgTacticalSchemeVote[33], Float:g_flTeamTacticalSchemeThink, TacticalScheme_e:g_rgTeamTacticalScheme[4], Float:g_rgflTeamTSEffectThink[4], g_rgiTeamSchemeBallotBox[4][SCHEMES_COUNT], Float:g_flOpeningBallotBoxes, Float:g_flNextMWDThink;
new Role_e:g_rgPlayerRole[33], bool:g_rgbUsingSkill[33], bool:g_rgbAllowSkill[33], Float:g_rgflSkillCooldown[33], Float:g_rgflSkillExecutedTime[33];
new g_rgiTeamCnfdnceMtnLeft[4], Float:g_rgflTeamCnfdnceMtnTimeLimit[4], g_rgiTeamCnfdnceMtnBallotBox[4][2], g_rgiConfidenceMotionVotes[33];
new cvar_WMDLkilltime, cvar_humanleader, cvar_menpower;
new cvar_TSDmoneyaddinv, cvar_TSDmoneyaddnum, cvar_TSDbountymul, cvar_TSDrefillinv, cvar_TSDmenpowermul, cvar_TSDresurrect, cvar_TSVcooldown;
new cvar_VONCperTeam, cvar_VONCtimeLimit;
new cvar_DebugMode, cvar_restartSV;
new OrpheuFunction:g_pfn_RadiusFlash, OrpheuFunction:g_pfn_CBasePlayer_ResetMaxSpeed;
new g_ptrBeamSprite;

#if defined AIR_SUPPORT_ENABLE
new g_strRadioViewModel, g_strRadioPersonalModel;
#endif

// SFX
#define SFX_GAME_START_1		"leadermode/start_game_01.wav"
#define SFX_GAME_START_2		"leadermode/start_game_02.wav"
#define SFX_MENPOWER_DEPLETED	"leadermode/unable_manpower_alert.wav"
#define SFX_TSD_GBD				"leadermode/money_in.wav"
#define SFX_TSD_SFD				"leadermode/infantry_rifle_cartridge_0%d.wav"
#define SFX_GAME_WON			"leadermode/brittania_mission_arrived.wav"
#define SFX_GAME_LOST			"leadermode/end_turn_brittania_04.wav"
#define MUSIC_GAME_WON			"sound/leadermode/Tally-ho.mp3"
#define MUSIC_GAME_LOST			"sound/leadermode/Warrior_s_Tomb.mp3"
#define SFX_VONC_PASSED			"leadermode/complete_focus_01.wav"
#define SFX_VONC_REJECTED		"leadermode/peaceconference01.wav"
#define SFX_RADAR_BEEP			"leadermode/nes_8bit_alien3_radar_beep1.wav"
#if defined AIR_SUPPORT_ENABLE
#define SFX_RADIO_DRAW			"weapons/radio_draw.wav"
#define SFX_RADIO_USE			"weapons/radio_use.wav"
#endif

// Models
#if defined AIR_SUPPORT_ENABLE
#define MDL_RADIO_V				"models/v_radio.mdl"
#define MDL_RADIO_P				"models/p_radio.mdl"
#endif

// DIVIDE ET IMPERA
#include "godfather.sma"
#include "commander.sma"
#include "berserker.sma"
#include "assassin.sma"
#include "blaster.sma"
#include "sharpshooter.sma"
#if defined AIR_SUPPORT_ENABLE
#include "commander_airsupport.sma"
#endif

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// Ham hooks
	RegisterHam(Ham_Killed, "player", "HamF_Killed");
	RegisterHam(Ham_Killed, "player", "HamF_Killed_Post", 1);
	RegisterHam(Ham_TraceAttack, "player", "HamF_TraceAttack");
	RegisterHam(Ham_TraceAttack, "player", "HamF_TraceAttack_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage_Post", 1);
	RegisterHam(Ham_CS_RoundRespawn, "player", "HamF_CS_RoundRespawn_Post", 1);
	RegisterHam(Ham_BloodColor, "player", "HamF_BloodColor");
	RegisterHam(Ham_Touch, "weaponbox", "HamF_Weaponbox_Touch");
	
	for (new i = 0; i < sizeof g_rgszWeaponEntity; i++)
	{
		if (!g_rgszWeaponEntity[i][0])
			continue;

		if (i == CSW_C4 || i == CSW_HEGRENADE || i == CSW_KNIFE || i == CSW_SMOKEGRENADE || i == CSW_FLASHBANG)
			continue;

		RegisterHam(Ham_Weapon_PrimaryAttack, g_rgszWeaponEntity[i], "HamF_Weapon_PrimaryAttack_Post", 1);
	}
	
	RegisterHam(Ham_Weapon_WeaponIdle, g_rgszWeaponEntity[CSW_HEGRENADE], "HamF_Weapon_WeaponIdle");
	RegisterHam(Ham_Weapon_WeaponIdle, g_rgszWeaponEntity[CSW_FLASHBANG], "HamF_Weapon_WeaponIdle");
	RegisterHam(Ham_Weapon_WeaponIdle, g_rgszWeaponEntity[CSW_SMOKEGRENADE], "HamF_Weapon_WeaponIdle");

	// FM hooks
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_forward(FM_Touch, "fw_Touch_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_StartFrame, "fw_StartFrame_Post", 1);
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink_Post", 1)
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_ClientCommand, "fw_ClientCommand");
	
	// events
	register_logevent("Event_FreezePhaseEnd", 2, "1=Round_Start")
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	
	// messages
	register_message(get_user_msgid("Health"),		"Message_Health");
	register_message(get_user_msgid("ScreenFade"),	"Message_ScreenFade");
	register_message(get_user_msgid("StatusValue"),	"Message_StatusValue");
	register_message(get_user_msgid("StatusText"),	"Message_StatusText");
	
	// CVars
	cvar_restartSV		= get_cvar_pointer("sv_restart");
	cvar_DebugMode 		= register_cvar("lm_debug", 							"0");
	cvar_WMDLkilltime	= register_cvar("lm_dropped_wpn_remove_time",			"120.0");
	cvar_humanleader	= register_cvar("lm_human_player_leadership_priority",	"1");
	cvar_menpower		= register_cvar("lm_starting_menpower_per_player",		"5");
	cvar_TSVcooldown	= register_cvar("lm_TS_voting_cooldown",				"20.0");
	cvar_TSDrefillinv	= register_cvar("lm_TSD_SFD_clip_refill_interval",		"1.0");
	cvar_TSDresurrect	= register_cvar("lm_TSD_MAD_resurrection_time",			"1.0");
	cvar_TSDmenpowermul	= register_cvar("lm_TSD_MAD_menpower_multiplier",		"2.0");
	cvar_TSDmoneyaddinv	= register_cvar("lm_TSD_GBD_account_refill_interval",	"5.0");
	cvar_TSDmoneyaddnum	= register_cvar("lm_TSD_GBD_account_refill_amount",		"200");
	cvar_TSDbountymul	= register_cvar("lm_TSD_GBD_bounty_multiplier",			"2.0");
	cvar_VONCperTeam	= register_cvar("lm_VONC_per_team_per_round",			"2");
	cvar_VONCtimeLimit	= register_cvar("lm_VONC_voting_time_limit",			"60.0");
	
	// client commands
	register_clcmd("vs",				"Command_VoteTS");
	register_clcmd("votescheme",		"Command_VoteTS");
	register_clcmd("say /votescheme",	"Command_VoteTS");
	register_clcmd("say /vs",			"Command_VoteTS");
	register_clcmd("vonc",				"Command_VoteONC");
	register_clcmd("voteofnoconfidence","Command_VoteONC");
	register_clcmd("say /vonc",			"Command_VoteONC");
	register_clcmd("dr",				"Command_DeclareRole");
	register_clcmd("say /dr",			"Command_DeclareRole");
	register_clcmd("mr",				"Command_ManageRoles");
	register_clcmd("say /dr",			"Command_ManageRoles");
	register_clcmd("buy",				"Command_Buy");
	register_clcmd("buy2",				"Command_Buy");
	
	// debug commands
	register_clcmd("assassin",			"Command_Assassin");
	register_clcmd("berserker",			"Command_Berserker");
	register_clcmd("blaster",			"Command_Blaster");
	register_clcmd("sharpshooter",		"Command_Sharpshooter");
	//register_clcmd("test",				"Command_Test");
	
	// roles custom initiation
	Godfather_Initialize();
	Commander_Initialize();
	Assassin_Initialize();
	Blaster_Initialize();
	Berserker_Initialize();
	Sharpshooter_Initialize();
	
	// bot support
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1);
	
	// orpheu
	g_pfn_RadiusFlash = OrpheuGetFunction("RadiusFlash");
	g_pfn_CBasePlayer_ResetMaxSpeed = OrpheuGetFunctionFromClass("player", "ResetMaxSpeed", "CBasePlayer");
	
	// airsupport
	#if defined AIR_SUPPORT_ENABLE
	RegisterHam(Ham_Item_Deploy, g_rgszWeaponEntity[CSW_KNIFE], "HamF_Item_Deploy_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, g_rgszWeaponEntity[CSW_KNIFE], "HamF_Knife_Slash");
	RegisterHam(Ham_Weapon_SecondaryAttack, g_rgszWeaponEntity[CSW_KNIFE], "HamF_Knife_Stab");
	RegisterHam(Ham_Item_Holster, g_rgszWeaponEntity[CSW_KNIFE], "HamF_Item_Holster_Post", 1);
	
	register_clcmd("giveradio",			"Command_GiveRadio");
	register_clcmd("weapon_radio",		"Command_SelectRadio");
	register_clcmd("weapon_knife",		"Command_SelectKnife");
	//register_clcmd("lastinv",			"Command_LastWeapon");	// I am not sure whether this is needed.
	
	AirSupport_Initialize();
	#endif
}

public plugin_precache()
{
	static szFile[192];
	
	register_forward(FM_Spawn, "fw_Spawn");
	
	// Gamerules
	engfunc(EngFunc_PrecacheSound, SFX_GAME_START_1);
	engfunc(EngFunc_PrecacheSound, SFX_GAME_START_2);
	engfunc(EngFunc_PrecacheSound, SFX_MENPOWER_DEPLETED);
	engfunc(EngFunc_PrecacheSound, SFX_GAME_WON);
	engfunc(EngFunc_PrecacheSound, SFX_GAME_LOST);
	engfunc(EngFunc_PrecacheSound, SFX_RADAR_BEEP);
	engfunc(EngFunc_PrecacheGeneric, MUSIC_GAME_WON);
	engfunc(EngFunc_PrecacheGeneric, MUSIC_GAME_LOST);
	
	// Radio
	#if defined AIR_SUPPORT_ENABLE
	engfunc(EngFunc_PrecacheSound, SFX_RADIO_DRAW);
	engfunc(EngFunc_PrecacheSound, SFX_RADIO_USE);
	engfunc(EngFunc_PrecacheModel, MDL_RADIO_V);
	engfunc(EngFunc_PrecacheModel, MDL_RADIO_P);
	engfunc(EngFunc_PrecacheModel, "sprites/640hud20.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/640hud21.spr");
	engfunc(EngFunc_PrecacheGeneric, "sprites/weapon_radio.txt");
	
	g_strRadioPersonalModel	= engfunc(EngFunc_AllocString, MDL_RADIO_P);
	g_strRadioViewModel		= engfunc(EngFunc_AllocString, MDL_RADIO_V);
	
	AirSupport_Precache();
	#endif

	// Schemes
	engfunc(EngFunc_PrecacheSound, SFX_TSD_GBD);
	
	for (new i = 1; i <= 7; i++)
	{
		formatex(szFile, charsmax(szFile), SFX_TSD_SFD, i);
		engfunc(EngFunc_PrecacheSound, szFile);
	}
	
	// Vote of Non Confidence
	engfunc(EngFunc_PrecacheSound, SFX_VONC_PASSED);
	engfunc(EngFunc_PrecacheSound, SFX_VONC_REJECTED);
	
	// Roles
	engfunc(EngFunc_PrecacheSound, GODFATHER_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, GODFATHER_REVOKE_SFX);
	engfunc(EngFunc_PrecacheSound, COMMANDER_GRAND_SFX);
	engfunc(EngFunc_PrecacheSound, COMMANDER_REVOKE_SFX);
	Assassin_Precache();
	Blaster_Precache();
	Sharpshooter_Precache();
	Berserker_Precache();
	g_ptrBeamSprite = engfunc(EngFunc_PrecacheModel, "sprites/lgtning.spr");
}

public plugin_cfg()
{
	set_cvar_float("sv_maxvelocity", 99999.0);
	set_cvar_float("sv_maxspeed", 9999.0);
}

public client_putinserver(pPlayer)
{
	g_rgbResurrecting[pPlayer] = false;
	g_rgPlayerRole[pPlayer] = Role_UNASSIGNED;
	g_rgbUsingSkill[pPlayer] = false;
	g_rgflSkillCooldown[pPlayer] = 0.0;
	g_rgiConfidenceMotionVotes[pPlayer] = DISCARD;
	g_rgTacticalSchemeVote[pPlayer] = Scheme_UNASSIGNED;
}

public client_disconnected(pPlayer, bool:bDrop, szMessage[], iMaxLen)
{
	// terminating skill
	switch (g_rgPlayerRole[pPlayer])
	{
		case Role_Commander:
		{
			Commander_TerminateSkill();
		}
		case Role_Godfather:
		{
			Godfather_TerminateSkill();
			Commander_RevokeSkill(COMMANDER_TASK);
		}
		case Role_Assassin:
		{
			Assassin_TerminateSkill(pPlayer);
		}
		case Role_Sharpshooter:
		{
			Sharpshooter_TerminateSkill(pPlayer);
		}
		default:
		{
		}
	}
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
		g_rgPlayerRole[victim] = Role_UNASSIGNED;
	}
	else if (victim == g_iLeader[1])
	{
		print_chat_color(0, BLUECHAT, "%s陣亡!", g_rgszRoleNames[Role_Commander]);
		Commander_TerminateSkill();
		g_rgPlayerRole[victim] = Role_UNASSIGNED;
	}

	g_rgbUsingSkill[victim] = false;

	if (g_rgPlayerRole[victim] == Role_Blaster)
		Blaster_Explosion(victim);
	
	new iTeam;
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (victim != THE_GODFATHER && victim != THE_COMMANDER)	// no win/lose sound necessary ... yet.
			break;
		
		if (!is_user_connected(i))
			continue;
		
		if (is_user_bot(i))
			continue;
		
		iTeam = get_pdata_int(i, m_iTeam);
		if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		{
			// play win sound for spectator anyway.
			client_cmd(i, "spk %s", SFX_GAME_WON);
			client_cmd(i, "mp3 play %s", MUSIC_GAME_WON);
			continue;
		}
		
		if (g_iLeader[iTeam - 1] == victim)	// loser
		{
			client_cmd(i, "spk %s", SFX_GAME_LOST);
			client_cmd(i, "mp3 play %s", MUSIC_GAME_LOST);
		}
		else	// winner
		{
			client_cmd(i, "spk %s", SFX_GAME_WON);
			client_cmd(i, "mp3 play %s", MUSIC_GAME_WON);
		}
	}

	if (!is_user_connected(victim))
		return;

	iTeam = get_pdata_int(victim, m_iTeam);
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return;
	
	// terminating skill
	switch (g_rgPlayerRole[victim])
	{
		case Role_Assassin:
		{
			Assassin_TerminateSkill(victim);
		}
		case Role_Sharpshooter:
		{
			Sharpshooter_TerminateSkill(victim);
		}
		default:
		{
		}
	}
	
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

public HamF_TraceAttack(iVictim, iAttacker, Float:flDamage, Float:vecDirection[3], tr, bitsDamageTypes)	// sharpshooter deathmark skill & assassin passive skill
{
	if (!is_user_alive(iAttacker))
		return HAM_IGNORED;
	
	new iId = get_pdata_int(get_pdata_cbase(iAttacker, m_pActiveItem), m_iId, 4);
	
	if (g_rgPlayerRole[iAttacker] == Role_Assassin &&
		(iId == CSW_USP || iId == CSW_M14EBR || iId == CSW_MP7A1 || iId == CSW_M200) &&	// silenced weapons
		!random_num(0, 99) )	// 1% chance
	{
		new Float:vecOrigin[3];
		get_tr2(tr, TR_vecEndPos, vecOrigin);
		
		client_cmd(iAttacker, "spk %s", ASSASSIN_CRITICAL_SFX);
		client_cmd(iVictim, "spk %s", ASSASSIN_CRITICAL_SFX);
		UTIL_BeamEntPoint(iAttacker|0x1000, vecOrigin, g_ptrBeamSprite, 0, 100, 1, 47, 5, 75, 75, 75, 255, 5);
		
		SetHamParamFloat(3, flDamage * 10.0);	// critical hit
		return HAM_HANDLED;
	}
	
	if (g_rgPlayerRole[iAttacker] == Role_Sharpshooter && g_rgbUsingSkill[iAttacker] &&
		(iId == CSW_AWP || iId == CSW_M200 || iId == CSW_M14EBR || iId == CSW_SVD) )	// skill only avaliable when using a sniper rifle.
	{
		new Float:vecOrigin[3];
		get_tr2(tr, TR_vecEndPos, vecOrigin);
		RadiusFlash(vecOrigin, get_pdata_cbase(iAttacker, m_pActiveItem), iAttacker, 1.0);
		
		set_tr2(tr, TR_iHitgroup, HIT_HEAD);	// mp.dll::monsters.h is using "HITGROUP_HEAD" with same number.
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public HamF_TraceAttack_Post(iVictim, iAttacker, Float:flDamage, Float:vecDirection[3], tr, bitsDamageTypes)
{
	if (!is_user_connected(iVictim))
		return;
	
	if (g_rgPlayerRole[iVictim] == Role_Assassin && g_rgbUsingSkill[iVictim])	// catcha!!!
	{
		Assassin_TerminateSkill(iVictim);
		client_cmd(iVictim, "spk %s", ASSASSIN_DISCOVERED_SFX);
		
		if (is_user_connected(iAttacker))
			client_cmd(iAttacker, "spk %s", ASSASSIN_DISCOVERED_SFX);
	}
}

public HamF_TakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	if (is_user_alive(iVictim) && g_rgbUsingSkill[iVictim])
	{
		if (g_rgPlayerRole[iVictim] == Role_Godfather || g_rgPlayerRole[iVictim] == Role_Commander)
			SetHamParamFloat(4, flDamage * 0.5);
		else if (g_rgPlayerRole[iVictim] == Role_Berserker)
		{
			new Float:flCurHealth;
			pev(iVictim, pev_health, flCurHealth);
			if (flCurHealth - flDamage < 1.0)
			{
				set_pev(iVictim, pev_health, 1.0);
				return FMRES_SUPERCEDE;
			}
		}
	}

	if (is_user_alive(iAttacker))
	{
		if (g_rgPlayerRole[iAttacker] == Role_Berserker)
		{
			new Float:flCurHealth;
			pev(iVictim, pev_health, flCurHealth);
			SetHamParamFloat(4, floatclamp(100.0 - flCurHealth, 0.0, 100.0) + flDamage);
		}
		else if (g_rgPlayerRole[iAttacker] == Role_Blaster && g_rgbUsingSkill[iAttacker])
		{
			if (bitsDamageTypes & DMG_BLAST || bitsDamageTypes & (1<<24))		// Blast or HE Grenade damage
				SetHamParamFloat(4, flDamage * 1.5);
		}
	}
	
	if (is_user_connected(iVictim) && g_rgPlayerRole[iVictim] == Role_Blaster && bitsDamageTypes & ((1<<24) | DMG_BLAST))	// blaster is resist to grenade damage.
	{
		SetHamParamFloat(4, flDamage * 0.25);
	}
	
	return HAM_IGNORED;
}

public HamF_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	if (!is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return;

	if (is_user_alive(iVictim) && bitsDamageTypes & DMG_FREEZE)
	{
		if (iInflictor && pev(iInflictor, pev_weapons) == ICE_GRENADE_KEY)
			Sharpshooter_GetFrozen(iVictim);
	}
	
	new iVictimTeam = get_pdata_int(iVictim, m_iTeam);
	new iAttackerTeam = get_pdata_int(iAttacker, m_iTeam);
	
	if (iVictimTeam != iAttackerTeam)
		UTIL_AddAccount(iAttacker, floatround(flDamage * (g_rgTeamTacticalScheme[iAttackerTeam] == Doctrine_GrandBattleplan ? get_pcvar_float(cvar_TSDbountymul) : 1.0 )) );
	else
		UTIL_AddAccount(iAttacker, -floatround(flDamage * 3.0));
}

#if defined AIR_SUPPORT_ENABLE
public HamF_Item_Deploy_Post(iEntity)
{
	if (pev(iEntity, pev_weapons) != CSW_RADIO)
		return;
	
	new pPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	set_pev(pPlayer, pev_viewmodel, g_strRadioViewModel);
	set_pev(pPlayer, pev_weaponmodel, g_strRadioPersonalModel);
	
	UTIL_WeaponAnim(pPlayer, ANIM_RADIO_DRAW);
	set_pdata_float(pPlayer, m_flNextAttack, ANIMTIME_RADIO_DRAW);
	set_pdata_float(iEntity, m_flNextPrimaryAttack, ANIMTIME_RADIO_DRAW, 4);
	set_pdata_float(iEntity, m_flNextSecondaryAttack, ANIMTIME_RADIO_DRAW, 4);
	set_pdata_float(iEntity, m_flTimeWeaponIdle, ANIMTIME_RADIO_DRAW, 4);
}
#endif

public HamF_Weapon_PrimaryAttack_Post(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	// Firerate for CT leader
	if (is_user_alive(iPlayer) && iPlayer == THE_COMMANDER && g_rgbUsingSkill[iPlayer])
		set_pdata_float(iEntity, m_flNextPrimaryAttack, get_pdata_float(iEntity, m_flNextPrimaryAttack) * 0.5, 4);
}

#if defined AIR_SUPPORT_ENABLE
public HamF_Knife_Slash(iEntity)
{
	if (pev(iEntity, pev_weapons) != CSW_RADIO)
		return HAM_IGNORED;
	
	new pPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	UTIL_WeaponAnim(pPlayer, ANIM_RADIO_USE);
	engfunc(EngFunc_EmitSound, pPlayer, CHAN_AUTO, SFX_RADIO_USE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	set_pdata_float(pPlayer, m_flNextAttack, ANIMTIME_RADIO_USE);
	set_pdata_float(iEntity, m_flNextPrimaryAttack, ANIMTIME_RADIO_USE, 4);
	set_pdata_float(iEntity, m_flNextSecondaryAttack, ANIMTIME_RADIO_USE, 4);
	set_pdata_float(iEntity, m_flTimeWeaponIdle, ANIMTIME_RADIO_USE, 4);
	
	new Float:vecGoal[3], Float:vecOrigin[3];
	get_aim_origin_vector(pPlayer, 9999.0, 0.0, 0.0, vecGoal);
	engfunc(EngFunc_TraceLine, vecOrigin, vecGoal, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, pPlayer, 0);
	get_tr2(0, TR_vecEndPos, vecGoal);
	Call(pPlayer, TEAM_CT, vecGoal);
	return HAM_SUPERCEDE;
}

public HamF_Knife_Stab(iEntity)
{
	if (pev(iEntity, pev_weapons) != CSW_RADIO)
		return HAM_IGNORED;
	
	return HAM_SUPERCEDE;
}
#endif

public HamF_Weapon_WeaponIdle(iEntity)
{
	new pPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	if (!is_user_connected(pPlayer))
		return HAM_IGNORED;
	
	if (g_rgPlayerRole[pPlayer] != Role_Blaster || !g_rgbUsingSkill[pPlayer])
		return HAM_IGNORED;
	
	// this is the condition of substracting BP ammo.
	if (get_pdata_float(iEntity, m_flTimeWeaponIdle, 4) <= 0.0 || get_pdata_float(iEntity, m_flStartThrow, 4) != 0.0)
		return HAM_IGNORED;
	
	switch (get_pdata_int(iEntity, m_iId, 4))
	{
		case CSW_HEGRENADE:
			set_pdata_int(pPlayer, m_rgAmmo[12], 1);
		
		case CSW_SMOKEGRENADE:
			set_pdata_int(pPlayer, m_rgAmmo[13], 1);
		
		case CSW_FLASHBANG:
			set_pdata_int(pPlayer, m_rgAmmo[11], 2);
		
		default:
			return HAM_IGNORED;
	}
	
	return HAM_IGNORED;
}

#if defined AIR_SUPPORT_ENABLE
public HamF_Item_Holster_Post(iEntity)
{
	set_pev(iEntity, pev_weapons, 0);
}
#endif

public HamF_CS_RoundRespawn_Post(pPlayer)
{
	if (!is_user_connected(pPlayer))
		return;
	
	new iTeam = get_pdata_int(pPlayer, m_iTeam);
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return;

	if (!g_bRoundStarted)	// avoid the new round error
		return;
	
	set_pdata_int(pPlayer, m_iHideHUD, get_pdata_int(pPlayer, m_iHideHUD) | HIDEHUD_TIMER);
	
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
			
			if (flFraction >= 1.0 && UTIL_CheckPassibility(vecCandidates[i]))
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
	
	if (g_rgTeamTacticalScheme[iTeam] == Doctrine_GrandBattleplan)
	{
		set_pev(pPlayer, pev_armorvalue, 100.0);
		set_pdata_int(pPlayer, m_iKevlar, 2);
		
		fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_HEGRENADE]);
		fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_FLASHBANG]);
		fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_FLASHBANG]);
		fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_SMOKEGRENADE]);
	}
}

public HamF_BloodColor(iPlayer)
{
	if (g_rgflFrozenNextthink[iPlayer] <= get_gametime())
		return HAM_IGNORED;
	
	SetHamReturnInteger(15);
	return HAM_SUPERCEDE;
}

public HamF_Weaponbox_Touch(iEntity, iPlayer)
{
	if (!is_user_alive(iPlayer))	// assassin is not allowed to pickup weapons while sneaking.
		return HAM_IGNORED
	
	for (new i = 1; i < 6; i++)
	{
		new iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems2[i], 4);
		
		if (pev_valid(iWeapon) != 2)
			continue;
		
		new iId = get_pdata_int(iWeapon, m_iId, 4);
		if (g_rgRoleWeaponsAccessibility[g_rgPlayerRole[iPlayer]][iId] == WPN_F)
			return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public fw_AddToFullPack_Post(ES_Handle, e, iEntity, iHost, iHostFlags, bIsPlayer, iSet)
{
	if (!is_user_connected(iHost))
		return;
	
	if (is_user_bot(iHost))
		return;
	
	if (bIsPlayer && is_user_alive(iHost))
	{
		if (g_rgflFrozenNextthink[iEntity] > get_gametime())
		{
			set_es(ES_Handle, ES_RenderFx, kRenderFxGlowShell)
			set_es(ES_Handle, ES_RenderColor, { 80, 80, 100 })
			set_es(ES_Handle, ES_RenderAmt, 50)
			set_es(ES_Handle, ES_RenderMode, kRenderNormal)
		}
		else if (iEntity == g_iLeader[0])
		{
			set_es(ES_Handle, ES_RenderFx, kRenderFxGlowShell)
			set_es(ES_Handle, ES_RenderColor, {255, 0, 0})
			set_es(ES_Handle, ES_RenderAmt, 1)
			set_es(ES_Handle, ES_RenderMode, kRenderNormal)
		}
		else if (iEntity == g_iLeader[1])
		{
			set_es(ES_Handle, ES_RenderFx, kRenderFxGlowShell)
			set_es(ES_Handle, ES_RenderColor, {0, 0, 255})
			set_es(ES_Handle, ES_RenderAmt, 1)
			set_es(ES_Handle, ES_RenderMode, kRenderNormal)
		}
		
		if (g_rgPlayerRole[iHost] == Role_Sharpshooter && g_rgbUsingSkill[iHost] && get_pdata_int(iEntity, m_iTeam) != TEAM_CT)
		{
			set_es(ES_Handle, ES_RenderMode, kRenderTransAdd);
			set_es(ES_Handle, ES_RenderAmt, 255);
			set_es(ES_Handle, ES_RenderFx, kRenderFxFadeSlow);
			set_es(ES_Handle, ES_RenderColor, {0, 0, 0});
			
			if (iEntity == THE_GODFATHER)
			{
				set_es(ES_Handle, ES_RenderColor, {255, 0, 0});
				set_es(ES_Handle, ES_Effects, (get_es(ES_Handle, ES_Effects) | EF_DIMLIGHT));
			}
		}
	}
}

public fw_Touch_Post(iEntity)
{
	static szClassName[33];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	
	if (strcmp(szClassName, "grenade"))
		return;
	
	if (pev(iEntity, pev_weapons) != ICE_GRENADE_KEY)
		return;
	
	Sharpshooter_IceExplode(iEntity);
}

public fw_SetModel(iEntity, szModel[])
{
	if (strlen(szModel) < 8)
		return FMRES_IGNORED
	
	if (szModel[7] != 'w' || szModel[8] != '_')
		return FMRES_IGNORED
	
	static classname[32]
	pev(iEntity, pev_classname, classname, charsmax(classname))
	
	if (!strcmp(classname, "weaponbox"))
	{
		set_pev(iEntity, pev_nextthink, get_gametime() + get_pcvar_float(cvar_WMDLkilltime));
	}
	else if (!strcmp(classname, "grenade") && !strcmp(szModel,"models/w_hegrenade.mdl"))
	{
		new iPlayer = pev(iEntity, pev_owner);
		if (g_rgPlayerRole[iPlayer] == Role_Sharpshooter)
		{
			set_pev(iEntity, pev_dmgtime, 99999.0)
			set_pev(iEntity, pev_weapons, ICE_GRENADE_KEY)
		}
	}
	
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
		
			if (!is_user_alive(g_iLeader[iTeam - 1]))
				return;
			
			if (g_rgPlayerRole[i] == Role_Assassin && g_rgbUsingSkill[i])	// assassin will "look" like dead when using his invisible skill.
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
			
			if (!is_user_alive(g_iLeader[iTeam - 1]) || g_rgiTeamMenPower[iTeam] <= 0 || is_user_alive(i))
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
				g_rgiTeamSchemeBallotBox[i][j] = 0;	// re-zero before each vote.
		
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (!is_user_connected(i))
				continue;
			
			if (is_user_bot(i))	// TODO: shall bots get to vote?
				continue;
			
			new iTeam = get_pdata_int(i, m_iTeam);
			if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
				continue;
			
			g_rgiTeamSchemeBallotBox[iTeam][g_rgTacticalSchemeVote[i]]++;
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
				if (g_rgiTeamSchemeBallotBox[j][i] > g_rgiTeamSchemeBallotBox[j][g_rgTeamTacticalScheme[j]])
					g_rgTeamTacticalScheme[j] = i;
				else if (g_rgTeamTacticalScheme[j] != i && g_rgiTeamSchemeBallotBox[j][i] > 0 && g_rgiTeamSchemeBallotBox[j][i] == g_rgiTeamSchemeBallotBox[j][g_rgTeamTacticalScheme[j]])	// disputation
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
					g_rgiTeamMenPower[j] = floatround(float(g_rgiTeamMenPower[j]) * get_pcvar_float(cvar_TSDmenpowermul));
				else if (iSavedTS == Doctrine_MassAssault)	// switching to others
					g_rgiTeamMenPower[j] = floatround(float(g_rgiTeamMenPower[j]) / get_pcvar_float(cvar_TSDmenpowermul));
			}
		}
	}
	
	for (new iTeam = TEAM_TERRORIST; iTeam <= TEAM_CT; iTeam++)	// Team Tactical Scheme Effect Think; Team Confidence Motion Think
	{
		if (g_rgflTeamTSEffectThink[iTeam] <= fCurTime && g_rgTeamTacticalScheme[iTeam] != Scheme_UNASSIGNED)
		{
			for (new i = 1; i <= global_get(glb_maxClients); i++)
			{
				if (!is_user_connected(i))
					continue;
				
				if (get_pdata_int(i, m_iTeam) != iTeam)
					continue;
				
				switch (g_rgTeamTacticalScheme[iTeam])
				{
					case Doctrine_GrandBattleplan:
					{
						if (get_pdata_int(i, m_iAccount) < 16000)
						{
							UTIL_AddAccount(i, get_pcvar_num(cvar_TSDmoneyaddnum));
							client_cmd(i, "spk %s", SFX_TSD_GBD);
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
								set_pdata_int(iEntity, m_iClip, get_pdata_int(iEntity, m_iClip, 4) + g_rgiClipRegen[iId], 4);
								
								if (!random_num(0, 3))	// constant sound makes player annoying.
								{
									static szSound[64];
									formatex(szSound, charsmax(szSound), SFX_TSD_SFD, random_num(1, 7));
									client_cmd(i, "spk %s", szSound);
								}
							}
						}
					}
					
					default:
						continue;
				}
			}
			
			switch (g_rgTeamTacticalScheme[iTeam])
			{
				case Doctrine_GrandBattleplan:
					g_rgflTeamTSEffectThink[iTeam] = fCurTime + get_pcvar_float(cvar_TSDmoneyaddinv);
				
				case Doctrine_SuperiorFirepower:
					g_rgflTeamTSEffectThink[iTeam] = fCurTime + get_pcvar_float(cvar_TSDrefillinv);
				
				default:
					g_rgflTeamTSEffectThink[iTeam] = fCurTime + 5.0;
			}
		}
		
		if (g_rgflTeamCnfdnceMtnTimeLimit[iTeam] > 0.0)	// there is a voting ongoing.
		{
			g_rgiTeamCnfdnceMtnBallotBox[iTeam][TRUST] = 0;
			g_rgiTeamCnfdnceMtnBallotBox[iTeam][DEPRIVE] = 0;
			
			new iTeamPlayerCount = 0;
			for (new i = 1; i <= global_get(glb_maxClients); i++)
			{
				if (!is_user_connected(i))
					continue;
				
				if (get_pdata_int(i, m_iTeam) != iTeam)
					continue;
				
				if (g_rgiConfidenceMotionVotes[i] == TRUST || g_rgiConfidenceMotionVotes[i] == DEPRIVE)
				{
					g_rgiTeamCnfdnceMtnBallotBox[iTeam][g_rgiConfidenceMotionVotes[i]]++;
					iTeamPlayerCount++;
				}
			}
			
			if (g_rgiTeamCnfdnceMtnBallotBox[iTeam][TRUST] > (iTeamPlayerCount / 2) ||	// one of the two opinions wins plurality.
				g_rgiTeamCnfdnceMtnBallotBox[iTeam][DEPRIVE] > (iTeamPlayerCount / 2) )
			{
				g_rgflTeamCnfdnceMtnTimeLimit[iTeam] = fCurTime - 1.0;	// ends voting right fucking now.
			}
			
			// UNDONE: time left hint. how to prevent it trigger it multiple frames?
			//new iTimeLeft = floatround(g_rgflTeamCnfdnceMtnTimeLimit[iTeam] - fCurTime);
			//if (iTimeLeft == floatround(get_pdata_float(cvar_VONCtimeLimit) / 2.0))
		}
		
		if (g_rgflTeamCnfdnceMtnTimeLimit[iTeam] <= fCurTime && g_rgflTeamCnfdnceMtnTimeLimit[iTeam] > 0.0)
		{
			if (g_rgiTeamCnfdnceMtnBallotBox[iTeam][TRUST] >= g_rgiTeamCnfdnceMtnBallotBox[iTeam][DEPRIVE])
			{
				UTIL_ColorfulPrintChat(0, "/y針對%s/g%s/y的/t不信任動議/y沒有通過: /g%s/y將留任。", REDCHAT, g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_szLeaderNetname[iTeam - 1], g_szLeaderNetname[iTeam - 1]);
				client_cmd(0, "spk %s", SFX_VONC_REJECTED);
			}
			else
			{
				new iCandidateCount = 0, rgiCandidates[33];
				for (new i = 1; i <= global_get(glb_maxClients); i++)
				{
					if (!is_user_connected(i))
						continue;
					
					if (get_pdata_int(i, m_iTeam) != iTeam)
						continue;
					
					if (i == g_iLeader[iTeam - 1])
						continue;
					
					if (is_user_bot(i) && get_pcvar_num(cvar_humanleader))
						continue;
					
					iCandidateCount++;
					rgiCandidates[iCandidateCount] = i;
				}
				
				if (!iCandidateCount)	// only one player?
				{
					for (new i = 1; i <= global_get(glb_maxClients); i++)
					{
						if (!is_user_connected(i))
							continue;
						
						if (get_pdata_int(i, m_iTeam) != iTeam)
							continue;
						
						if (i == g_iLeader[iTeam - 1])
							continue;
						
						iCandidateCount++;
						rgiCandidates[iCandidateCount] = i;
					}
				}
				
				if (iCandidateCount > 0)
				{
					new iCromwell = rgiCandidates[random_num(1, iCandidateCount)], bool:bCharlesI = false, iCharlesI = g_iLeader[iTeam - 1];	// check your history textbook.
					if (!is_user_alive(iCromwell))
						bCharlesI = true;
					
					if (iTeam == TEAM_TERRORIST)
						Godfather_Assign(iCromwell);
					else if (iTeam == TEAM_CT)
						Commander_Assign(iCromwell);
					
					if (bCharlesI)
					{
						set_pev(iCharlesI, pev_health, 1.0);
						ExecuteHamB(Ham_TakeDamage, iCharlesI, 0, iCharlesI, 10.0, DMG_FALL | DMG_NEVERGIB);
					}
					
					UTIL_ColorfulPrintChat(0, "/t不信任動議/y已經通過: /g%s/y已經被推舉為新的/g%s/y!", REDCHAT, g_szLeaderNetname[iTeam - 1], iTeam == TEAM_CT ? COMMANDER_TEXT : GODFATHER_TEXT);
					client_cmd(0, "spk %s", SFX_VONC_PASSED);
				}
				else
				{
					UTIL_ColorfulPrintChat(0, "/y由於/t人數不足/y, 針對%s/g%s/y的/t不信任動議/y沒有通過: /g%s/y將留任。", REDCHAT, g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_szLeaderNetname[iTeam - 1], g_szLeaderNetname[iTeam - 1]);
					client_cmd(0, "spk %s", SFX_VONC_REJECTED);
				}
			}
			
			g_rgflTeamCnfdnceMtnTimeLimit[iTeam] = -1.0;
			for (new i = 0; i < 33; i++)
				g_rgiConfidenceMotionVotes[i] = DISCARD;
		}
	}
	
	// custom global think
	Assassin_SkillThink();
}

public fw_PlayerPreThink_Post(pPlayer)
{
	Sharpshooter_IceThink(pPlayer);
}

public fw_PlayerPostThink_Post(pPlayer)
{
	if (!is_user_connected(pPlayer))
		return;
	
	if (IsObserver(pPlayer))	// including player "afterlife".
		return;
	
	new iTeam = get_pdata_int(pPlayer, m_iTeam);
	
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return;
	
	// HUD
	if (!is_user_bot(pPlayer) && g_rgflHUDThink[pPlayer] < get_gametime())
	{
		new rgColor[3] = { 255, 255, 0 };
		new Float:flCoordinate[2] = { -1.0, 0.90 };
		new Float:flGoalCoordinate[2] = { -1.0, 0.05 };
		new Float:rgflTime[4] = { 6.0, 4000.0, 0.0, 0.0 };
		
		static szText[192], szSkillText[192], szGoal[192];
		formatex(szSkillText, charsmax(szSkillText), "");	// have to clear it each frame, or the strcpy() will fuck everything up.
		
		if (!g_rgbAllowSkill[pPlayer] && !g_rgbUsingSkill[pPlayer])	// Cooling down
		{
			new Float:flCooldownTimeLeft = g_rgflSkillCooldown[pPlayer] - get_gametime();
			if (flCooldownTimeLeft > 0.0 && g_rgSkillCooldown[g_rgPlayerRole[pPlayer]] > -1)
			{
				new Float:flCooldownLength = get_pcvar_float(g_rgSkillCooldown[g_rgPlayerRole[pPlayer]]);	// Done by Rex
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
			if (flSkillEffectLeft > 0.0 && g_rgSkillDuration[g_rgPlayerRole[pPlayer]] > -1)
			{
				new Float:flSkillEffectLength = get_pcvar_float(g_rgSkillDuration[g_rgPlayerRole[pPlayer]]);	// Done by Rex
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
		{
			if (strlen(g_rgszRolePassiveSkills[g_rgPlayerRole[pPlayer]]))
				formatex(szText, charsmax(szText), "身份: %s^n%s^n%s^n%s已陣亡|兵源補給中斷|%s", g_rgszRoleNames[g_rgPlayerRole[pPlayer]], szSkillText, g_rgszRolePassiveSkills[g_rgPlayerRole[pPlayer]], g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[iTeam]]);
			else
				formatex(szText, charsmax(szText), "身份: %s^n%s^n%s已陣亡|兵源補給中斷|%s", g_rgszRoleNames[g_rgPlayerRole[pPlayer]], szSkillText, g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[iTeam]]);
		}
		else
		{
			if (strlen(g_rgszRolePassiveSkills[g_rgPlayerRole[pPlayer]]))
				formatex(szText, charsmax(szText), "身份: %s^n%s^n%s^n%s: %s|兵源剩餘: %d|%s", g_rgszRoleNames[g_rgPlayerRole[pPlayer]], szSkillText, g_rgszRolePassiveSkills[g_rgPlayerRole[pPlayer]], g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_szLeaderNetname[iTeam - 1], g_rgiTeamMenPower[iTeam], g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[iTeam]]);
			else
				formatex(szText, charsmax(szText), "身份: %s^n%s^n%s: %s|兵源剩餘: %d|%s", g_rgszRoleNames[g_rgPlayerRole[pPlayer]], szSkillText, g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_szLeaderNetname[iTeam - 1], g_rgiTeamMenPower[iTeam], g_rgszTacticalSchemeNames[g_rgTeamTacticalScheme[iTeam]]);
		}

		if (!is_user_alive(g_iLeader[2 - iTeam]) && g_iLeader[2 - iTeam] > 0)
			formatex(szGoal, charsmax(szGoal), "任務目標: 扫荡残敌");
		else if (!g_bRoundStarted)	// not started yet.
			formatex(szGoal, charsmax(szGoal), "任務目標: 投票擬定作戰策略");
		else
			formatex(szGoal, charsmax(szGoal), "任務目標: 击杀敌方%s %s", g_rgszRoleNames[g_rgPlayerRole[g_iLeader[2 - iTeam]]], g_szLeaderNetname[2 - iTeam]);
		
		if (strcmp(g_rgszLastHUDText[pPlayer][0], szText))
		{
			g_rgszLastHUDText[pPlayer][0] = szText;
			ShowHudMessage(pPlayer, rgColor, flCoordinate, 0, rgflTime, HUD_SHOWHUD, szText);
		}
		if (strcmp(g_rgszLastHUDText[pPlayer][1], szText))
		{
			g_rgszLastHUDText[pPlayer][1] = szText;
			ShowHudMessage(pPlayer, rgColor, flGoalCoordinate, 0, rgflTime, HUD_SHOWGOAL, szGoal);
		}
		g_rgflHUDThink[pPlayer] = 0.5 + get_gametime();
	}
	
	if (g_rgTeamTacticalScheme[iTeam] == Doctrine_MobileWarfare && is_user_alive(pPlayer) && g_flNextMWDThink < get_gametime())
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
		// these is a bug that if you are survived across rounds, you will permanently lose the access of store.
		// how to fix it? just remove the scheme effect at the end of round.
		
		new bool:bEnemyExist = false;
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (is_user_alive(i) && get_pdata_int(i, m_iTeam) == (3 - iTeam))	// this pdata is safe, since '&&' operator will prevent the execution of the second parameter if the first one was already FALSE.
			{
				bEnemyExist = true;
				break;
			}
		}
		
		// LUNA: when sv_restart is used, the exact same bug would occurs.
		if (get_pcvar_num(cvar_restartSV))
			bEnemyExist = false;
		
		if (get_pcvar_num(cvar_restartSV) == 1)	// since sv_restart == 0 doesn't means the restart has over, we have to pause the think for 1 second.
			g_flNextMWDThink = get_gametime() + 2.5;
		
		if (bEnemyExist)
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
	else if (iTeam == TEAM_TERRORIST)	// Godfather's skill
	{
		Godfather_HealingThink(pPlayer);
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
	if (!is_user_alive(iPlayer))
		return FMRES_IGNORED;

	if (get_uc(uc_handle, UC_Impulse) != 201)
		return FMRES_IGNORED;

	if (g_rgbUsingSkill[iPlayer])
	{
		print_chat_color(iPlayer, GREYCHAT, "技能正在使用中！");
		return FMRES_IGNORED;
	}

	if (!g_rgbAllowSkill[iPlayer])
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
		case Role_Assassin:
		{
			Assassin_ExecuteSkill(iPlayer);
		}
		case Role_Berserker:
		{
			Berserker_ExecuteSkill(iPlayer);
		}
		case Role_Blaster:
		{
			Blaster_ExecuteSkill(iPlayer);
		}
		case Role_Sharpshooter:
		{
			Sharpshooter_ExecuteSkill(iPlayer);
		}
		default:
			return FMRES_IGNORED;
	}

	print_chat_color(iPlayer, GREENCHAT, "技能已施放！");
	g_rgbUsingSkill[iPlayer] = true;
	g_rgbAllowSkill[iPlayer] = false;
	g_rgflSkillExecutedTime[iPlayer] = get_gametime();
	set_uc(uc_handle, UC_Impulse, 0);

	return FMRES_IGNORED;
}

public fw_ClientCommand(iPlayer)
{
	static szCommand[24];
	read_argv(0, szCommand, charsmax(szCommand));
	
	if (UTIL_GetAliasId(szCommand))	// block original buy
		return FMRES_SUPERCEDE;
	
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
		client_cmd(0, "spk %s", SFX_MENPOWER_DEPLETED);
	}
}

public Event_FreezePhaseEnd()
{
	new bool:bHumanPriority = !!get_pcvar_num(cvar_humanleader);
	
	Godfather_Assign(UTIL_RandomNonroleCharacter(TEAM_TERRORIST, bHumanPriority));
	Commander_Assign(UTIL_RandomNonroleCharacter(TEAM_CT, bHumanPriority));
	
	g_rgPlayerRole[UTIL_RandomNonroleCharacter(TEAM_TERRORIST, bHumanPriority)] = Role_Assassin;
	g_rgPlayerRole[UTIL_RandomNonroleCharacter(TEAM_CT, bHumanPriority)] = Role_Sharpshooter;
	g_rgPlayerRole[UTIL_RandomNonroleCharacter(TEAM_TERRORIST, bHumanPriority)] = Role_Berserker;
	g_rgPlayerRole[UTIL_RandomNonroleCharacter(TEAM_CT, bHumanPriority)] = Role_Blaster;

	g_bRoundStarted = true;

	new iPlayerAmount = 0, iTeam = TEAM_SPECTATOR;
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_alive(i))
			continue;
		
		iPlayerAmount ++;
		
		if (is_user_bot(i))
			continue;
		
		iTeam = get_pdata_int(i, m_iTeam);
		if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
			continue;
		
		// hint TR who is commander, and hint CT who is godfather.
		print_chat_color(i, iTeam == TEAM_CT ? BLUECHAT : REDCHAT, "%s是%s, 殺死他以切斷%s兵源補給!", g_szLeaderNetname[2 - iTeam], g_rgszRoleNames[iTeam == TEAM_CT ? Role_Godfather : Role_Commander], g_rgszTeamName[3 - iTeam]);
		
		set_pdata_int(i, m_iHideHUD, get_pdata_int(i, m_iHideHUD) | HIDEHUD_TIMER);
	}
	
	// menpower initiation
	g_rgiTeamMenPower[TEAM_CT] = get_pcvar_num(cvar_menpower) * iPlayerAmount;
	g_rgiTeamMenPower[TEAM_TERRORIST] = get_pcvar_num(cvar_menpower) * iPlayerAmount;
	
	for (new i = TEAM_TERRORIST; i <= TEAM_CT; i++)
		if (g_rgTeamTacticalScheme[i] == Doctrine_MassAssault)
			g_rgiTeamMenPower[i] = floatround(float(g_rgiTeamMenPower[i]) * get_pcvar_float(cvar_TSDmenpowermul));
	
	client_cmd(0, "spk %s", random_num(0, 1) ? SFX_GAME_START_1 : SFX_GAME_START_2);
}

public Event_HLTV()
{
	g_iLeader[0] = -1;
	g_iLeader[1] = -1;
	
	formatex(g_szLeaderNetname[0], charsmax(g_szLeaderNetname[]), "未揭示");
	formatex(g_szLeaderNetname[1], charsmax(g_szLeaderNetname[]), "未揭示");
	
	for (new i = 0; i < 33; i++)
	{
		g_rgbResurrecting[i] = false;
		g_rgiConfidenceMotionVotes[i] = DISCARD;
		g_rgflFrozenNextthink[i] = 0.0
	}
	
	g_bRoundStarted = false;
	
	for (new i = TEAM_TERRORIST; i <= TEAM_CT; i++)
	{
		g_rgflTeamCnfdnceMtnTimeLimit[i] = -1.0;
		g_rgiTeamCnfdnceMtnLeft[i] = get_pcvar_num(cvar_VONCperTeam);
		g_rgiTeamCnfdnceMtnBallotBox[i][TRUST] = 0;
		g_rgiTeamCnfdnceMtnBallotBox[i][DEPRIVE] = 0;
	}
	
	// custom role HLTV events
	Godfather_TerminateSkill();
	Commander_TerminateSkill();

	for (new i = 1; i <= global_get(glb_maxClients); i ++)
	{
		if (is_user_connected(i))
		{
			remove_task(BERSERKER_TASK + i);
			remove_task(BLASTER_TASK + i);

			g_rgPlayerRole[i] = Role_UNASSIGNED;
			g_rgbUsingSkill[i] = false;
			g_rgflSkillCooldown[i] = 0.0;
			
			set_pdata_int(i, m_iHideHUD, get_pdata_int(i, m_iHideHUD) & ~HIDEHUD_TIMER);
			set_pev(i, pev_max_health, 100.0);
		}
	}
	
	client_cmd(0, "stopsound");	// stop music
	client_cmd(0, "mp3 stop");	// stop music
}

public Message_Health(msg_id, msg_dest, msg_entity)
{
	if (!is_user_alive(msg_entity))
		return PLUGIN_CONTINUE;
	
	if (msg_entity != g_iLeader[0] && msg_entity != g_iLeader[1])
		return PLUGIN_CONTINUE;

	if (g_rgPlayerRole[msg_entity] != Role_Godfather && g_rgPlayerRole[msg_entity] != Role_Commander)
		return PLUGIN_CONTINUE;

	new Float:flHealth;
	pev(msg_entity, pev_health, flHealth);

	set_msg_arg_int(1, ARG_BYTE, max(floatround(flHealth / 1000.0 * 100.0), 1));
	return PLUGIN_CONTINUE;
}

public Message_ScreenFade(msg_id, msg_dest, msg_entity)
{
	/**
	Name:		ScreenFade
	Structure:	
				short	Duration
				short	HoldTime
				short	Flags
				byte	ColorR
				byte	ColorG
				byte	ColorB
				byte	Alpha
	**/
	
	if (get_msg_arg_int(4) != 255 || get_msg_arg_int(5) != 255 || get_msg_arg_int(6) != 255 || get_msg_arg_int(7) < 200)
		return PLUGIN_CONTINUE;
	
	if (is_user_connected(msg_entity) && g_rgPlayerRole[msg_entity] == Role_Assassin && g_rgbUsingSkill[msg_entity])	// assassin is immue to flashbang when he is using his skill.
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public Message_StatusValue(msg_id, msg_dest, msg_entity)
{
	/**
	Name:		StatusValue
	Structure:	
				byte	Flag	// 1 is TeamRelation, 2 is PlayerID, and 3 is Health.
				short	Value	// For TeamRelation, 1 is Teammate player, 2 is Non-Teammate player, 3 is Hostage. If TeamRelation is Hostage, PlayerID will be 0 or will be not sent at all.
	**/
	
	// reference: CBasePlayer::UpdateStatusBar()
	
	if(get_msg_arg_int(2) == 0)	// this can only occurs when player health == 0 ???
	{
		if (get_msg_arg_int(1) == 1)
		{
			message_begin(MSG_ONE, get_user_msgid("StatusText"), _, msg_entity);
			write_byte(0);
			write_string("");
			message_end();
		}
		
		return PLUGIN_HANDLED;	// LUNA: why block them all?
	}

	if (get_msg_arg_int(1) == 2)
	{
		new iTarget = get_msg_arg_int(2);
		if (!is_user_connected(iTarget))	// don't use is_user_alive(), this will skip assassins when they are using skill.
			return PLUGIN_CONTINUE;
		
		new Float:flHealth;
		pev(iTarget, pev_health, flHealth)
		if (flHealth <= 0.0)
			return PLUGIN_CONTINUE;
		
		if (g_rgPlayerRole[msg_entity] == Role_Sharpshooter
			|| (g_rgPlayerRole[msg_entity] == Role_Assassin && g_rgbUsingSkill[msg_entity])	// only sniper and sneaking assassin have the detail.
			|| fm_is_user_same_team(msg_entity, iTarget)	// or you are in the same team.
			|| (g_rgPlayerRole[iTarget] == Role_Assassin && g_rgbUsingSkill[iTarget])	// this is a assassin with skill on!
			)
		{
			static szMsg[64];
			formatex(szMsg, charsmax(szMsg), "%s: %%p2 生命值: %d%%%%", g_rgszRoleNames[g_rgPlayerRole[iTarget]], floatround(flHealth));
			
			message_begin(MSG_ONE, get_user_msgid("StatusText"), _, msg_entity);
			write_byte(0);
			write_string(szMsg);
			message_end();
		}
		
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_HANDLED;	// LUNA: why block them all?
}

public Message_StatusText(msg_id, msg_dest, msg_entity)
{
	/**
	Name:		StatusText
	Structure:	
				byte	Unknown
				string	Text
	**/
	
	// reference: CBasePlayer::UpdateStatusBar()

	set_msg_arg_string(2, " ");	// LUNA: I wish nobody notice enemies by the text.
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
		formatex(szItem[i], charsmax(szItem[]), "\w%s (\y%d\w人支持)", g_rgszTacticalSchemeNames[i], g_rgiTeamSchemeBallotBox[iTeam][i]);
	
	strcat(szItem[g_rgTacticalSchemeVote[pPlayer]], " - 已投票", charsmax(szItem[]))
	
	for (new TacticalScheme_e:i = Scheme_UNASSIGNED; i < SCHEMES_COUNT; i++)
		menu_additem(hMenu, szItem[i]);
	
	menu_setprop(hMenu, MPROP_EXIT, MEXIT_ALL);
	menu_display(pPlayer, hMenu, 0);
	return PLUGIN_HANDLED;
}

public Command_VoteONC(pPlayer)
{
	if (!is_user_connected(pPlayer))
		return PLUGIN_HANDLED;
	
	new iTeam = get_pdata_int(pPlayer, m_iTeam);
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return PLUGIN_HANDLED;
	
	if (g_rgiTeamCnfdnceMtnLeft[iTeam] <= 0 && g_rgflTeamCnfdnceMtnTimeLimit[iTeam] <= 0.0)	// no voting left, and there is no ongoing voting.
	{
		UTIL_ColorfulPrintChat(pPlayer, "/t本回合的/g不信任動議/t次數已經用盡。請服從現任%s。", GREYCHAT, g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather]);
		return PLUGIN_HANDLED;
	}
	
	// if in the voting phase
		// open menu for him
	// else
		// start a new vote.
		// clear the vote data from last vote.
	
	new szBuffer[192];
	formatex(szBuffer, charsmax(szBuffer), "\r發起對%s\y%s\r的不信任動議:^n\w(尚餘\y%d\w次)", g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_szLeaderNetname[iTeam - 1], g_rgiTeamCnfdnceMtnLeft[iTeam]);
	
	if (g_rgflTeamCnfdnceMtnTimeLimit[iTeam] > 0.0)	// open voting found!
	{
		new hMenu = menu_create(szBuffer, "MenuHandler_VoteONC");	// create a new menu id for each player. this could avoid the chaos.
		
		menu_additem(hMenu, g_rgszCnfdnceMtnText[DEPRIVE]);
		menu_additem(hMenu, g_rgszCnfdnceMtnText[TRUST]);
		
		menu_setprop(hMenu, MPROP_EXIT, MEXIT_ALL);
		menu_setprop(hMenu, MPROP_EXITNAME, g_rgszCnfdnceMtnText[DISCARD]);
		menu_display(pPlayer, hMenu, 0);
		
		return PLUGIN_HANDLED;
	}
	
	// starting a new vote.
	// don't clear g_rgiConfidenceMotionVotes, since this will sabortage the voting of the other team.
	g_rgflTeamCnfdnceMtnTimeLimit[iTeam] = get_gametime() + get_pcvar_float(cvar_VONCtimeLimit);
	g_rgiTeamCnfdnceMtnLeft[iTeam]--;
	g_rgiTeamCnfdnceMtnBallotBox[iTeam][TRUST] = 0;
	g_rgiTeamCnfdnceMtnBallotBox[iTeam][DEPRIVE] = 0;
	
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != iTeam)
			continue;
		
		if (i == g_iLeader[iTeam - 1])
			continue;

		g_rgiConfidenceMotionVotes[i] = DISCARD;	// default vote.
		
		new hMenu = menu_create(szBuffer, "MenuHandler_VoteONC");	// create a new menu id for each player. this could avoid the chaos.
		
		menu_additem(hMenu, g_rgszCnfdnceMtnText[DEPRIVE]);
		menu_additem(hMenu, g_rgszCnfdnceMtnText[TRUST]);
		
		menu_setprop(hMenu, MPROP_EXIT, MEXIT_ALL);
		menu_setprop(hMenu, MPROP_EXITNAME, g_rgszCnfdnceMtnText[DISCARD]);
		menu_display(i, hMenu, 0);
	}
	
	return PLUGIN_HANDLED;
}

public Command_DeclareRole(pPlayer)
{
	if (!is_user_connected(pPlayer))
		return PLUGIN_HANDLED;
	
	new iTeam = get_pdata_int(pPlayer, m_iTeam);
	if (iTeam != TEAM_CT && iTeam != TEAM_TERRORIST)
		return PLUGIN_HANDLED;
	
	new szBuffer[192];
	formatex(szBuffer, charsmax(szBuffer), "\r當前職業: \y%s\w^n選擇可用的職業以更換", g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_szLeaderNetname[iTeam - 1], g_rgiTeamCnfdnceMtnLeft[iTeam]);
	
	return PLUGIN_HANDLED;
}

public Command_ManageRoles(pPlayer)
{
	return PLUGIN_HANDLED;
}

public Command_Berserker(pPlayer)
{
	if (get_pcvar_num(cvar_DebugMode))
	{
		g_rgPlayerRole[pPlayer] = Role_Berserker;
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public Command_Blaster(pPlayer)
{
	if (get_pcvar_num(cvar_DebugMode))
	{
		g_rgPlayerRole[pPlayer] = Role_Blaster;
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public Command_Sharpshooter(pPlayer)
{
	if (get_pcvar_num(cvar_DebugMode))
	{
		g_rgPlayerRole[pPlayer] = Role_Sharpshooter;
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public Command_Assassin(pPlayer)
{
	if (get_pcvar_num(cvar_DebugMode))
	{
		g_rgPlayerRole[pPlayer] = Role_Assassin;
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public Command_Buy(pPlayer)
{
	if (!is_user_alive(pPlayer) || !(get_pdata_int(pPlayer, m_signals[1]) & SIGNAL_BUY))
		return PLUGIN_HANDLED;
	
	static szCommand[24]
	read_argv(1, szCommand, charsmax(szCommand))
	
	if (!strlen(szCommand))
		formatex(szCommand, charsmax(szCommand), "%d", g_rgPlayerRole[pPlayer]);
	
	new szBuffer[192];
	formatex(szBuffer, charsmax(szBuffer), "\r購買菜單^n\y身份: \w%s", g_rgszRoleNames[Role_e:str_to_num(szCommand)]);
	
	new hMenu = menu_create(szBuffer, "MenuHandler_Buy");

	menu_additem(hMenu, "職業折扣武器", szCommand);
	menu_additem(hMenu, "允許的武器", szCommand);
	menu_additem(hMenu, "價格有懲罰的武器", szCommand);
	menu_additem(hMenu, "防彈衣 - 650$", szCommand);
	menu_additem(hMenu, "鋼盔與防彈衣 - 1000$", szCommand);
	
	menu_setprop(hMenu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(hMenu, MPROP_EXITNAME, "離開");
	menu_display(pPlayer, hMenu, 0);
	
	return PLUGIN_HANDLED;
}

#if defined AIR_SUPPORT_ENABLE
public Command_GiveRadio(pPlayer)
{
	if (pev(pPlayer, pev_weapons) & (1<<CSW_RADIO))
		set_pev(pPlayer, pev_weapons, pev(pPlayer, pev_weapons) & ~(1<<CSW_RADIO));
	else
		set_pev(pPlayer, pev_weapons, pev(pPlayer, pev_weapons) | (1<<CSW_RADIO));
	
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, pPlayer)
	write_string("weapon_radio")	// HUD
	write_byte(-1)	// BP ammo type
	write_byte(-1)	// BP ammo max
	write_byte(-1)	// 2nd ammo type
	write_byte(-1)	// 2nd ammo max
	write_byte(5 - 1)	// slot - 1
	write_byte(2)	// position in slot list
	write_byte(CSW_RADIO)	// weapon iId
	write_byte(0)	// weapon flags
	message_end()
}

public Command_SelectRadio(pPlayer)
{
	if (!(pev(pPlayer, pev_weapons) & (1<<CSW_RADIO)))
		return PLUGIN_HANDLED;
	
	new iEntity = get_pdata_cbase(pPlayer, m_pActiveItem);
	if (get_pdata_int(iEntity, m_iId, 4) == CSW_KNIFE && pev(iEntity, pev_weapons) != CSW_RADIO)	// switch to radio from knife
	{
		set_pev(iEntity, pev_weapons, CSW_RADIO);
		ExecuteHamB(Ham_Item_Deploy, iEntity);
	}
	else
	{
		set_pev(get_pdata_cbase(pPlayer, m_rgpPlayerItems[3]), pev_weapons, CSW_RADIO);
		engclient_cmd(pPlayer, "weapon_knife");
	}
	
	return PLUGIN_HANDLED;
}

public Command_SelectKnife(pPlayer)
{
	new iEntity = get_pdata_cbase(pPlayer, m_pActiveItem);
	
	if (get_pdata_int(iEntity, m_iId, 4) != CSW_KNIFE || pev(iEntity, pev_weapons) != CSW_RADIO)	// switch from other weapons
		return PLUGIN_CONTINUE;
	
	// from radio to knife
	HamF_Item_Holster_Post(iEntity);
	ExecuteHamB(Ham_Item_Deploy, iEntity);
	return PLUGIN_HANDLED;
}
#endif

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

public MenuHandler_VoteONC(pPlayer, hMenu, iItem)
{
	new iLastVote = g_rgiConfidenceMotionVotes[pPlayer];
	new iTeam = get_pdata_int(pPlayer, m_iTeam);
	
	if (iItem == TRUST || iItem == DEPRIVE)
	{
		g_rgiConfidenceMotionVotes[pPlayer] = iItem;
		g_rgiTeamCnfdnceMtnBallotBox[iTeam][iItem]++;
	}
	else
	{
		g_rgiConfidenceMotionVotes[pPlayer] = DISCARD;
	}
	
	if (iLastVote != g_rgiConfidenceMotionVotes[pPlayer] &&
		(iLastVote == TRUST || iLastVote == DEPRIVE) )
	{
		g_rgiTeamCnfdnceMtnBallotBox[iTeam][iLastVote]--;
	}
	
	UTIL_ColorfulPrintChat(0, "/y針對%s/g%s/y的/t不信任動議/y: %s/t%d/y票, %s/g%d/y票。", REDCHAT, g_rgszRoleNames[iTeam == TEAM_CT ? Role_Commander : Role_Godfather], g_szLeaderNetname[iTeam - 1], g_rgszCnfdnceMtnText[DEPRIVE], g_rgiTeamCnfdnceMtnBallotBox[iTeam][DEPRIVE], g_rgszCnfdnceMtnText[TRUST], g_rgiTeamCnfdnceMtnBallotBox[iTeam][TRUST]);
	UTIL_ColorfulPrintChat(0, "/t%s/y至少要比/g%s/y多一票, 不信任動議方可通過。", REDCHAT, g_rgszCnfdnceMtnText[DEPRIVE], g_rgszCnfdnceMtnText[TRUST]);
	
	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}

public MenuHandler_Buy(pPlayer, hMenu, iItem)
{
	new hNextMenu = -1;
	new szRoleIndex[8], Role_e:iRoleIndex, iDummy, szDummy[32], iDummy2;
	menu_item_getinfo(hMenu, iItem, iDummy, szRoleIndex, charsmax(szRoleIndex), szDummy, charsmax(szDummy), iDummy2);
	iRoleIndex = Role_e:str_to_num(szRoleIndex);
	
	switch (iItem)
	{
		case 0:
		{
			new szBuffer[192];
			formatex(szBuffer, charsmax(szBuffer), "\r職業折扣武器^n\y身份: \w%s", g_rgszRoleNames[iRoleIndex]);
			
			hNextMenu = menu_create(szBuffer, "MenuHandler_GiveWeapon");
			
			for (new i = 1; i <= CSW_P90; i++)
			{
				if (g_rgRoleWeaponsAccessibility[iRoleIndex][i] == WPN_D)
				{
					if (get_pdata_int(pPlayer, m_iAccount) >= g_rgiWeaponDefaultCost[i] / 2)
						formatex(szBuffer, charsmax(szBuffer), "\w%s - \y%d\w$", g_rgszWeaponName[i], g_rgiWeaponDefaultCost[i] / 2);
					else
						formatex(szBuffer, charsmax(szBuffer), "\d%s - \r%d\d$", g_rgszWeaponName[i], g_rgiWeaponDefaultCost[i] / 2);
					
					new szInfo[8];
					formatex(szInfo, charsmax(szInfo), "%d,%d", i, g_rgiWeaponDefaultCost[i] / 2);
					menu_additem(hNextMenu, szBuffer, szInfo);
				}
			}
		}
		case 1:
		{
			new szBuffer[192];
			formatex(szBuffer, charsmax(szBuffer), "\r允許的武器^n\y身份: \w%s", g_rgszRoleNames[iRoleIndex]);
			
			hNextMenu = menu_create(szBuffer, "MenuHandler_GiveWeapon");
			
			for (new i = 1; i <= CSW_P90; i++)
			{
				if (g_rgRoleWeaponsAccessibility[iRoleIndex][i] == WPN_A)
				{
					if (get_pdata_int(pPlayer, m_iAccount) >= g_rgiWeaponDefaultCost[i])
						formatex(szBuffer, charsmax(szBuffer), "\w%s - \y%d\w$", g_rgszWeaponName[i], g_rgiWeaponDefaultCost[i]);
					else
						formatex(szBuffer, charsmax(szBuffer), "\d%s - \r%d\d$", g_rgszWeaponName[i], g_rgiWeaponDefaultCost[i]);
					
					new szInfo[8];
					formatex(szInfo, charsmax(szInfo), "%d,%d", i, g_rgiWeaponDefaultCost[i]);
					menu_additem(hNextMenu, szBuffer, szInfo);
				}
			}
		}
		case 2:
		{
			new szBuffer[192];
			formatex(szBuffer, charsmax(szBuffer), "\r價格有懲罰的武器^n\y身份: \w%s", g_rgszRoleNames[iRoleIndex]);
			
			hNextMenu = menu_create(szBuffer, "MenuHandler_GiveWeapon");
			
			for (new i = 1; i <= CSW_P90; i++)
			{
				if (g_rgRoleWeaponsAccessibility[iRoleIndex][i] == WPN_P)
				{
					if (get_pdata_int(pPlayer, m_iAccount) >= g_rgiWeaponDefaultCost[i] * 2)
						formatex(szBuffer, charsmax(szBuffer), "\w%s - \y%d\w$", g_rgszWeaponName[i], g_rgiWeaponDefaultCost[i] * 2);
					else
						formatex(szBuffer, charsmax(szBuffer), "\d%s - \r%d\d$", g_rgszWeaponName[i], g_rgiWeaponDefaultCost[i] * 2);
					
					new szInfo[8];
					formatex(szInfo, charsmax(szInfo), "%d,%d", i, g_rgiWeaponDefaultCost[i] * 2);
					menu_additem(hNextMenu, szBuffer, szInfo);
				}
			}
		}
		case 3:
		{
			if (get_pdata_int(pPlayer, m_iAccount) >= 650)
			{
				set_pev(pPlayer, pev_armorvalue, 100.0);
				set_pdata_int(pPlayer, m_iKevlar, max(get_pdata_int(pPlayer, m_iKevlar), 1));
				UTIL_AddAccount(pPlayer, -650);
			}
			else
				print_chat_color(pPlayer, REDCHAT, "金錢不足!");
		}
		case 4:
		{
			if (get_pdata_int(pPlayer, m_iKevlar) == 2)
			{
				if (get_pdata_int(pPlayer, m_iAccount) >= 650)
				{
					set_pev(pPlayer, pev_armorvalue, 100.0);
					UTIL_AddAccount(pPlayer, -650);
				}
				else
					print_chat_color(pPlayer, REDCHAT, "金錢不足!");
			}
			else
			{
				if (get_pdata_int(pPlayer, m_iAccount) >= 1000)
				{
					set_pev(pPlayer, pev_armorvalue, 100.0);
					set_pdata_int(pPlayer, m_iKevlar, 2);
					UTIL_AddAccount(pPlayer, -1000);
				}
				else
					print_chat_color(pPlayer, REDCHAT, "金錢不足!");
			}
		}
		default:
		{
		}
	}
	
	menu_destroy(hMenu);
	
	if (hNextMenu >= 0)
	{
		menu_setprop(hNextMenu, MPROP_BACKNAME, "上一頁");
		menu_setprop(hNextMenu, MPROP_NEXTNAME, "下一頁");
		menu_setprop(hNextMenu, MPROP_EXITNAME, "離開");
		menu_display(pPlayer, hNextMenu);
	}

	return PLUGIN_HANDLED;
}

public MenuHandler_GiveWeapon(pPlayer, hMenu, iItem)
{
	new szInfo[8], iDummy, szDummy[32], iDummy2;
	menu_item_getinfo(hMenu, iItem, iDummy, szInfo, charsmax(szInfo), szDummy, charsmax(szDummy), iDummy2);
	
	new sziId[8], szCost[8];
	strtok(szInfo, sziId, charsmax(sziId), szCost, charsmax(szCost), ',', true);
	
	new iId = str_to_num(sziId);
	new iCost = str_to_num(szCost);
	
	if (iId <= 0 || iCost <= 0)
	{
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}
	
	if (get_pdata_int(pPlayer, m_iAccount) < iCost)
	{
		print_chat_color(pPlayer, REDCHAT, "金錢不足!");
		return PLUGIN_HANDLED;
	}
	
	DropWeapons(pPlayer, g_rgiWeaponDefaultSlot[iId] + 1);	// this array was designed for gmsgWeaponList. needs a constant offset.
	fm_give_item(pPlayer, g_rgszWeaponEntity[iId]);
	UTIL_AddAccount(pPlayer, -iCost);
	
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
		RegisterHamFromEntity(Ham_TraceAttack, iPlayer, "HamF_TraceAttack");
		RegisterHamFromEntity(Ham_TraceAttack, iPlayer, "HamF_TraceAttack_Post", 1);
		RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "HamF_TakeDamage");
		RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "HamF_TakeDamage_Post", 1);
		RegisterHamFromEntity(Ham_CS_RoundRespawn, iPlayer, "HamF_CS_RoundRespawn_Post", 1);
		RegisterHamFromEntity(Ham_BloodColor, iPlayer, "HamF_BloodColor")
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
		message_begin(iPlayer ? MSG_ONE : MSG_ALL, get_user_msgid("TeamInfo"), _, Client)
		write_byte(Client)
		write_string(g_rgszTeamName[Color])
		message_end()
	}
	
	message_begin(iPlayer ? MSG_ONE : MSG_ALL, get_user_msgid("SayText"), _, Client)
	write_byte(Client)
	write_string(Message)
	message_end()
	
	if (1 <= Color <= 3)
	{
		message_begin(iPlayer ? MSG_ONE : MSG_ALL, get_user_msgid("TeamInfo"), _, Client)
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
	else if (iMoney < 0)
		iMoney = 0;

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
	if (!get_pcvar_num(cvar_DebugMode))
		return;

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

stock bool:UTIL_CheckPassibility(const Float:vecOrigin[3])	// return true is accessable
{
	static tr;
	if (!tr)
		tr = create_tr2();
	
	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, DONT_IGNORE_MONSTERS, HULL_HEAD, 0, tr);
	
	return !(get_tr2(tr, TR_StartSolid) || get_tr2(tr, TR_AllSolid) || !get_tr2(tr, TR_InOpen));
}

stock DropWeapons(iPlayer, iSlot)
{
	if (iSlot != 1 && iSlot != 2)
		return;
	
	new pItem = get_pdata_cbase(iPlayer, m_rgpPlayerItems[iSlot], 4);
	while (pItem > 0)
	{
		static szClassname[24];
		pev(pItem, pev_classname, szClassname, charsmax(szClassname));
		
		engclient_cmd(iPlayer, "drop", szClassname);
		
		pItem = get_pdata_cbase(pItem, m_pNext, 5);
	}
	
	set_pdata_cbase(iPlayer, m_rgpPlayerItems[0], -1, 4);
}

stock fm_give_item(iPlayer, const szName[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szName));
	
	if (!pev_valid(iEntity))	// NullEnt is created!
		return -1;
	
	new Float:vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	
	set_pev(iEntity, pev_origin, vecOrigin);
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN);
	
	dllfunc(DLLFunc_Spawn, iEntity);
	
	new save = pev(iEntity, pev_solid);
	dllfunc(DLLFunc_Touch, iEntity, iPlayer);
	
	if (pev(iEntity, pev_solid) != save)
		return iEntity;
	
	engfunc(EngFunc_RemoveEntity, iEntity);
	return -1;
}

stock bool:IsObserver(pPlayer)
{
	return !!pev(pPlayer, pev_iuser1);
}

stock NvgScreen(iPlayer, R = 0, B = 0, G = 0, density = 0)	// copy from zombieriot.sma
{
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0, 0, 0}, iPlayer);
	
	if (R || B || G || density)
	{
		write_short(~0);
		write_short(~0);
		write_short(0x0004);
	}
	else
	{
		write_short(0);
		write_short(0);
		write_short(0);
	}
	
	write_byte(R);
	write_byte(B);
	write_byte(G);
	write_byte(density);
	message_end();
}

stock UTIL_RandomNonroleCharacter(iTeam, bool:bHumanPriority = true)
{
	new iCandidateCount = 0, rgiCandidates[33];
	
	for (new i = 1; i <= global_get(glb_maxClients); i++)
	{
		if (!is_user_alive(i))
			continue;
		
		if (bHumanPriority && is_user_bot(i))
			continue;
		
		if (get_pdata_int(i, m_iTeam) != iTeam)
			continue;
		
		if (g_rgPlayerRole[i] != Role_UNASSIGNED)
			continue;
		
		iCandidateCount++;
		rgiCandidates[iCandidateCount] = i;
	}
	
	if (!iCandidateCount)	// include bots this time.
	{
		for (new i = 1; i <= global_get(glb_maxClients); i++)
		{
			if (!is_user_alive(i))
				continue;
			
			if (get_pdata_int(i, m_iTeam) != iTeam)
				continue;
			
			if (g_rgPlayerRole[i] != Role_UNASSIGNED)
				continue;
			
			iCandidateCount++;
			rgiCandidates[iCandidateCount] = i;
		}
	}
	
	if (iCandidateCount > 0)
		return rgiCandidates[random_num(1, iCandidateCount)];
	
	return 0;	// no found.
}

stock RadiusFlash(const Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage)
{
	OrpheuCallSuper(g_pfn_RadiusFlash, vecSrc[0], vecSrc[1], vecSrc[2], pevInflictor, pevAttacker, flDamage);
}

stock ResetMaxSpeed(pPlayer)
{
	OrpheuCallSuper(g_pfn_CBasePlayer_ResetMaxSpeed, pPlayer);
}

stock UTIL_BeamEntPoint(id, const Float:point[3], SpriteId, StartFrame, FrameRate, life, width, noise, red, green, bule, brightness, ScrollSpeed)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, point, 0)
	write_byte(TE_BEAMENTPOINT)
	write_short(id)
	engfunc(EngFunc_WriteCoord, point[0])
	engfunc(EngFunc_WriteCoord, point[1])
	engfunc(EngFunc_WriteCoord, point[2])
	write_short(SpriteId)
	write_byte(StartFrame)			// starting frame
	write_byte(FrameRate)			// frame rate in 0.1's
	write_byte(life)			// life in 0.1's
	write_byte(width)			// line width in 0.1's
	write_byte(noise)			// noise amplitude in 0.01's
	write_byte(red)				// r
	write_byte(green)			// g
	write_byte(bule)			// b
	write_byte(brightness)			// brightness
	write_byte(ScrollSpeed)			// scroll speed in 0.1's
	message_end()
}

stock UTIL_WeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, id);
	write_byte(iAnim);
	write_byte(pev(id, pev_body));
	message_end();
}

stock GetVelocityFromOrigin(Float:origin1[3], Float:origin2[3], Float:speed, Float:velocity[3])
{
	xs_vec_sub(origin1, origin2, velocity)
	new Float:valve = get_distance_f(origin1, origin2)/speed
	
	if (valve <= 0.0)
	return
	
	xs_vec_div_scalar(velocity, valve, velocity)
}

stock bool:fm_is_user_same_team(index1, index2)
{
	return !!(get_pdata_int(index1, m_iTeam) == get_pdata_int(index2, m_iTeam));
}

stock get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	static Float:length
	length = redius * floatcos(vertical_angle, degrees)
	
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}

stock bool:UTIL_PointVisible(const Float:vecSrc[3], const Float:vecEnd[3], iIgnoreType = DONT_IGNORE_MONSTERS, iSkipEntity = 0)
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, iIgnoreType, iSkipEntity, 0);
	get_tr2(0, TR_flFraction, flFraction);
	
	return (flFraction >= 1.0);
}

stock get_aim_origin_vector(iPlayer, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(iPlayer, pev_origin, vOrigin)
	pev(iPlayer, pev_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(iPlayer, pev_v_angle, vAngle)
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock UTIL_GetAliasId(szAlias[])
{
	static Trie:tAliasesIds;
	if( tAliasesIds == Trie:0 )
	{
		tAliasesIds = TrieCreate()
		TrieSetCell(tAliasesIds, "p228",		CSW_P228)
		TrieSetCell(tAliasesIds, "228compact",	CSW_P228)
		TrieSetCell(tAliasesIds, "scout",		CSW_SCOUT)
		TrieSetCell(tAliasesIds, "hegren",		CSW_HEGRENADE)
		TrieSetCell(tAliasesIds, "xm1014",		CSW_XM1014)
		TrieSetCell(tAliasesIds, "autoshotgun",	CSW_XM1014)
		TrieSetCell(tAliasesIds, "mac10",		CSW_MAC10)
		TrieSetCell(tAliasesIds, "aug",			CSW_AUG)
		TrieSetCell(tAliasesIds, "bullpup",		CSW_AUG)
		TrieSetCell(tAliasesIds, "sgren",		CSW_SMOKEGRENADE)
		TrieSetCell(tAliasesIds, "elites",		CSW_ELITE)
		TrieSetCell(tAliasesIds, "fn57",		CSW_FIVESEVEN)
		TrieSetCell(tAliasesIds, "fiveseven",	CSW_FIVESEVEN)
		TrieSetCell(tAliasesIds, "ump45",		CSW_UMP45)
		TrieSetCell(tAliasesIds, "sg550",		CSW_SG550)
		TrieSetCell(tAliasesIds, "krieg550",	CSW_SG550)
		TrieSetCell(tAliasesIds, "galil",		CSW_GALIL)
		TrieSetCell(tAliasesIds, "defender",	CSW_GALIL)
		TrieSetCell(tAliasesIds, "famas",		CSW_FAMAS)
		TrieSetCell(tAliasesIds, "clarion",		CSW_FAMAS)
		TrieSetCell(tAliasesIds, "usp",			CSW_USP)
		TrieSetCell(tAliasesIds, "km45",		CSW_USP)
		TrieSetCell(tAliasesIds, "glock",		CSW_GLOCK18)
		TrieSetCell(tAliasesIds, "9x19mm",		CSW_GLOCK18)
		TrieSetCell(tAliasesIds, "awp",			CSW_AWP)
		TrieSetCell(tAliasesIds, "magnum",		CSW_AWP)
		TrieSetCell(tAliasesIds, "mp5",			CSW_MP5NAVY)
		TrieSetCell(tAliasesIds, "smg",			CSW_MP5NAVY)
		TrieSetCell(tAliasesIds, "m249",		CSW_M249)
		TrieSetCell(tAliasesIds, "m3",			CSW_M3)
		TrieSetCell(tAliasesIds, "12gauge",		CSW_M3)
		TrieSetCell(tAliasesIds, "m4a1",		CSW_M4A1)
		TrieSetCell(tAliasesIds, "tmp",			CSW_TMP)
		TrieSetCell(tAliasesIds, "mp",			CSW_TMP)
		TrieSetCell(tAliasesIds, "g3sg1",		CSW_G3SG1)
		TrieSetCell(tAliasesIds, "d3au1",		CSW_G3SG1)
		TrieSetCell(tAliasesIds, "flash",		CSW_FLASHBANG)
		TrieSetCell(tAliasesIds, "deagle",		CSW_DEAGLE)
		TrieSetCell(tAliasesIds, "nighthawk",	CSW_DEAGLE)
		TrieSetCell(tAliasesIds, "sg552",		CSW_SG552)
		TrieSetCell(tAliasesIds, "krieg552",	CSW_SG552)
		TrieSetCell(tAliasesIds, "ak47",		CSW_AK47)
		TrieSetCell(tAliasesIds, "cv47",		CSW_AK47)
		TrieSetCell(tAliasesIds, "p90",			CSW_P90)
		TrieSetCell(tAliasesIds, "c90",			CSW_P90)

		TrieSetCell(tAliasesIds, "vest",		99)
		TrieSetCell(tAliasesIds, "vesthelm",	99)

		TrieSetCell(tAliasesIds, "defuser",		99)
		TrieSetCell(tAliasesIds, "nvgs",		99)
		TrieSetCell(tAliasesIds, "shield",		99)
		TrieSetCell(tAliasesIds, "buyammo1",	99)
		TrieSetCell(tAliasesIds, "primammo",	99)
		TrieSetCell(tAliasesIds, "buyammo2",	99)
		TrieSetCell(tAliasesIds, "secammo",		99)
	}

	strtolower(szAlias);

	new iId
	if( TrieGetCell(tAliasesIds, szAlias, iId) )
	{
		return iId;
	}
	
	return 0;
}








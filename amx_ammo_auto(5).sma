#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fun>
#include <hamsandwich>

#define PLUGIN	"Unlimited Ammo Auto"
#define VERSION "0.5.0"
#define AUTHOR	"v3x"

#define HE_GRENADE	(1<<0)
#define SMOKE_GRENADE	(1<<1)
#define FLASH_GRENADE	(1<<2)

#define COST_VESTHELM	1000
#define COST_HELM	350
#define COST_VEST	650

#define MODE_DEFAULT	0	// 跟随 ammo_auto
#define MODE_ON		1	// 管理员强制开启
#define MODE_OFF	2	// 管理员强制关闭

new const USAGE[] = ": amx_ammo <nick,#userid> <0|1|2>  (0=off 1=on 2=default)";

new gCvar_flags, gCvar_auto, gCvar_armor, gCvar_free, gCvar_naccess;
new gCvar_khp, gCvar_khphs, gCvar_khpmax;
new g_mode[33];

public plugin_init()
{
	register_plugin(PLUGIN , VERSION , AUTHOR);

	register_concmd("amx_ammo" , "concmd_Ammo" , ADMIN_LEVEL_A , USAGE);
	register_event("CurWeapon" , "event_CurWeapon" , "be" , "1=1");
	RegisterHam(Ham_Spawn , "player" , "fw_Spawn" , 1);

	// 1 = 所有玩家自动无限子弹, 0 = 仅管理员指令指定的玩家
	gCvar_auto  = register_cvar("ammo_auto" , "1");
	// 1 = 出生时自动购买防弹衣+头盔
	gCvar_armor = register_cvar("ammo_auto_armor" , "1");
	// 1 = 自动购买免费(不扣钱), 0 = 按原价扣钱, 钱不够则不买
	gCvar_free  = register_cvar("ammo_armor_free" , "0");
	// 手雷: a=HE b=烟雾 c=闪光, 留空则不发放
	gCvar_flags = register_cvar("ammo_nade_flags" , "abc");
	// 谁能使用本插件的所有功能(无限子弹/手雷/自动买甲/杀人回血): 需要的管理员权限标志
	// 默认 "m" (ADMIN_LEVEL_A, 即能用 amx_ammo 的管理员); 电脑(bot)永远不生效
	// 想只给自己, 就在 users.ini 里给自己一个别人没有的标志并在这里填上; 留空 = 所有真人
	gCvar_naccess = register_cvar("ammo_access" , "m");

	// 杀人回血: 普通击杀回多少血 / 爆头击杀回多少血 / 血量上限, 0 = 关闭
	gCvar_khp    = register_cvar("ammo_kill_hp"    , "15");
	gCvar_khphs  = register_cvar("ammo_kill_hp_hs" , "30");
	gCvar_khpmax = register_cvar("ammo_kill_hp_max" , "100");
	register_event("DeathMsg" , "event_DeathMsg" , "a");

	set_task(0.3 , "check_for_nades" , 0 , _ , _ , "b");
}

// 所有功能共用的权限标志, 由 check_for_nades 每 0.3 秒刷新一次 (避免每次都解析字符串)
new g_nadeNeed;

// 这个玩家能不能使用本插件的功能: 电脑永远不行; 被 amx_ammo 关掉的不行; 其余看管理员权限
stock bool:can_use(id)
{
	if(is_user_bot(id) || g_mode[id] == MODE_OFF)
		return false;

	if(!g_nadeNeed)
		return true;				// 留空 = 所有真人玩家

	return bool:((get_user_flags(id) & g_nadeNeed) != 0);
}

stock bool:has_ammo(id)
{
	if(is_user_bot(id))
		return false;

	switch(g_mode[id])
	{
		case MODE_ON:  return true;
		case MODE_OFF: return false;
	}

	return bool:(get_pcvar_num(gCvar_auto) != 0 && can_use(id));
}

public concmd_Ammo(id , lvl , cid)
{
	if(!cmd_access(id , lvl , cid , 3))
		return PLUGIN_HANDLED;

	new arg1[33] , arg2[8];
	read_argv(1 , arg1 , 32);
	read_argv(2 , arg2 , 7);
	remove_quotes(arg2);

	new pid = cmd_target(id , arg1 , 0);
	if(!pid)
		return PLUGIN_HANDLED;

	if(equali(arg2 , "on") || equal(arg2 , "1"))
		g_mode[pid] = MODE_ON;
	else if(equali(arg2 , "off") || equal(arg2 , "0"))
		g_mode[pid] = MODE_OFF;
	else if(equali(arg2 , "default") || equal(arg2 , "2"))
		g_mode[pid] = MODE_DEFAULT;
	else
	{
		console_print(id , "[AMXX] Usage%s" , USAGE);
		return PLUGIN_HANDLED;
	}

	new pname1[33] , pname2[33];
	get_user_name(id  , pname1 , 32);
	get_user_name(pid , pname2 , 32);

	new bool:s = has_ammo(pid);

	switch(get_cvar_num("amx_show_activity"))
	{
		case 1: client_print(0 , print_chat , "ADMIN: %s unlimited ammo on %s" , s ? "Set" : "Unset" , pname2);
		case 2: client_print(0 , print_chat , "ADMIN %s: %s unlimited ammo on %s" , pname1 , s ? "Set" : "Unset" , pname2);
	}

	return PLUGIN_HANDLED;
}

public event_CurWeapon(id)
{
	if(!is_user_alive(id) || !has_ammo(id))
		return PLUGIN_CONTINUE;

	give_ammo(id , read_data(2) , read_data(3));
	return PLUGIN_CONTINUE;
}

public client_connect(id)
{
	g_mode[id] = MODE_DEFAULT;
	remove_task(id);			// 清掉上一个占用这个位置的玩家遗留的定时任务
}

public client_disconnect(id)
{
	g_mode[id] = MODE_DEFAULT;
	remove_task(id);
}

// ---------- 自动购买防弹衣 + 头盔 ----------
public fw_Spawn(id)
{
	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(get_pcvar_num(gCvar_armor))
		set_task(0.5 , "task_buy_armor" , id);	// 稍等片刻, 避开出生时的装备重置

	return HAM_IGNORED;
}

public task_buy_armor(id)
{
	if(!is_user_connected(id) || !is_user_alive(id) || !can_use(id))
		return;

	new CsArmorType:type;
	new armor = cs_get_user_armor(id , type);

	new cost;
	if(armor >= 100 && type == CS_ARMOR_VESTHELM)
		return;					// 已经满甲+头盔
	else if(armor >= 100 && type == CS_ARMOR_KEVLAR)
		cost = COST_HELM;			// 只差头盔
	else
		cost = COST_VESTHELM;			// 没甲或甲不满, 买整套

	new CsArmorType:buy = CS_ARMOR_VESTHELM;

	if(!get_pcvar_num(gCvar_free))
	{
		new money = cs_get_user_money(id);
		if(money < cost)
		{
			// 钱不够买整套 (比如手枪局只有 $800): 退而求其次, 只买防弹衣
			if(armor < 100 && money >= COST_VEST)
			{
				cost = COST_VEST;
				buy = CS_ARMOR_KEVLAR;
			}
			else
				return;
		}
		cs_set_user_money(id , money - cost);
	}

	cs_set_user_armor(id , 100 , buy);

	new what[24];
	copy(what , 23 , (buy == CS_ARMOR_VESTHELM) ? "Kevlar + Helmet" : "Kevlar");

	if(get_pcvar_num(gCvar_free))
		client_print(id , print_chat , "[AMXX] Auto-bought %s (free)" , what);
	else
		client_print(id , print_chat , "[AMXX] Auto-bought %s ($%d)" , what , cost);
}

// ---------- 杀人回血 ----------
public event_DeathMsg()
{
	new killer = read_data(1);
	new victim = read_data(2);
	new hs     = read_data(3);

	if(!killer || killer == victim)
		return;

	if(!is_user_alive(killer) || !can_use(killer))
		return;

	if(get_user_team(killer) == get_user_team(victim))	// 杀队友不回血
		return;

	new heal = hs ? get_pcvar_num(gCvar_khphs) : get_pcvar_num(gCvar_khp);
	if(heal <= 0)
		return;

	new maxhp = get_pcvar_num(gCvar_khpmax);
	new hp    = get_user_health(killer);

	if(hp >= maxhp)
		return;

	hp += heal;
	if(hp > maxhp)
		hp = maxhp;

	set_user_health(killer , hp);
}

// ---------- 无限子弹 ----------
public give_ammo(id , wpnid , clip)
{
	if(!is_user_alive(id))
		return;

	if(	wpnid==CSW_C4		||
		wpnid==CSW_KNIFE	||
		wpnid==CSW_HEGRENADE	||
		wpnid==CSW_SMOKEGRENADE	||
		wpnid==CSW_FLASHBANG	)
			return;

	if(!clip)
	{
		new weapname[33];
		get_weaponname(wpnid , weapname , 32);

		new wpn = -1;
		while((wpn = find_ent_by_class(wpn , weapname)) != 0)
		{
			if(id == entity_get_edict(wpn , EV_ENT_owner))
			{
				cs_set_weapon_ammo(wpn , maxclip(wpnid));
				break;
			}
		}
	}
}

// ---------- 自动补手雷 (全局一个定时器, 针对每个有效玩家) ----------
public check_for_nades()
{
	new buffer[16];
	get_pcvar_string(gCvar_naccess , buffer , 15);
	g_nadeNeed = read_flags(buffer);

	new flags = nade_flags();
	if(!flags)
		return;

	new players[32] , num , id;
	get_players(players , num , "ach");	// 存活, 非 HLTV

	for(new i = 0; i < num; i++)
	{
		id = players[i];
		if(!can_use(id))
			continue;

		if((flags & HE_GRENADE) && !user_has_weapon(id , CSW_HEGRENADE))
			give_item(id , "weapon_hegrenade");
		if((flags & SMOKE_GRENADE) && !user_has_weapon(id , CSW_SMOKEGRENADE))
			give_item(id , "weapon_smokegrenade");
		if((flags & FLASH_GRENADE) && !user_has_weapon(id , CSW_FLASHBANG))
			give_item(id , "weapon_flashbang");
	}
}

// ---------- 扔完雷后继续拿着雷 ----------
// 扔出后: 0.1 秒补一颗同类型的雷 (等游戏先扣完弹药), 1.0 秒后强制切回这颗雷
// (游戏大约 0.75 秒时会自动切走, 所以最后一步放在它之后)
public grenade_throw(id , greindex , wId)
{
	if(!is_user_alive(id) || !can_use(id))
		return;

	new flag;
	switch(wId)
	{
		case CSW_HEGRENADE:	flag = HE_GRENADE;
		case CSW_SMOKEGRENADE:	flag = SMOKE_GRENADE;
		case CSW_FLASHBANG:	flag = FLASH_GRENADE;
		default:		return;
	}

	if(!(nade_flags() & flag))
		return;

	new params[1];
	params[0] = wId;

	set_task(0.1 , "task_regive_nade"  , id , params , 1);
	set_task(1.0 , "task_select_nade"  , id , params , 1);
}

public task_regive_nade(params[] , id)
{
	if(!is_user_alive(id))
		return;

	new wId = params[0];

	if(!user_has_weapon(id , wId))
	{
		new name[32];
		get_weaponname(wId , name , 31);
		give_item(id , name);
	}
	else if(cs_get_user_bpammo(id , wId) < 1)
		cs_set_user_bpammo(id , wId , 1);
}

public task_select_nade(params[] , id)
{
	if(!is_user_alive(id))
		return;

	new wId = params[0];

	if(!user_has_weapon(id , wId))
		return;

	new clip , ammo;
	if(get_user_weapon(id , clip , ammo) == wId)
		return;					// 已经拿着了

	new name[32];
	get_weaponname(wId , name , 31);
	engclient_cmd(id , name);
}

stock maxclip(wpnid)
{
	new ca = 0;

	switch (wpnid)
	{
		case CSW_P228 : ca = 13;
		case CSW_SCOUT : ca = 10;
		case CSW_XM1014 : ca = 7;
		case CSW_MAC10 : ca = 30;
		case CSW_AUG : ca = 30;
		case CSW_ELITE : ca = 15;
		case CSW_FIVESEVEN : ca = 20;
		case CSW_UMP45 : ca = 25;
		case CSW_SG550 : ca = 30;
		case CSW_GALI : ca = 35;
		case CSW_FAMAS : ca = 25;
		case CSW_USP : ca = 12;
		case CSW_GLOCK18 : ca = 20;
		case CSW_AWP : ca = 10;
		case CSW_MP5NAVY : ca = 30;
		case CSW_M249 : ca = 100;
		case CSW_M3 : ca = 8;
		case CSW_M4A1 : ca = 30;
		case CSW_TMP : ca = 30;
		case CSW_G3SG1 : ca = 20;
		case CSW_DEAGLE	: ca = 7;
		case CSW_SG552 : ca = 30;
		case CSW_AK47 : ca = 30;
		case CSW_P90 : ca = 50;
	}
	return ca;
}

stock nade_flags()
{
	new buffer[8];
	get_pcvar_string(gCvar_flags , buffer , 7);

	return read_flags(buffer);
}

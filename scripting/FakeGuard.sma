#include <amxmodx>
#include <fakemeta>
#include <ColorChat>
#include <amxmisc>

new const PLUGIN[]=		"FakeGuard"
new const VERSION[]=		"2.03c"
new const AUTHOR[]=		"RevCrew"

#include "include/FakeGuard/globals.inl"
#include "include/FakeGuard/stock.inl"
#include "include/FakeGuard/fakeip.inl"
#include "include/FakeGuard/recaptha.inl"

const grenade_he = 0;
const grenade_fl = 1;
const grenade_sm = 2;

stock Show_VGUIMenu(pev, MenuType, BitMask)
{
	if(!gmsgVGUIMenu)
		gmsgVGUIMenu = get_user_msgid("VGUIMenu")
	
	message_begin(MSG_ONE, gmsgVGUIMenu, NULL, pev);
	write_byte(MenuType);
	write_short(BitMask);
	write_char(-1);
	write_byte(0);
	write_string(" ");
	message_end();	
}

public plugin_precache()
{
	static const DIR[] = "addons/amxmodx/logs/FakeGuard/"
	static const DIR2[] = "addons/amxmodx/data/FG/"
	
	if(!dir_exists(DIR))
		mkdir(DIR);
	if(!dir_exists(DIR2))
		mkdir(DIR2);
	
	new configsDir[64];
	get_configsdir(configsDir, 63);
	
	g_Cvars[CVAR_SETINFO] =			register_cvar("fakeguard_check_setinfo", "1")
	g_Cvars[CVAR_FAKECVAR] =		register_cvar("fakeguard_check_cvar", "1")
	
	g_Cvars[CVAR_SPAM_ON] =			register_cvar("fakeguard_spam_block", "1")
	g_Cvars[CVAR_SPAM_PUNISH] = 		register_cvar("fakeguard_spam_punish", "kick %userid% SpamBlock")
	
	g_Cvars[CVAR_FAKEIP_COUNT] =		register_cvar("fakeguard_fakeip_count", "1")
	g_Cvars[CVAR_FAKEIP_PUNISH] = 		register_cvar("fakeguard_fakeip_punish", "kick %userid% FakeIP")
	
	g_Cvars[CVAR_RECAPTCHA] = 		register_cvar("fakeguard_recaptcha", "1")
	g_Cvars[CVAR_RECAPTCHA_CHOOSE] = 	register_cvar("fakeguard_recaptcha_choose", "1")
	g_Cvars[CVAR_RECAPTCHA_SAVE] = 		register_cvar("fakeguard_recaptcha_save", "1")
	g_Cvars[CVAR_RECAPTCHA_TIME] = 		register_cvar("fakeguard_recaptcha_time", "15.0")
	g_Cvars[CVAR_RECAPTCHA_PUNISH] = 	register_cvar("fakeguard_recaptcha_punish", "kick %userid% InvalidReCaptcha")
	
	server_cmd("exec %s/fakeguard.cfg", configsDir);
	server_exec()
	
	new Array: g_grenades[3];
	ArrayPushCell(g_grenades[grenade_he], 123);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_array_setinfo = 	ArrayCreate(StructSetinfo);
	g_array_fakecvar = 	ArrayCreate(StructFakeCvar);
	g_array_spam = 		ArrayCreate(StructSpam);
	
	g_trie_fakeip = TrieCreate();
	
	ReadIniFile();
	
	if(get_pcvar_num(g_Cvars[CVAR_SPAM_ON]))
	{
		register_clcmd("say", "HookSay")
		register_clcmd("say_team", "HookSay")
	}
	
	RegisterReCaptha();
}
public plugin_end()
{
	ArrayDestroy(g_array_setinfo)
	ArrayDestroy(g_array_fakecvar)
	ArrayDestroy(g_array_spam)
	
	TrieDestroy(g_trie_fakeip);
	TrieDestroy(RealPlayers)
}
public client_connect(id)
{
	ResetPlayer(id);
	
	if(is_user_hltv(id))
		return;
	
	new cell
	if( (TrieGetCell(RealPlayers, RayID[id], cell) && get_pcvar_num(g_Cvars[CVAR_RECAPTCHA_SAVE])) || g_steam[id])
		Captcha[id] = true;
	
	CheckFakeIp(id)
	
	if(get_pcvar_num(g_Cvars[CVAR_SETINFO]) && !g_steam[id])
		CheckSetinfo(id)
	
	if(!get_pcvar_num(g_Cvars[CVAR_SPAM_ON]))
		return;
	
	new name[32];
	get_user_name(id, name, charsmax(name))
	
	if(SearchSpam(name))
	{
		PunishSpam(id, name)
	}
	
	
}
public HookSay(id)
{
	new message[196];
	read_args(message, charsmax(message))
	
	if( !message[0] || strlen(message) <= 0 )
		return PLUGIN_CONTINUE;
	
	if(g_check_spam[id] > 5)
		return PLUGIN_CONTINUE;
	
	g_check_spam[id] ++;
	
	if(SearchSpam(message))
	{
		PunishSpam(id, message)
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}
public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id)) return PLUGIN_CONTINUE;
	
	if(get_pcvar_num(g_Cvars[CVAR_FAKECVAR]) && !g_steam[id])
		set_task(1.0, "CheckCvar", id+333,_,_,"b")
		
	return PLUGIN_CONTINUE
}
public client_disconnect(id)
{
	RemoveFakeIP(id)
}

CheckSetinfo(id)
{
	new data[StructSetinfo];
	
	new value[32], len
	new size = ArraySize(g_array_setinfo)
	for(new i; i< size; i++)
	{
		ArrayGetArray(g_array_setinfo, i, data);
		
		get_user_info(id, data[SS_SETINFO],value, 31);
		
		len = strlen(value)
		
		if( (equali(data[SS_VALUE], "NOT_NULL") && len > 0) || \
		(equali(data[SS_VALUE], "NULL") && !len) ||\
		(equali(data[SS_VALUE], value) && len > 0) )
		{
			static cmd[64];
			copy(cmd, charsmax(cmd), data[SS_PUNISH])
				
			static uid[8], ip[22];
			formatex(uid, charsmax(uid), "#%d", get_user_userid(id))
			get_user_ip(id, ip, charsmax(ip), 1)
				
			replace_all(cmd, charsmax(cmd), "%userid%", uid)
			replace_all(cmd, charsmax(cmd), "%ip%", ip)
				
			new name[32];
			get_user_name(id, name, charsmax(name))
			PrintMessage("Player %s punish by SETINFO ( IP ^"%s^", Info ^"%s^", Value ^"%s^" ) [CMD:%s]", \
			name,ip, data[SS_SETINFO], value, cmd)
				
			server_cmd(cmd);
			
		}
	}
}
public CheckCvar(id)
{
	if(id>32)
		id-=333;
	
	if(!is_user_connected(id))
		return;
	
	new from = g_total[id];
	g_total[id] +=5;
	
	new size = ArraySize(g_array_fakecvar) 
	if(g_total[id] >= size)
	{
		g_total[id] = size - 1;
		remove_task(id+333)
	}
	
	new data[StructFakeCvar]
	for(new i = from; i<= g_total[id]; i++)
	{
		ArrayGetArray(g_array_fakecvar, i, data);
		query_client_cvar(id, data[FC_CVAR], "query_cvar_result");
	}
}
public query_cvar_result(id, cvar[], value[])
{
	new data[StructFakeCvar]
	ArrayGetArray(g_array_fakecvar, g_check_cvar[id], data);
		
	if(equali(cvar, data[FC_CVAR]))
	{
			
		if( (equali(data[FC_VALUE], "BADCVAR") && containi(value, "bad") != -1) ||\
		equali(data[FC_VALUE], value) )
		{
			static cmd[64];
			copy(cmd, charsmax(cmd), data[FC_PUNISH])
				
			static uid[8], ip[22];
			formatex(uid, charsmax(uid), "#%d", get_user_userid(id))
			get_user_ip(id, ip, charsmax(ip), 1)
				
			replace_all(cmd, charsmax(cmd), "%userid%", uid)
			replace_all(cmd, charsmax(cmd), "%ip%", ip)
				
			new name[32];
			get_user_name(id, name, charsmax(name))
			PrintMessage("Player %s punish by FAKECVAR ( IP ^"%s^", Cvar ^"%s^", Value ^"%s^" )[CMD:%s]", \
			name,ip, cvar, value,cmd)
				
			server_cmd(cmd);
		}
		
	}
	
	g_check_cvar[id] ++
}
bool:SearchSpam( string[] )
{
	new end = ArraySize(g_array_spam);
	
	strtolower(string);
	
	new data[StructSpam]
	for(new i; i<end; i++)
	{
		ArrayGetArray(g_array_spam, i, data)
		
		if(containi(string, data[SP_VALUE]) != -1)
			return true;
	}
	
	return false
}
PunishSpam(id, const string[])
{
	static cmd[64];
	get_pcvar_string(g_Cvars[CVAR_SPAM_PUNISH], cmd, charsmax(cmd))
				
	static uid[8], ip[22];
	formatex(uid, charsmax(uid), "#%d", get_user_userid(id))
	get_user_ip(id, ip, charsmax(ip), 1)
		
	replace_all(cmd, charsmax(cmd), "%userid%", uid)
	replace_all(cmd, charsmax(cmd), "%ip%", ip)
				
	new name[32];
	get_user_name(id, name, charsmax(name))
	PrintMessage("Player %s punish by SPAMBLOCK ( IP ^"%s^", Value ^"%s^" )[CMD:%s]", \
	name,ip, string,cmd)
				
	server_cmd(cmd);
}
GetRayID(id)
{
	static authid[33], steam = 0;
	
	steam = is_user_steam(id);
	get_user_authid(id, authid, charsmax(authid))
	
	static cmd[32], md[34];
	
	formatex(cmd, charsmax(cmd), "%d%s%d", steam, authid, steam);
	md5(cmd, md);
	
	copy(RayID[id],RAYID_LEN, md)
}
public ShowReMenu(id) {
	if(id > 32)
		id -= (TASK_RECAPTHA +1);
	
	new diff = floatround(ReTime[id]-get_gametime(), floatround_ceil)
	
	if(diff < 0)
	{
		show_menu(id, 0, "^n", 1);
		return;
	}
	
	new menu[256];
	formatex(menu, charsmax(menu), "\y[ReCaptcha]  РџСЂРѕРІРµСЂРєР°...^n\wРќР°Р¶РјРёС‚Рµ РєР»Р°РІРёС€Сѓ <1> РґР»СЏ Р°РІС‚РѕСЂРёР·Р°С†РёРё^nР’Р°С€ RayID:\r %s\w^nРћСЃС‚Р°Р»РѕСЃСЊ\y %d СЃРµРєСѓРЅРґ^n^n\y1.\w РќР°Р¶РјРё РјРµРЅСЏ",\
	RayID[id], diff)
	show_menu(id, KeysReMenu, menu, -1, "ReMenu") // Display menu

	set_task(1.0, "ShowReMenu", id+TASK_RECAPTHA+1);
}
public PressedReMenu(id, key) {

	switch (key) {
		case 0: { // 1
			
			show_menu(id, 0, "^n", 1);
			
			remove_task(id+TASK_RECAPTHA)
			remove_task(id+(TASK_RECAPTHA+1))
			
			Captcha[id] = true;
			
			TrieSetCell(RealPlayers, RayID[id], 0);
			write_file(FILE,RayID[id], - 1);
			
			client_print_color(id, RED, "^1[^4FakeGuard^1] Р’С‹ ^3СѓСЃРїРµС€РЅРѕ РёРґРµРЅС‚РёС„РёС†РёСЂРѕРІР°РЅС‹ ^1РЅР° СЃРµСЂРІРµСЂРµ РєР°Рє ^4РёРіСЂРѕРє^1.Р’Р°С€ ^4RayID^1:^3%s", RayID[id])
			set_task(2.0, "ReCaptchaUnlock", id+431)
		}
	}
}

#if defined _recaptha_included
    #endinput
#endif

#define _recaptha_included

#include <amxmodx>

#define KeysReMenu (1<<0) // Keys: 1
#define TASK_RECAPTHA 1133

const VGUIMenu = 114;
const OLDMenu = 96;

new const FILE[] = "addons/amxmodx/data/FG/recaptcha.txt"

RegisterReCaptha()
{
	register_message(VGUIMenu, "ShowCaptcha");
	register_message(OLDMenu, "ShowCaptcha");
	
	register_menucmd(register_menuid("ReMenu"), KeysReMenu, "PressedReMenu")
	
	RealPlayers = TrieCreate();
	
	new bool: need_read = true;
	if(!file_exists(FILE))
	{
		need_read = false;
		fclose(fopen(FILE,"w"));
	}
	
	if(!need_read)
		return;
	
	new File = fopen(FILE, "rt"), Data[25];
	while(!feof(File))
	{
		fgets(File, Data, charsmax(Data)), trim(Data);
		if(!Data[0] || Data[0] == ';') continue;
		TrieSetCell(RealPlayers, Data, 0);
	}
	fclose(File);
}

public ShowCaptcha(const iMsg, const iMsgDest, const iClient)
{
	if(Captcha[iClient] || !get_pcvar_num(g_Cvars[CVAR_RECAPTCHA]))
		return PLUGIN_CONTINUE
	
	if(iMsg == OLDMenu)
	{
		static szArg4[20]; get_msg_arg_string(4, szArg4, charsmax(szArg4));
		if(contain(szArg4, "Team_Select") == -1) return PLUGIN_HANDLED;
	}
	else if(get_msg_arg_int(1) != 2) return PLUGIN_HANDLED;
	set_pdata_int(iClient, 205, 0);
	
	g_MenuMsg[iClient] = iMsg;
	
	new Float: f = get_pcvar_float(g_Cvars[CVAR_RECAPTCHA_TIME]);
	
	if( f <= 10.0) f = 10.0	
	set_task(f, "KickPlayer", iClient+TASK_RECAPTHA);
		
	ReTime[iClient] = get_gametime() +f;		
		
	ShowReMenu(iClient);
		
	return PLUGIN_HANDLED;
}
public ReCaptchaUnlock(id)
{
	id -=431
	
	switch (get_pcvar_num(g_Cvars[CVAR_RECAPTCHA_CHOOSE]))
	{
		case 0:		force_team_join(id, g_MenuMsg[id])
		default:	engclient_cmd(id, "jointeam", "0");
	}
	
	
}
public KickPlayer(id)
{
	if(id > 32)
		id -= (TASK_RECAPTHA);
	
	if(!is_user_connected(id))
		return;
	
	static cmd[64];
	get_pcvar_string(g_Cvars[CVAR_RECAPTCHA_PUNISH], cmd, charsmax(cmd))
				
	static uid[8], ip[22];
	formatex(uid, charsmax(uid), "#%d", get_user_userid(id))
	get_user_ip(id, ip, charsmax(ip), 1)
				
	replace_all(cmd, charsmax(cmd), "%userid%", uid)
	replace_all(cmd, charsmax(cmd), "%ip%", ip)
		
	new name[32];
	get_user_name(id, name, charsmax(name))
	PrintMessage("Player %s punish by ReCaptha ( IP ^"%s^", RayID ^"%s^" ) [CMD:%s]", \
	name,ip, RayID[id], cmd)
				
	server_cmd(cmd);
}

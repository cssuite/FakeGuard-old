#if defined _stock_included
    #endinput
#endif

#define _stock_included

#include <amxmodx>

stock ReadIniFile()
{
	new f = fopen("addons/amxmodx/configs/fakeguard.ini", "r")
	
	if(!f)
		return PrintMessage("File [FakeGuard.ini] not found in configs/");
	
	static filedata[256];
	
	new const START[][] = 
	{
		"[SETINFO]",
		"[FAKECVAR]",
		"[SPAM]"
	}
	
	new len[sizeof(START)];
	for(new i; i<sizeof(START); i++)
	{
		len[i] = strlen(START[i])
	}
	
	new bool:index[3];
	new bool:next = false;
	static data1[StructSetinfo], data2[StructFakeCvar], data3[StructSpam]
	
	while(!feof(f))
	{
		fgets(f, filedata, charsmax(filedata))
		trim(filedata)
		
		if(!filedata[0] || filedata[0] == '#')
			continue;
		
		for(new i; i<sizeof(START); i++)
			if(equal(filedata, START[i], len[i]))
			{
				index[i] = !index[i];
				next = true;
			}
			
		if(next)
		{
			next = false;
			continue;
		}
	
		if(index[0])
		{
			parse(filedata, data1[SS_SETINFO], 31, data1[SS_VALUE], 31, data1[SS_PUNISH], 63)
			
			remove_quotes(data1[SS_SETINFO])
			remove_quotes(data1[SS_VALUE])
			remove_quotes(data1[SS_PUNISH])
			
			ArrayPushArray(g_array_setinfo,data1)
		}
		if(index[1])
		{
			parse(filedata, data2[FC_CVAR], 31, data2[FC_VALUE], 31, data2[FC_PUNISH], 63)
			
			remove_quotes(data2[FC_CVAR])
			remove_quotes(data2[FC_VALUE])
			remove_quotes(data2[FC_PUNISH])
			
			ArrayPushArray(g_array_fakecvar,data2)
		}
		if(index[2])
		{
			remove_quotes(filedata)
			copy(data3[SP_VALUE], 31, filedata)
			
			ArrayPushArray(g_array_spam,data3)
		}
	}
	
	return fclose(f);
}
stock ResetPlayer(id)
{
	g_total[id] = 0;
	g_check_spam[id] = 0;
	
	GetRayID(id)
	ReTime[id] = 0.0
	Captcha[id] = false;
	g_MenuMsg[id] = 0;
	g_check_cvar[id] = 0;
	g_steam[id] = bool:is_user_steam(id);
}
stock PrintMessage(const szMessage[], any:...)
{
	static szMsg[196];
	vformat(szMsg, charsmax(szMsg), szMessage, 2);
	
	static LogDat[16],LogFile[64]
	get_time("%Y_%m_%d", LogDat, 15);
	
	get_basedir(LogFile,63)
	formatex(LogFile,63,"%s/logs/FakeGuard/Log_%s.log",LogFile,LogDat)
	log_to_file(LogFile,"[%s] %s",PREFIX,szMsg)
	
	return 0;
}
stock bool: is_user_steam(client)
{
    new dp_pointer;
	
    if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider")))
    {
        server_cmd("dp_clientinfo %d", client);
        server_exec();
        return bool:((get_pcvar_num(dp_pointer) == 2) ? 1 : 0);
    }
	
    return bool:0;
}
stock force_team_join(id, menu_msgid) 
{
	static msg_block
	
	msg_block = get_msg_block(menu_msgid)
	set_msg_block(menu_msgid, BLOCK_SET)
	engclient_cmd(id, "jointeam", "5")
	engclient_cmd(id, "joinclass", "2")
	set_msg_block(menu_msgid, msg_block)
}

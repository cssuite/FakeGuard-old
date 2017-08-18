#if defined _fakeip_included
    #endinput
#endif

#define _fakeip_included

#include <amxmodx>

CheckFakeIp(id)
{
	new value = get_pcvar_num(g_Cvars[CVAR_FAKEIP_COUNT])
	
	if(!value)
		return;
	
	static ip[IP_SIZE]; get_user_ip(id, ip, sizeof(ip) - 1, .without_port=1)
	
	new cell = 1;
	if(TrieGetCell(g_trie_fakeip, ip, cell))
	{
		if(++cell > value)
		{
			TrieDeleteKey(g_trie_fakeip, ip);
			PunishFakeIp(id, cell)
			return;
		}
		
		TrieDeleteKey(g_trie_fakeip, ip);
	}
	
	TrieSetCell(g_trie_fakeip, ip, cell);
}
RemoveFakeIP(id)
{
	static ip[IP_SIZE]; get_user_ip(id, ip, sizeof(ip) - 1, .without_port=1);
	static cell
	if(TrieGetCell(g_trie_fakeip, ip, cell))
	{
		TrieDeleteKey(g_trie_fakeip, ip);
		
		if(--cell < 1)
			return;
	}

	TrieSetCell(g_trie_fakeip, ip, cell);
}
PunishFakeIp(id, const value)
{
	static cmd[64];
	get_pcvar_string(g_Cvars[CVAR_FAKEIP_PUNISH], cmd, charsmax(cmd))
				
	static uid[8], ip[22];
	formatex(uid, charsmax(uid), "#%d", get_user_userid(id))
	get_user_ip(id, ip, charsmax(ip), 1)
		
	replace_all(cmd, charsmax(cmd), "%userid%", uid)
	replace_all(cmd, charsmax(cmd), "%ip%", ip)
				
	new name[32];
	get_user_name(id, name, charsmax(name))
	PrintMessage("Player %s punish by FAKEIP ( IP ^"%s^", Value ^"%d^" )[CMD:%s]", \
	name,ip, value,cmd)
				
	server_cmd(cmd);
}

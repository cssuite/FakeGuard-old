#if defined _glob_included
    #endinput
#endif

#define _glob_included

new const PREFIX[] = 	"FakeGuard"

#define IP_SIZE 18
#define is_valid_player(%0) (1<=%0<=32)

enum _:StructSetinfo
{
	SS_SETINFO[32],
	SS_VALUE[32],
	SS_PUNISH[64]
}

enum _:StructFakeCvar
{
	FC_CVAR[32],
	FC_VALUE[32],
	FC_PUNISH[64]
}

enum _:StructSpam
{
	SP_VALUE[32]
}

new Array:g_array_setinfo, Array:g_array_fakecvar, Array:g_array_spam
new g_total[33];

enum Cvars
{
	CVAR_SETINFO,
	CVAR_FAKECVAR,
	
	CVAR_SPAM_ON,
	CVAR_SPAM_PUNISH,
	
	CVAR_FAKEIP_COUNT,
	CVAR_FAKEIP_PUNISH,
	
	CVAR_RECAPTCHA,
	CVAR_RECAPTCHA_CHOOSE,
	CVAR_RECAPTCHA_SAVE,
	CVAR_RECAPTCHA_TIME,
	CVAR_RECAPTCHA_PUNISH
}
new g_Cvars[Cvars]
new g_check_spam[33]

new Trie:g_trie_fakeip

const RAYID_LEN = 11
new RayID[33][12];
new Float:ReTime[33], bool:Captcha[33], Trie:RealPlayers

new g_MenuMsg[33], g_check_cvar[33], bool:g_steam[33];

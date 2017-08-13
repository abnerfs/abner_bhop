#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required 
#define BHOPCHECK g_Bhop[client] || GetConVarBool(hAutoBhop)
#define PLUGIN_ENABLED GetConVarBool(hBhop);
#define PLUGIN_VERSION "3.0"


ConVar hBhop;
ConVar hAutoBhop;
ConVar hFlag;


bool CSGO = false;
int WATER_LIMIT;

bool g_Bhop[MAXPLAYERS+1];

/*
	-Added sm_bhopplayer admin command to enable/disable bhop in a player.
	-Added convar abner_bhop_flag to restrict auto bhop to a specific flag
	-Config file changed to abner_bhop.cfg 
	-Convar names changed

*/


public Plugin myinfo =
{
	name = "[CSS/CS:GO] AbNeR BHOP",
	author = "AbNeR_CSS",
	description = "Auto BHOP",
	version = PLUGIN_VERSION,
	url = "www.tecnohardclan.com"
}

public void OnPluginStart()
{       
	CreateConVar("abnerbhop_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hBhop = CreateConVar("abner_bhop", "1", "Enable/disable plugin", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hAutoBhop = CreateConVar("abner_autobhop", "1", "Enable/Disable auto bhop to everyone", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hFlag = CreateConVar("abner_bhop_flag", "z", "Admin flag that have autobhop enabled", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	AutoExecConfig(true, "abner_bhop");
	
	RegAdminCmd("sm_bhopplayer", CommandBhop, ADMFLAG_SLAY);
	
	char theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
    (CSGO = StrEqual(theFolder, "csgo")) ? 
		(WATER_LIMIT = 2) : 
		(WATER_LIMIT = 1);

	if(GetConVarInt(hBhop) == 1) BhopOn();

	
	for(int i  = 1;i <= MaxClients;i++)
	{
		if(IsValidClient(i))
			OnClientPutInServer(i);
	}
}


bool CheckFlag(int client)
{
	char flag[100];
	GetConVarString(g_Imunidade, flag, sizeof(flag));
	return (GetUserFlagBits(client) | ReadFlagString(flag)) != 0 ? true : false;
}


public void OnClientPutInServer(int client)
{
	if(!PLUGIN_ENABLED)
		return;
		
	g_Bhop[client] = CheckFlag(client);
	if(!CSGO)
		SDKHook(client, SDKHook_PreThink, PreThink);
}

public Action PreThink(int client)
{
	if(!PLUGIN_ENABLED)
		return Plugin_Continue;
		
	if(IsValidClient(client) && IsPlayerAlive(client) && BHOPCHECK)
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0); 
	}
	return Plugin_Continue;
}

void BhopOn()
{
	if(CSGO)
	{
		SetCvar("sv_enablebunnyhopping", "1"); 
		SetCvar("sv_staminamax", "0");
		SetCvar("sv_airaccelerate", "2000");
		SetCvar("sv_staminajumpcost", "0");
		SetCvar("sv_staminalandcost", "0");
	}
	else
	{
		SetCvar("sv_enablebunnyhopping", "1");
		SetCvar("sv_airaccelerate", "2000");
	}
}


void BhopOff()
{
	if(CSGO)
	{
		SetDefaultValue("sv_enablebunnyhopping"); 
		SetDefaultValue("sv_staminamax");
		SetDefaultValue("sv_airaccelerate");
		SetDefaultValue("sv_staminajumpcost");
		SetDefaultValue("sv_staminalandcost");
	}
	else
	{
		SetCvar("sv_enablebunnyhopping");
		SetCvar("sv_airaccelerate");
	}
}

stock void SetDefaultValue(char[] scvar){
	ConVar cvar = FindConVar(scvar);
	char szDefault[100];
	cvar.GetDefault(szDefault, sizeof(szDefault));
	SetConVarString(cvar, szDefault, true);
}


stock void SetCvar(char[] scvar, char[] svalue)
{
	ConVar cvar = FindConVar(scvar);
	SetConVarString(cvar, svalue, true);
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!PLUGIN_ENABLED)
		return Plugin_Continue;
		
	if(BHOPCHECK) 
		if (IsPlayerAlive(client) && buttons & IN_JUMP) //Check if player is alive and is in pressing space
			if(!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND)) //Check if is not in ladder and is in air
				if(waterCheck(client) < WATER_LIMIT)
					buttons &= ~IN_JUMP; 
	return Plugin_Continue;
}

int waterCheck(int client)
{
	int index = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	return index;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}






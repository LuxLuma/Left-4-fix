/*  
*    Fixes for gamebreaking bugs and stupid gameplay aspects
*    Copyright (C) 2020  LuxLuma		acceliacat@gmail.com
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#pragma newdecls required


#define DEBUG 0

#define GAMEDATA "survivor_afk_fix"
#define PLUGIN_VERSION	"1.0"

#if DEBUG
Handle hAFKSDKCall;
#endif

Handle hSetHumanSpecSDKCall;
Handle hSetObserverTarget;

bool g_bShouldFixAFK = false;
int g_iSurvivorBot;
bool g_bShouldIgnore = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2 && GetEngineVersion() != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1/2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2]Survivor_AFK_Fix",
	author = "Lux",
	description = "Fixes survivor going AFK game function.",
	version = PLUGIN_VERSION,
	url = "https://github.com/LuxLuma/Left-4-fix/tree/master/left%204%20fix/survivors/survivor_afk_fix"
};

public void OnPluginStart()
{
	CreateConVar("survivor_afk_fix_ver", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	hSetObserverTarget = DHookCreateFromConf(hGamedata, "CTerrorPlayer::SetObserverTarget");
	if(hSetObserverTarget == null)
		SetFailState("Failed to make hook for 'CTerrorPlayer::SetObserverTarget'");
	
	Handle hDetour;
	hDetour = DHookCreateFromConf(hGamedata, "CTerrorPlayer::GoAwayFromKeyboard");
	if(!hDetour)
		SetFailState("Failed to find 'CTerrorPlayer::GoAwayFromKeyboard' signature");
	
	if(!DHookEnableDetour(hDetour, false, OnGoAFKPre))
		SetFailState("Failed to detour 'CTerrorPlayer::GoAwayFromKeyboard'");
	if(!DHookEnableDetour(hDetour, true, OnGoAFKPost))
		SetFailState("Failed to detour 'CTerrorPlayer::GoAwayFromKeyboard'");
	
	hDetour = DHookCreateFromConf(hGamedata, "SurvivorBot::SetHumanSpectator");
	if(!hDetour)
		SetFailState("Failed to find 'SurvivorBot::SetHumanSpectator' signature");
	
	if(!DHookEnableDetour(hDetour, false, OnSetHumanSpectatorPre))
		SetFailState("Failed to detour 'SurvivorBot::SetHumanSpectator'");
	
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "SurvivorBot::SetHumanSpectator"))
		SetFailState("Error finding the 'SurvivorBot::SetHumanSpectator' signature.");
		
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hSetHumanSpecSDKCall = EndPrepSDKCall();
	if(hSetHumanSpecSDKCall == null)
		SetFailState("Unable to prep SDKCall 'SurvivorBot::SetHumanSpectator'");
	
	#if DEBUG
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard"))
		SetFailState("Error finding the 'CTerrorPlayer::GoAwayFromKeyboard' signature.");
		
	hAFKSDKCall = EndPrepSDKCall();
	if(hAFKSDKCall == null)
		SetFailState("Unable to prep SDKCall 'CTerrorPlayer::GoAwayFromKeyboard'");
	
	RegAdminCmd("sm_afktest", AFKTEST, ADMFLAG_ROOT);
	#endif
	
	delete hGamedata;
}

#if DEBUG
public Action AFKTEST(int client, int args)
{
	if(client == 0)
		return Plugin_Handled;
	
	SDKCall(hAFKSDKCall, client);
	return Plugin_Handled;
}
#endif

public void OnClientPutInServer(int client)
{
	if(!IsFakeClient(client))
	{
		DHookEntity(hSetObserverTarget, false, client, _, OnSetObserverTargetPre);
	}
	else if(g_bShouldFixAFK)
	{
		g_iSurvivorBot = client;
	}
}

public MRESReturn OnGoAFKPre(int pThis, Handle hReturn)
{
	if(g_bShouldFixAFK)
		LogError("Something wentwrong here 'CTerrorPlayer::GoAwayFromKeyboard' :(");
	
	g_bShouldFixAFK = true;
}

public MRESReturn OnSetHumanSpectatorPre(int pThis, Handle hParams)
{
	if(g_bShouldIgnore)
		return MRES_Ignored;
	
	if(!g_bShouldFixAFK)
		return MRES_Ignored;
	
	if(g_iSurvivorBot < 1)
		return MRES_Ignored;
	
	return MRES_Supercede;
}

public MRESReturn OnSetObserverTargetPre(int pThis, Handle hReturn, Handle hParams)
{
	if(!g_bShouldFixAFK)
		return MRES_Ignored;
	
	if(g_iSurvivorBot < 1)
		return MRES_Ignored;
	
	DHookSetParam(hParams, 1, g_iSurvivorBot);
	return MRES_ChangedHandled;
}

public MRESReturn OnGoAFKPost(int pThis, Handle hReturn)
{
	if(g_bShouldFixAFK && g_iSurvivorBot > 1)
	{
		g_bShouldIgnore = true;
		SDKCall(hSetHumanSpecSDKCall, g_iSurvivorBot, pThis);
		g_bShouldIgnore = false;
	}
	
	g_iSurvivorBot = 0;
	g_bShouldFixAFK = false;
	return MRES_Ignored;
}

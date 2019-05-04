/*  
*    Fixes for gamebreaking bugs and stupid gameplay aspects
*    Copyright (C) 2019  LuxLuma		acceliacat@gmail.com
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

#pragma newdecls required

#define PLUGIN_VERSION "1.1.2"

//static Handle hInfoMapChange;
static Handle hDirectorChangeLevel;

//Credit ProdigySim for l4d2_direct reading of TheDirector class https://forums.alliedmods.net/showthread.php?t=180028
static Address TheDirector = Address_Null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "l4d2_changelevel_auto",
	author = "Lux",
	description = "-",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2607394"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile("l4d2_changelevel");
	if(hGamedata == null) 
		SetFailState("Failed to load \"l4d2_changelevel.txt\" gamedata.");
		
	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CDirectorChallengeMode::ShutdownScriptedMode"))
		SetFailState("Error finding the 'CDirectorChallengeMode::ShutdownScriptedMode' signature.");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	
	hDirectorChangeLevel = EndPrepSDKCall();
	if(hDirectorChangeLevel == null)
		SetFailState("Unable to prep SDKCall 'CDirectorChallengeMode::ShutdownScriptedMode'");
	
	TheDirector = GameConfGetAddress(hGamedata, "CDirector");
	if(TheDirector == Address_Null)
		SetFailState("Unable to get 'CDirector' Address");
	
	delete hGamedata;
	
	
	AddCommandListener(OnChangeLevel, "changelevel");
}

public Action OnChangeLevel(int iClient, const char[] sCommand, int iArgc)
{
	char sMapName[64];
	GetCmdArg(1, sMapName, sizeof(sMapName));
	if(!IsMapValid(sMapName))
		return Plugin_Continue;
	
	PrintToServer("###################blocked map changing dispatching own %s %s", sCommand, sMapName);

	SDKCall(hDirectorChangeLevel, (TheDirector + view_as<Address>(354)), 3, sMapName);
	return Plugin_Continue;
}
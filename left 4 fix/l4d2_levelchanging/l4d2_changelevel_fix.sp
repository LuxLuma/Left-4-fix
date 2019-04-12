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

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

static Handle hInfoMapChange = null;

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
	name = "l4d2_changelevel_fix",
	author = "Lux",
	description = "Creates a clean way to change maps, sm_map/changelevel causes leaks and other spooky stuff causing server perf to be worse over time.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2607394"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile("l4d2_changelevel_fix");
	if(hGamedata == null) 
		SetFailState("Failed to load \"l4d2_changelevel_fix.txt\" gamedata.");
	
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "InfoChangelevel::ChangeLevelNow"))
		SetFailState("Error finding the 'InfoChangelevel::ChangeLevelNow' signature.");
	
	hInfoMapChange = EndPrepSDKCall();
	if(hInfoMapChange == null)
		SetFailState("Unable to prep SDKCall 'InfoChangelevel::ChangeLevelNow'");

	delete hGamedata;
	
	AddCommandListener(CmdMapChange, "map");
	AddCommandListener(CmdMapChange, "changelevel");
	AddCommandListener(CmdMapChange, "changelevel2");
}

public Action CmdMapChange(int iClient, const char[] sCommand, int iArg)
{
	if(GetCmdArgs() < 1)
		return Plugin_Continue;
		
	char sMapName[64];
	GetCmdArg(1, sMapName, sizeof(sMapName));
	if(sMapName[0] == '\0')
		return Plugin_Continue;
	
	char temp[1];
	if(FindMap(sMapName, temp, sizeof(temp)) == FindMap_NotFound)
		return Plugin_Continue;
	
	char sCurrentMap[64];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	if(StrEqual(sMapName, sCurrentMap, false))//breaks if let current map be the same map.
		return Plugin_Continue;
	
	return ((L4D2_ChangeLevel(sMapName)) ? Plugin_Handled : Plugin_Continue);
}

bool L4D2_ChangeLevel(const char[] sMapName)
{
	int iInfoChangelevel = CreateEntityByName("info_changelevel");
	if(iInfoChangelevel < 1 || !IsValidEntity(iInfoChangelevel))
		return false;
	
	DispatchKeyValue(iInfoChangelevel, "map", sMapName);
	if(!DispatchSpawn(iInfoChangelevel))
	{
		AcceptEntityInput(iInfoChangelevel, "Kill");
		return false;
	}
	
	PrintToServer("SDKCall changelevel to %s", sMapName);
	SDKCall(hInfoMapChange, iInfoChangelevel);	//don't allow invalid maps get here or it will break level changing.
	AcceptEntityInput(iInfoChangelevel, "Kill");
	return true;
}
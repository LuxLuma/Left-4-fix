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
#include <dhooks>

#pragma newdecls required

#define GAMEDATA "stop_air_revive"

#define PLUGIN_VERSION	"1.0"


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion CurrentEngine = GetEngineVersion();
	if(CurrentEngine != Engine_Left4Dead2 && CurrentEngine != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1/2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "stop_air_revive",
	author = "Lux",
	description = "Block allowing to survivor to revive to while not on floor",
	version = PLUGIN_VERSION,
	url = "https://github.com/LuxLuma/Left-4-fix"
}

public void OnPluginStart()
{
	CreateConVar("stop_air_revive_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if(hGameData == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	Handle hDetour = DHookCreateFromConf(hGameData, "CTerrorPlayer::StartReviving");
	if(hDetour == null)
		SetFailState("Failed to find \"CTerrorPlayer::StartReviving\" signature.");
	
	if(!DHookEnableDetour(hDetour, false, ShouldRevive))
		SetFailState("Failed to detour \"CTerrorPlayer::StartReviving\".");

	delete hGameData;
}

public MRESReturn ShouldRevive(int pThis, Handle hParams)
{
	if(GetEntPropEnt(pThis, Prop_Send, "m_hGroundEntity") != -1)
		return MRES_Ignored;
	return MRES_Supercede;
}
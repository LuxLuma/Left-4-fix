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

// alternative to https://forums.alliedmods.net/showthread.php?p=1706053
// credit silvershot for using some code.

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#pragma newdecls required

#define GAMEDATA "physics_object_pushfix"

#define PLUGIN_VERSION	"1.0"

#define PROPMODELS_MAX 4
int g_iPropModelIndex[4];
char g_sPropModels[4][] =
{
	"models/props_equipment/oxygentank01.mdl",
	"models/props_junk/explosive_box001.mdl",
	"models/props_junk/gascan001a.mdl",
	"models/props_junk/propanecanister001a.mdl"
};

bool g_bIsPhysics[2048+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion Engine = GetEngineVersion();
	if( Engine != Engine_Left4Dead && Engine != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1/2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D1/2]physics_object_pushfix",
	author = "Lux",
	description = "Prevents firework crates, gascans, oxygen and propane tanks being pushed when players walk into them",
	version = PLUGIN_VERSION,
	url = "https://github.com/LuxLuma/Left-4-fix"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Handle hDetour = DHookCreateFromConf(hGamedata, "MovePropAway");
	if(!hDetour)
		SetFailState("Failed to find 'MovePropAway' signature");
	
	if(!DHookEnableDetour(hDetour, false, MovePropAwayPre))
		SetFailState("Failed to detour 'MovePropAway'");
	
	delete hGamedata;
	
	CreateConVar("physics_object_pushfix_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnMapStart()
{
	int iModelIndex;
	for(int i = 0; i < PROPMODELS_MAX; i++)
	{
		iModelIndex = PrecacheModel(g_sPropModels[i], true);
		g_iPropModelIndex[i] = (iModelIndex != 0 ? iModelIndex : -1);// failsafe
	}
}


public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity < 1)
		return;
	
	g_bIsPhysics[entity] = false;
	
	if(classname[0] != 'p')
		return;
	
	if(!StrEqual(classname, "prop_physics", false) && !StrEqual(classname, "physics_prop", false))
		return;
	
	g_bIsPhysics[entity] = true;
}

public MRESReturn MovePropAwayPre(Handle hReturn, Handle hParams)
{
	//param 1 = physics entity
	//param 2 = client
	//has potental to fix exploit of pushing props in chokes, e.g. mercy 4 pushing generator infront of elevator

	int iEnt = DHookGetParam(hParams, 1);
	if(!g_bIsPhysics[iEnt])
		return MRES_Ignored;

	int iModelIndex = GetEntProp(iEnt, Prop_Data, "m_nModelIndex", 2);
	for(int i = 0; i < PROPMODELS_MAX; i++)
	{
		if(iModelIndex == g_iPropModelIndex[i])
		{
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
	}
	return MRES_Ignored;
}
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
#include <dhooks>

#pragma newdecls required

#define GAMEDATA "l4d2_csweapons"

#define PLUGIN_VERSION "1.0"


#define CS_MP5 33
#define CS_SG552 34
#define CS_AWP 35
#define CS_SCOUT 36

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
	name = "l4d2_csweapons",
	author = "Lux",
	description = "Allow director to spawn CS weapons, does not obey no_cs_weapons mission keyvalue",
	version = PLUGIN_VERSION,
	url = "-"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Handle hDetour;
	hDetour = DHookCreateFromConf(hGamedata, "CDirectorItemManager::IsWeaponAllowedToExist");
	if(!hDetour)
		SetFailState("Failed to find 'CDirectorItemManager::IsWeaponAllowedToExist' signature");
	
	if(!DHookEnableDetour(hDetour, false, AreCSWeaponsAllowed))
		SetFailState("Failed to detour 'CDirectorItemManager::IsWeaponAllowedToExist'");
	
	delete hGamedata;
}

public MRESReturn AreCSWeaponsAllowed(Handle hReturn, Handle hParams)
{
	switch(DHookGetParam(hParams, 1))
	{
		case CS_MP5, CS_SG552, CS_AWP, CS_SCOUT:// CSWeaponIDs
		{
			DHookSetReturn(hReturn, true);
			return MRES_Supercede;
		}
	}
	return MRES_Ignored;
}

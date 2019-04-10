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

#define GAMEDATA "witch_target_patch"
#define PLUGIN_VERSION	"1.0"

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
	name = "[L4D2]Witch_Target_Patch",
	author = "Lux",
	description = "Fixes witch targeting wrong person",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("witch_target_patch_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
		
	Address patch;
	int offset;
	int byte;
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::GetVictim");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::GetVictim");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x74)
			{
				StoreToAddress(patch + view_as<Address>(offset), 0x7E, NumberType_Int8);
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::GetVictim'");
				return;
			}
			else if(byte == 0x75)
			{
				StoreToAddress(patch + view_as<Address>(offset), 0x7F, NumberType_Int8);
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::GetVictim'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::GetVictim'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::GetVictim'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::GetVictim' signature.");
	}
	
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::OnStart");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::OnStart");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x75)
			{
				StoreToAddress(patch + view_as<Address>(offset), 0x7F, NumberType_Int8);
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::OnStart'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::OnStart'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::OnStart'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::OnStart' signature.");
	}
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::OnAnimationEvent");
	if(patch)
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::OnAnimationEvent");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x75)
			{
				StoreToAddress(patch + view_as<Address>(offset), 0x7F, NumberType_Int8);
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::OnAnimationEvent'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::OnAnimationEvent'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::OnAnimationEvent'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::OnAnimationEvent' signature.");
	}
	
	patch = GameConfGetAddress(hGamedata, "WitchAttack::Update");
	if(patch) 
	{
		offset = GameConfGetOffset(hGamedata, "WitchAttack::Update");
		if(offset != -1) 
		{
			byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
			if(byte == 0x75)
			{
				StoreToAddress(patch + view_as<Address>(offset), 0x7F, NumberType_Int8);
				PrintToServer("WitchPatch Targeting patch applied 'WitchAttack::Update'");
			}
			else
			{
				LogError("Incorrect offset for 'WitchAttack::Update'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'WitchAttack::Update'.");
		}
	}
	else
	{
		LogError("Error finding the 'WitchAttack::Update' signature.");
	}
	delete hGamedata;
}
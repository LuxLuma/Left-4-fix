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

#define GAMEDATA "witch_change_target_fix"
#define PLUGIN_VERSION	"0.2"

#define WITCH_TARGET_OFFSET view_as<Address>(54)

int g_iWitchTarget[2048+1];
Address g_WitchAttackAddress[2048+1];
int g_iCurrentWitchUpdating;


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
	name = "[L4D2]witch_change_target_fix",
	author = "Lux",
	description = "Reimplementation of witch targeting from character indexs to entity EHandles",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2647014"
};

public void OnPluginStart()
{
	CreateConVar("witch_change_target_fix", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Handle hDetour;
	hDetour = DHookCreateFromConf(hGamedata, "WitchAttack::SetVictim");
	if(!hDetour)
	{
		SetFailState("Failed to find 'WitchAttack::SetVictim' signature");
	}
	if(!DHookEnableDetour(hDetour, false, OnSetVictimPre))
	{
		SetFailState("Failed to detour 'WitchAttack::SetVictim'");
	}
	
	hDetour = DHookCreateFromConf(hGamedata, "Behavior<Infected>::Update");
	if(!hDetour)
	{
		SetFailState("Failed to find 'Behavior<Infected>::Update' signature");
	}
	if(!DHookEnableDetour(hDetour, false, OnBehaviorUpdatePre))
	{
		SetFailState("Failed to detour 'Behavior<Infected>::Update'");
	}
	
	hDetour = DHookCreateFromConf(hGamedata, "ZombieReplacement::Restore");
	if(!hDetour)
	{
		SetFailState("Failed to find 'ZombieReplacement::Restore' signature");
	}
	if(!DHookEnableDetour(hDetour, false, OnClientReplaced))
	{
		SetFailState("Failed to detour 'ZombieReplacement::Restore'");
	}
	
	hDetour = DHookCreateFromConf(hGamedata, "SurvivorReplacement::Restore");
	if(!hDetour)
	{
		SetFailState("Failed to find 'SurvivorReplacement::Restore' signature");
	}
	if(!DHookEnableDetour(hDetour, false, OnClientReplaced))
	{
		SetFailState("Failed to detour 'SurvivorReplacement::Restore'");
	}
	
	/*
	hDetour = DHookCreateFromConf(hGamedata, "WitchAttack::Update");
	if(!hDetour)
	{
		LogError("Failed to find 'WitchAttack::Update' signature");
	}
	else if(!DHookEnableDetour(hDetour, false, OnWitchAttackUpdatePre))
	{
		LogError("Failed to detour 'WitchAttack::Update'");
	}*/
	delete hGamedata;
	
	RegAdminCmd("witchchangetarget", targetchange, ADMFLAG_ROOT);
}

public Action targetchange(int iClient, int iArgs)// test cmd very unsafe, sets all witches to attack client index
{
	char sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));
	
	for(int i = MaxClients; i <= 2048; i++)
	{
		if(g_WitchAttackAddress[i] != Address_Null)
			StoreEntityHandleToAddress(g_WitchAttackAddress[i] + WITCH_TARGET_OFFSET, StringToInt(sArg));
	}
	return Plugin_Handled;
}

//witch offset 7628‬ = startle target or nexttarget if she kills infected if the next target differs from current target.
public MRESReturn OnSetVictimPre(Address pThis, Handle hParams)
{
	g_iWitchTarget[g_iCurrentWitchUpdating] = DHookGetParam(hParams, 1);
	g_WitchAttackAddress[g_iCurrentWitchUpdating] = pThis;
}

//since i'm unsure how to locate the witch owner from the WitchAttack behavior struct(if you can), I use call order to see which address belongs to the witch.
public MRESReturn OnBehaviorUpdatePre(Address pThis, Handle hParams)
{
	g_iCurrentWitchUpdating = DHookGetParam(hParams, 1);
	if(g_iCurrentWitchUpdating < MaxClients+1 || g_iCurrentWitchUpdating > 2048)
		g_iCurrentWitchUpdating = -1;
	
	
	return MRES_Ignored;
}

public MRESReturn OnClientReplaced(Handle hReturn, Handle hParams)
{
	PrintToChatAll("%N replaced %N", DHookGetParam(hParams, 2), DHookGetParam(hParams, 1));
	
	int iClientToReplace = DHookGetParam(hParams, 1);
	int iReplacement = DHookGetParam(hParams, 2);
	
	for(int i = MaxClients+1; i < sizeof(g_iWitchTarget); i++)
	{
		if(g_iWitchTarget[i] == iClientToReplace)
			g_iWitchTarget[i] = iReplacement;
	}
	
	return MRES_Ignored;
}

//DHook limit cannot return objects so running this will crash.
public MRESReturn OnWitchAttackUpdatePre(Address pThis, Handle hReturn, Handle hParams)
{
	int iWitchTarget = LoadEntityHandleFromAddress(pThis + WITCH_TARGET_OFFSET);
	if(iWitchTarget < 1)
	{
		g_iWitchTarget[g_iCurrentWitchUpdating] = -1;
		return MRES_Ignored;
	}
	
	if(g_iWitchTarget[g_iCurrentWitchUpdating] != iWitchTarget)
		StoreEntityHandleToAddress(pThis + WITCH_TARGET_OFFSET, g_iWitchTarget[g_iCurrentWitchUpdating]);
	return MRES_Ignored;
}


/**
 * Retrieves an entity index from a raw entity handle address.
 * 
 * Note that SourceMod's entity conversion routine is an implementation detail that may change.
 * 
 * @param addr			Address to a memory location.
 * @return				Entity index, or -1 if not valid.
 */
stock int LoadEntityHandleFromAddress(Address addr) {
	return EntRefToEntIndex(LoadFromAddress(addr, NumberType_Int32) | (1 << 31));
}

/**
 * Stores an entity into a raw entity handle address.
 * 
 * Note that SourceMod's entity conversion routine is an implementation detail that may change.
 * 
 * @param addr			Address to a memory location.
 * @param entity		Entity index.
 */
stock void StoreEntityHandleToAddress(Address addr, int entity) {
	// TODO do we need to handle some special cases?
	StoreToAddress(addr, EntIndexToEntRef(entity) & ~(1 << 31), NumberType_Int32);
}
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <lux_library>

#pragma semicolon 1
#pragma newdecls required


#define PLUGIN_VERSION "1.0"

#define DEATHS_MAX_PER_FRAME 24


bool g_ShouldHideInfected[2048+1][MAXPLAYERS+1];
int g_ClientDeathAmount[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Lux",
	author = "Witch Pipebomb exploit & Death Optmizer",
	description = "Fixes",
	version = PLUGIN_VERSION,
	url = "https://github.com/LuxLuma/Left-4-fix"
};


public void OnPluginStart()
{
	HookEvent("player_death", eEntDeath);
	HookEvent("round_start", eRoundStart);
	return;
}

public void eRoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	SetConVarInt(FindConVar("z_fatal_blast_max_ragdolls"), 999, true);
	SetConVarInt(FindConVar("z_fatal_blast_min_ragdolls"), 999, true);
	return;
}

public void eEntDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	static char sNetclass[12];
	static float vecPos[3];
	static int clientsInPVS[MAXPLAYERS+1];
	
	int iVictim = hEvent.GetInt("entityid");
	if(iVictim < MaxClients+1 || iVictim > 2048 || !IsValidEntity(iVictim))
		return;
	
	GetEntityClassname(iVictim, sNetclass, sizeof(sNetclass));
	if(sNetclass[0] != 'i' || !StrEqual(sNetclass, "infected", false))
		return;
	
	for(int i; i <= MAXPLAYERS; ++i)
	{
		clientsInPVS[i] = 0;
		g_ShouldHideInfected[iVictim][i] = true;
	}
	
	GetAbsOrigin(iVictim, vecPos, true);
	int amount = GetClientsInRange(vecPos, RangeType_Visibility, clientsInPVS, sizeof(clientsInPVS));
	if(amount == 0)
	{
		RemoveEntity(iVictim);
		return;
	}
	else
	{
		for(int i; i < amount; ++i)
		{
			if(g_ClientDeathAmount[clientsInPVS[i]] < DEATHS_MAX_PER_FRAME)
			{
				g_ShouldHideInfected[iVictim][clientsInPVS[i]] = false;
				++g_ClientDeathAmount[clientsInPVS[i]];
			}
		}
		SDKHook(iVictim, SDKHook_SetTransmit, HideFromClient);
	}
	return;
}

public Action HideFromClient(int infected, int client)
{
	if(g_ShouldHideInfected[infected][client])
		return Plugin_Handled;
	return Plugin_Continue;
}

public void OnGameFrame()
{
	for(int i; i <= MaxClients; ++i)
	{
		g_ClientDeathAmount[i] = 0;
	}
	return;
}


/**
 * Get an entity's world space origin.
 * Note: Not all entities may support "CollisionProperty" for getting the center.
 * (https://github.com/LuxLuma/l4d2_structs/blob/master/collision_property.h)
 *
 * @param iEntity 		Entity index to get origin of.
 * @param vecOrigin		Vector to store origin in.
 * @param bCenter		True to get world space center, false otherwise.
 *
 * @error			Invalid entity index.
 **/
stock void GetAbsOrigin(int iEntity, float vecOrigin[3], bool bCenter=false)
{
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", vecOrigin);

	if(bCenter)
	{
		float vecMins[3];
		float vecMaxs[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMins);
		GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMaxs);

		vecOrigin[0] += (vecMins[0] + vecMaxs[0]) * 0.5;
		vecOrigin[1] += (vecMins[1] + vecMaxs[1]) * 0.5;
		vecOrigin[2] += (vecMins[2] + vecMaxs[2]) * 0.5;
	}
}
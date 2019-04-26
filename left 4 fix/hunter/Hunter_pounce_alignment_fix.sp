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
	name = "[L4D2]Hunter_pounce_alignment_fix",
	author = "Lux",
	description = "Fixes hunter slowly moving towards pounce target at cost of initial pounce animation.",
	version = PLUGIN_VERSION,
	url = "-"
};


public void OnPluginStart()
{
	CreateConVar("Hunter_pounce_alignment_fix_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(sClassname[0] == 's' && StrEqual(sClassname, "survivor_bot", false))
		SDKHook(iEntity, SDKHook_PostThinkPost, PostThinkPostSurvivor);
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
		SDKHook(iClient, SDKHook_PostThinkPost, PostThinkPostSurvivor);
}

public void PostThinkPostSurvivor(int iClient)
{
	if(!IsPlayerAlive(iClient))
		return;
	
	if(!IsFakeClient(iClient) && GetClientTeam(iClient) != 2)
		return;
	
	int iPounceAttacker = GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker");
	if(iPounceAttacker < 1 || !IsPlayerAlive(iPounceAttacker) || 
		GetEntPropEnt(iPounceAttacker, Prop_Send, "m_pounceVictim") != iClient)
		return;
	
	static float fPos[3];
	GetClientAbsOrigin(iClient, fPos);
	TeleportEntity(iClient, fPos, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(iPounceAttacker, fPos, NULL_VECTOR, NULL_VECTOR);
}

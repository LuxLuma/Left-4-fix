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

#define GAMEDATA "witch_update_witch_nbm"

#define WITCH_UPDATE_FREQUENCY 0.033

#define PLUGIN_VERSION	"1.0"

static int g_iWitchRef[2048+1] = {INVALID_ENT_REFERENCE, ...};
static bool g_bForceUpdate = false;
static float g_fWitchNextUpdate[2048+1];

//NBM = (Next Bot Manager) update method.

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
	name = "[L4D2]Witch_update_witch_nbm",
	author = "Lux",
	description = "Decouples the witch from nb_update_frequency cvar, unless the cvar is lower that WITCH_UPDATE_FREQUENCY define includes other misc stuff.",
	version = PLUGIN_VERSION,
	url = "-"
}

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Handle hDetour;
	hDetour = DHookCreateFromConf(hGamedata, "NextBotManager::ShouldUpdate");
	if(!hDetour)
		SetFailState("Failed to find \"NextBotManager::ShouldUpdate\" signature.");
		
	if(!DHookEnableDetour(hDetour, true, NextBotShouldUpdatePost))
		SetFailState("Failed to detour \"NextBotManager::ShouldUpdate\".");
	
	hDetour = DHookCreateFromConf(hGamedata, "NextBotCombatCharacter::DoThink");
	if(!hDetour)
		SetFailState("Failed to find \"NextBotCombatCharacter::DoThink\" signature.");
	
	if(!DHookEnableDetour(hDetour, false, NextBotDoThink))
		SetFailState("Failed to detour \"NextBotCombatCharacter::DoThink\".");
	
	delete hGamedata;
}

public MRESReturn NextBotShouldUpdatePost(Handle hReturn)
{
	if(g_bForceUpdate)
	{
		g_bForceUpdate = false;
		DHookSetReturn(hReturn, true);
		return MRES_Override;
	}
	return MRES_Ignored;
}

public MRESReturn NextBotDoThink(int pThis)
{
	if(IsValidEntRef(g_iWitchRef[pThis]))
	{
		static float fNow;
		fNow = GetEngineTime();
		if(g_fWitchNextUpdate[pThis] <= fNow)
		{
			g_bForceUpdate = true;
			g_fWitchNextUpdate[pThis] = fNow + ((GetEntProp(pThis, Prop_Send, "m_nSequence", 2) == 60) 
				? 0.0666666666666667 : WITCH_UPDATE_FREQUENCY);
		}
	}
	return MRES_Ignored;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(sClassname[0] != 'w' || !StrEqual(sClassname, "witch", false))
		return;
	
	g_iWitchRef[iEntity] = EntIndexToEntRef(iEntity);
	SDKHook(iEntity, SDKHook_Think, OnThink);
}

public void OnThink(int iWitch)
{
	switch(GetEntProp(iWitch, Prop_Send, "m_nSequence", 2))
	{
		case 56:
		{
			SetEntPropFloat(iWitch, Prop_Send, "m_flPlaybackRate", 2.0);
			g_fWitchNextUpdate[iWitch] = 0.0;
		}
		case 30:
		{
			SetEntPropFloat(iWitch, Prop_Send, "m_flCycle", 1.0);
			g_fWitchNextUpdate[iWitch] = 0.0;
		}
		case 32, 54, 55:
		{
			g_fWitchNextUpdate[iWitch] = 0.0;
		}
	}
}


static bool IsValidEntRef(int iEntRef)
{
	return (iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE);
}
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

#define PLUGIN_VERSION	"1.1"

enum DeathModelType
{
	DeathModelType_EntityRef = 0,
	DeathModelType_CharIndex,
}

static ConVar hCvar_Defib_All;
static bool g_bDefibAnyone = false;

static int g_iClientCharIDs[MAXPLAYERS+1][MAXPLAYERS+1];
static bool g_bReapplyChars[MAXPLAYERS+1] = {false, ...};
static int g_iDeathModelRef[MAXPLAYERS+1][2];

static bool bIgnore = false;
static int iDeathModelRef;


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
	name = "[L4D2]Defib_Fix",
	author = "Lux",
	description = "Fixes defibbing from failing when defibbing an alive character index",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2647018"
};

public void OnPluginStart()
{
	CreateConVar("defib_fix_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hCvar_Defib_All = CreateConVar("df_defib_all", "0", "Allowed to defib anyone from any body?", FCVAR_NOTIFY);
	hCvar_Defib_All.AddChangeHook(eConvarChanged);
	AutoExecConfig(true, "defib_fix");
	CvarsChanged();
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_death", ePlayerDeath, EventHookMode_Pre);
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	g_bDefibAnyone = hCvar_Defib_All.IntValue > 0;
}

public void OnRoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for(int i; i < sizeof(g_iClientCharIDs); i++)
		for(int ii; ii < sizeof(g_iClientCharIDs[]); ii++)
			g_iClientCharIDs[i][ii] = -1;
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		SDKHook(iClient, SDKHook_PostThink, PostThink);
		SDKHook(iClient, SDKHook_PostThinkPost, ThinkPost);
	}
	
	for(int i; i < sizeof(g_iClientCharIDs); i++)
		g_iClientCharIDs[iClient][i] = -1;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(sClassname[0] != 's')
	 	return;
	 	
	if(StrEqual(sClassname, "survivor_death_model", false))
		SDKHook(iEntity, SDKHook_SpawnPost, SpawnPostDeathModel);
	else if(StrEqual(sClassname, "survivor_bot"))
	{
		//incase using death chaos's defib plugin
		SDKHook(iEntity, SDKHook_PreThink, PostThink);
		SDKHook(iEntity, SDKHook_PostThinkPost, ThinkPost);
	}
}

public void PostThink(int iClient)
{
	if(!IsPlayerAlive(iClient) || GetClientTeam(iClient) != 2)
		return;
	
	if(GetEntProp(iClient, Prop_Send, "m_iCurrentUseAction", 1) != 4 || GetEntPropEnt(iClient, Prop_Send, "m_useActionOwner") != iClient)
		return;
	
	int iDeathModel = GetEntPropEnt(iClient, Prop_Send, "m_useActionTarget");
	if(iDeathModel < 1 || !IsValidEntity(iDeathModel))
		return;
	
	int iDeathModelCharIndex = GetEntProp(iDeathModel, Prop_Send, "m_nCharacterType", 4);
	
	if(g_bDefibAnyone)
	{
		int iOrignalDeathModeChar = iDeathModelCharIndex;
		if(DeathModelConvert(iDeathModel, iDeathModelCharIndex))
		{
			g_iDeathModelRef[iClient][DeathModelType_EntityRef] = EntIndexToEntRef(iDeathModel);
			g_iDeathModelRef[iClient][DeathModelType_CharIndex] = iOrignalDeathModeChar;
		}
	}
		
	iDeathModelCharIndex = ConvertToInternalCharacter(iDeathModelCharIndex);
	int iSurvivorChar;
	int iSurvivorCharConvert;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;
		
		g_bReapplyChars[iClient] = true;
		
		iSurvivorChar = GetEntProp(i, Prop_Send, "m_survivorCharacter", 1);
		iSurvivorCharConvert = ConvertToInternalCharacter(iSurvivorChar);
		
		if(iDeathModelCharIndex == iSurvivorCharConvert)
		{
			g_iClientCharIDs[iClient][i] = iSurvivorChar;
			SetEntProp(i, Prop_Send, "m_survivorCharacter", (iSurvivorCharConvert == 3) ? --iSurvivorCharConvert : ++iSurvivorCharConvert);
		}
	}
}

bool DeathModelConvert(int iDeathModel, int &iDeathModelCharIndex)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
		{
			if(iDeathModelCharIndex == GetEntProp(i, Prop_Send, "m_survivorCharacter", 1))
				return false;
		}
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
		{
			int iSurvivorChar = GetEntProp(i, Prop_Send, "m_survivorCharacter", 1);
			iDeathModelCharIndex = (iSurvivorChar == 8) ? 0 : iSurvivorChar; //should never happen but if someone is char 8 convert to 0
			SetEntProp(iDeathModel, Prop_Send, "m_nCharacterType", iDeathModelCharIndex, 4);
			return true;
		}
	}
	return false;
}

public void ThinkPost(int iClient)
{
	if(!g_bReapplyChars[iClient])
		return;
	
	g_bReapplyChars[iClient] = false;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if(g_iClientCharIDs[iClient][i] != -1)
				SetEntProp(i, Prop_Send, "m_survivorCharacter", g_iClientCharIDs[iClient][i]);
		}
		g_iClientCharIDs[iClient][i] = -1;
	}
	
	if(IsValidEntRef(g_iDeathModelRef[iClient][DeathModelType_EntityRef]))
	{
		SetEntProp(g_iDeathModelRef[iClient][DeathModelType_EntityRef], Prop_Send, "m_nCharacterType", g_iDeathModelRef[iClient][DeathModelType_CharIndex], 4);
	}
}

static bool IsValidEntRef(int iEnt)
{
	return (iEnt != 0 && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE);
}

//Convert char indexs like the game engine does.
int ConvertToInternalCharacter(int iChar)
{
	//to not have to use SDKCall for survivor_set downconvert everytime.
	switch(iChar)
	{
		case 4, 8:
		{
			return 0;
		}
		case 5:
		{
			return 1;
		}
		case 6:
		{
			return 3;
		}
		case 7:
		{
			return 2;
		}
		default:
		{
			return iChar;
		}
	}
	return iChar;
}

/*
signed int __cdecl ConvertToInternalCharacter(signed int a1)
{
  bool v1; // zf
  signed int result; // eax

  v1 = CTerrorGameRules::FastGetSurvivorSet() == 1;
  result = a1;
  if ( v1 )
  {
    switch ( a1 )
    {
      case 4:
        result = 0;
        break;
      case 5:
        result = 1;
        break;
      case 6:
        result = 3;
        break;
      case 7:
        result = 2;
        break;
      default:
        return result;
    }
  }
  return result;
}
*/

public void ePlayerDeath(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iVictim < 1 || iVictim > MaxClients || !IsClientInGame(iVictim) || GetClientTeam(iVictim) != 2)
		return;
	
	if(!IsValidEntRef(iDeathModelRef))
		return;
	
	float fPos[3];
	GetClientAbsOrigin(iVictim, fPos);
	int iEnt = EntRefToEntIndex(iDeathModelRef);
	iDeathModelRef = INVALID_ENT_REFERENCE;
	TeleportEntity(iEnt, fPos, NULL_VECTOR, NULL_VECTOR);// fix valve issue with teleporting clones

}

public void SpawnPostDeathModel(int iEntity)
{
	SDKUnhook(iEntity, SDKHook_SpawnPost, SpawnPostDeathModel);
	if(!IsValidEntity(iEntity))
		return;
	
	iDeathModelRef = EntIndexToEntRef(iEntity);
	
	if(bIgnore)
		return;
	
	bIgnore = true;
	RequestFrame(ClearVar);
}

public void ClearVar(any nothing)
{
	iDeathModelRef = INVALID_ENT_REFERENCE;
	bIgnore = false;
}

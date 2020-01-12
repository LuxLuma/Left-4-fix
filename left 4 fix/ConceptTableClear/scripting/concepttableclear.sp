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

#define LOG_GETADDRESS_FAILS true

#define PLUGIN_VERSION "0.1"

Handle hCUtlSymbolTableRemoveAll;

Address AIConceptTable = Address_Null;

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
	name = "ConceptTableClear",
	author = "Lux",
	description = "-",
	version = PLUGIN_VERSION,
	url = "-"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile("concepttableclear");
	if(hGamedata == null) 
		SetFailState("Failed to load \"concepttableclear.txt\" gamedata.");
	
	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CUtlSymbolTable::RemoveAll"))
		SetFailState("Error finding the 'CUtlSymbolTable::RemoveAll' signature.");
	
	hCUtlSymbolTableRemoveAll = EndPrepSDKCall();
	if(hCUtlSymbolTableRemoveAll == null)
		SetFailState("Unable to prep SDKCall 'CUtlSymbolTable::RemoveAll'");
	
	delete hGamedata;
	
	RegAdminCmd("sm_clearconcepttable", Changelevel, ADMFLAG_ROOT, "");
}

public Action Changelevel(int iClient, int iArg)
{
	ClearConecptTable();
	return Plugin_Handled;
}

void ClearConecptTable()
{
	if(AIConceptTable == Address_Null)
	{
		GetConceptTableAddress();
		if(AIConceptTable == Address_Null)
			return;
	}
	PrintToChatAll("[SM] ClearedConecptTable");
	SDKCall(hCUtlSymbolTableRemoveAll, AIConceptTable);
}

Address GetConceptTableAddress()
{
	Handle hGamedata = LoadGameConfigFile("concepttableclear");
	if(hGamedata == null) 
		SetFailState("Failed to load \"concepttableclear.txt\" gamedata.");
	
	AIConceptTable = GameConfGetAddress(hGamedata, "AIConceptTable");
	if(AIConceptTable == Address_Null)
	{
		LogError("Unable to get 'AIConceptTable' Address");
	}
	
	delete hGamedata;
}


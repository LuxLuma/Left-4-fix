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


//Requires https://github.com/nosoop/SMExt-SourceScramble

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define REQUIRE_EXTENSIONS
#include <sourcescramble>

#pragma newdecls required

#define GAMEDATA "hunter_pounce_alignment_fix"
#define PLUGIN_VERSION	"1.1.0"

#define DEBUG false

MemoryPatch g_PatchMoveScale;
MemoryBlock g_PatchMoveScaleRedirect;

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
	name = "[L4D2]hunter_pounce_alignment_fix",
	author = "Lux",
	description = "Fixes hunter alignment and issue with shoving a pounced survivor hunter from not being shoved off very early in pounce.",
	version = PLUGIN_VERSION,
	url = "-"
};

// followed this example https://github.com/nosoop/SM-TFCustomAttributeStarterPack/blob/master/scripting/cloak_debuff_time_scale.sp thanks noscoop
public void OnPluginStart()
{
	CreateConVar("hunter_pounce_alignment_fix_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	g_PatchMoveScale = MemoryPatch.CreateFromConf(hGamedata, "CTerrorPlayer::UpdatePounce");
	
	if(!g_PatchMoveScale.Validate())
		SetFailState("Unable to load offset signatures differ 'CTerrorPlayer::UpdatePounce'.", GAMEDATA);
		
	Address ppFloat = g_PatchMoveScale.Address + view_as<Address>(0x04);
	
	#if DEBUG
	Address pOrignalLocation = DereferencePointer(ppFloat);
	#endif
	
	float flNewMoveScale = 0.0;
	g_PatchMoveScaleRedirect = new MemoryBlock(4);
	g_PatchMoveScaleRedirect.StoreToOffset(0, view_as<int>(flNewMoveScale), NumberType_Int32);
	
	StoreToAddress(ppFloat, view_as<int>(g_PatchMoveScaleRedirect.Address), NumberType_Int32);
	
	#if DEBUG
	PrintToServer("pOrignalLocation = %f new value = %f", view_as<float>(DereferencePointer(pOrignalLocation)), view_as<float>(
			DereferencePointer(DereferencePointer(ppFloat))));
	#endif
}

//Thanks noscoop
//https://github.com/nosoop/stocksoup/blob/f531c63d411dd8541bf15d88881ee9c6cce56804/memory.inc#L39-L49
stock Address DereferencePointer(Address addr) {
	// maybe someday we'll do 64-bit addresses
	return view_as<Address>(LoadFromAddress(addr, NumberType_Int32));
}
// List of Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// The code formatting rules we wish to follow
#pragma semicolon 1;
#pragma newdecls required;


//////////////////////////
// - Global Variables - //
//////////////////////////

#define DMG_HEADSHOT (1 << 30)

ConVar Cvar_HeadshotSound;
ConVar Cvar_HeadshotShake;
ConVar Cvar_Slowdown;
ConVar Cvar_SlowdownInferno;
ConVar Cvar_SlowdownHE;


public Plugin myinfo =
{
	name		= "[CS:GO] Anti Team Griefing",
	author		= "Manifest @Road To Glory",
	description	= "Reduces numerous ways of griefing teammates through team-attacking related actions.",
	version		= "V. 1.0.0 [Beta]",
	url			= ""
};



//////////////////////////
// - Forwards & Hooks - //
//////////////////////////


public void OnPluginStart()
{
	Cvar_HeadshotSound = 	CreateConVar("Manifest_HeadshotSound", 		"1", 	"Should the loud 'ding' headshot sound be replaced with a normal attack sound when headshotted by a teammate? - [Yes = 1 | No = 0]");
	Cvar_HeadshotShake = 	CreateConVar("Manifest_HeadshotShake", 		"0", 	"Should the player's screen shake when being headshotted by their own teammates? - [Yes = 1 | No = 0]");
	Cvar_Slowdown = 		CreateConVar("Manifest_Slowdown", 			"0", 	"Should players be slowed when being attacked by their own teammates? - [Yes = 1 | No = 0]");
	Cvar_SlowdownInferno =	CreateConVar("Manifest_SlowdownInferno",	"1", 	"Should fire created from molotovs incendiary grenades still be allowed to slow down teammates? - [Yes = 1 | No = 0]");
	Cvar_SlowdownHE = 		CreateConVar("Manifest_SlowdownGrenade", 	"1", 	"Should high explosive grenades still be allowed to slow down teammates? - [Yes = 1 | No = 0]");

	AutoExecConfig(true, "custom_AntiTeamGriefing");

	LateLoadSupport();
}


public void LateLoadSupport()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if(!IsValidClient(client))
		{
			continue;
		}

		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnDamageTaken);
	}
}


public void OnClientPostAdminCheck(int client)
{
	if(!IsValidClient(client))
	{
		return;
	}

	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnDamageTaken);
}


public void OnClientDisconnect(int client)
{
	if(!IsValidClient(client))
	{
		return;
	}

	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnDamageTaken);
}


public Action Hook_OnDamageTaken(int client, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	if(!IsValidClient(attacker))
	{
		return Plugin_Continue;
	}

	if(GetClientTeam(client) != GetClientTeam(attacker))
	{
		return Plugin_Continue;
	}

	if(GetConVarInt(Cvar_SlowdownInferno) | GetConVarInt(Cvar_SlowdownHE))
	{
		char className[64];

		GetEdictClassname(inflictor, className, sizeof(className));

		if(StrEqual(className, "inferno", false))
		{
			return Plugin_Continue;
		}

		else if(StrEqual(className, "hegrenade_projectile", false))
		{
			return Plugin_Continue;
		}
	}

	if(!GetConVarInt(Cvar_Slowdown))
	{
		SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", 1.0);
	}

	if(damagetype & DMG_HEADSHOT)
	{
		if(!GetConVarInt(Cvar_HeadshotShake))
		{
			SetEntPropVector(client, Prop_Send, "m_viewPunchAngle", NULL_VECTOR);
			SetEntPropVector(client, Prop_Send, "m_aimPunchAngle", NULL_VECTOR);
			SetEntPropVector(client, Prop_Send, "m_aimPunchAngleVel", NULL_VECTOR);
		}

		if(GetConVarInt(Cvar_HeadshotSound))
		{
			damagetype &= ~DMG_HEADSHOT;
			damagetype = DMG_GENERIC;
		}
	
		return Plugin_Changed;
	}

	return Plugin_Handled;
}



////////////////////////////////
// - Return Based Functions - //
////////////////////////////////


public bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientConnected(client) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}

	return true;
}

// Super Tanks++: Smash Ability
#pragma semicolon 1
#pragma newdecls required
#include <super_tanks++>

public Plugin myinfo =
{
	name = "[ST++] Smash Ability",
	author = ST_AUTHOR,
	description = ST_DESCRIPTION,
	version = ST_VERSION,
	url = ST_URL
};

#define PARTICLE_BLOOD "boomer_explode_D"
#define SOUND_GROWL "player/tank/voice/growl/tank_climb_01.wav"
#define SOUND_SMASH "player/charger/hit/charger_smash_02.wav"

bool g_bLateLoad;
bool g_bTankConfig[ST_MAXTYPES + 1];
float g_flSmashRange[ST_MAXTYPES + 1];
float g_flSmashRange2[ST_MAXTYPES + 1];
int g_iSmashAbility[ST_MAXTYPES + 1];
int g_iSmashAbility2[ST_MAXTYPES + 1];
int g_iSmashChance[ST_MAXTYPES + 1];
int g_iSmashChance2[ST_MAXTYPES + 1];
int g_iSmashHit[ST_MAXTYPES + 1];
int g_iSmashHit2[ST_MAXTYPES + 1];
int g_iSmashRangeChance[ST_MAXTYPES + 1];
int g_iSmashRangeChance2[ST_MAXTYPES + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[ST++] Smash Ability only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("super_tanks++"))
	{
		SetFailState("No Super Tanks++ library found.");
	}
}

public void OnMapStart()
{
	vPrecacheParticle(PARTICLE_BLOOD);
	PrecacheSound(SOUND_GROWL, true);
	PrecacheSound(SOUND_SMASH, true);
	if (g_bLateLoad)
	{
		vLateLoad(true);
		g_bLateLoad = false;
	}
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void vLateLoad(bool late)
{
	if (late)
	{
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer))
			{
				SDKHook(iPlayer, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (ST_PluginEnabled() && damage > 0.0)
	{
		if (ST_TankAllowed(attacker) && IsPlayerAlive(attacker) && bIsSurvivor(victim))
		{
			char sClassname[32];
			GetEntityClassname(inflictor, sClassname, sizeof(sClassname));
			if (strcmp(sClassname, "weapon_tank_claw") == 0 || strcmp(sClassname, "tank_rock") == 0)
			{
				int iSmashChance = !g_bTankConfig[ST_TankType(attacker)] ? g_iSmashChance[ST_TankType(attacker)] : g_iSmashChance2[ST_TankType(attacker)];
				int iSmashHit = !g_bTankConfig[ST_TankType(attacker)] ? g_iSmashHit[ST_TankType(attacker)] : g_iSmashHit2[ST_TankType(attacker)];
				vSmashHit(victim, iSmashChance, iSmashHit);
			}
		}
	}
}

public void ST_Configs(char[] savepath, int limit, bool main)
{
	KeyValues kvSuperTanks = new KeyValues("Super Tanks++");
	kvSuperTanks.ImportFromFile(savepath);
	for (int iIndex = 1; iIndex <= limit; iIndex++)
	{
		char sName[MAX_NAME_LENGTH + 1];
		Format(sName, sizeof(sName), "Tank %d", iIndex);
		if (kvSuperTanks.JumpToKey(sName))
		{
			main ? (g_bTankConfig[iIndex] = false) : (g_bTankConfig[iIndex] = true);
			main ? (g_iSmashAbility[iIndex] = kvSuperTanks.GetNum("Smash Ability/Ability Enabled", 0)) : (g_iSmashAbility2[iIndex] = kvSuperTanks.GetNum("Smash Ability/Ability Enabled", g_iSmashAbility[iIndex]));
			main ? (g_iSmashAbility[iIndex] = iSetCellLimit(g_iSmashAbility[iIndex], 0, 1)) : (g_iSmashAbility2[iIndex] = iSetCellLimit(g_iSmashAbility2[iIndex], 0, 1));
			main ? (g_iSmashChance[iIndex] = kvSuperTanks.GetNum("Smash Ability/Smash Chance", 4)) : (g_iSmashChance2[iIndex] = kvSuperTanks.GetNum("Smash Ability/Smash Chance", g_iSmashChance[iIndex]));
			main ? (g_iSmashChance[iIndex] = iSetCellLimit(g_iSmashChance[iIndex], 1, 9999999999)) : (g_iSmashChance2[iIndex] = iSetCellLimit(g_iSmashChance2[iIndex], 1, 9999999999));
			main ? (g_iSmashHit[iIndex] = kvSuperTanks.GetNum("Smash Ability/Smash Hit", 0)) : (g_iSmashHit2[iIndex] = kvSuperTanks.GetNum("Smash Ability/Smash Hit", g_iSmashHit[iIndex]));
			main ? (g_iSmashHit[iIndex] = iSetCellLimit(g_iSmashHit[iIndex], 0, 1)) : (g_iSmashHit2[iIndex] = iSetCellLimit(g_iSmashHit2[iIndex], 0, 1));
			main ? (g_flSmashRange[iIndex] = kvSuperTanks.GetFloat("Smash Ability/Smash Range", 150.0)) : (g_flSmashRange2[iIndex] = kvSuperTanks.GetFloat("Smash Ability/Smash Range", g_flSmashRange[iIndex]));
			main ? (g_flSmashRange[iIndex] = flSetFloatLimit(g_flSmashRange[iIndex], 1.0, 9999999999.0)) : (g_flSmashRange2[iIndex] = flSetFloatLimit(g_flSmashRange2[iIndex], 1.0, 9999999999.0));
			main ? (g_iSmashRangeChance[iIndex] = kvSuperTanks.GetNum("Smash Ability/Smash Range Chance", 16)) : (g_iSmashRangeChance2[iIndex] = kvSuperTanks.GetNum("Smash Ability/Smash Range Chance", g_iSmashRangeChance[iIndex]));
			main ? (g_iSmashRangeChance[iIndex] = iSetCellLimit(g_iSmashRangeChance[iIndex], 1, 9999999999)) : (g_iSmashRangeChance2[iIndex] = iSetCellLimit(g_iSmashRangeChance2[iIndex], 1, 9999999999));
			kvSuperTanks.Rewind();
		}
	}
	delete kvSuperTanks;
}

public void ST_Death2(int enemy, int client)
{
	int iSmashAbility = !g_bTankConfig[ST_TankType(enemy)] ? g_iSmashAbility[ST_TankType(enemy)] : g_iSmashAbility2[ST_TankType(enemy)];
	if (ST_TankAllowed(enemy) && iSmashAbility == 1 && bIsSurvivor(client))
	{
		int iCorpse = -1;
		while ((iCorpse = FindEntityByClassname(iCorpse, "survivor_death_model")) != INVALID_ENT_REFERENCE)
		{
			int iOwner = GetEntPropEnt(iCorpse, Prop_Send, "m_hOwnerEntity");
			if (client == iOwner)
			{
				AcceptEntityInput(iCorpse, "Kill");
			}
		}
	}
}

public void ST_Ability(int client)
{
	if (ST_TankAllowed(client) && IsPlayerAlive(client))
	{
		int iSmashAbility = !g_bTankConfig[ST_TankType(client)] ? g_iSmashAbility[ST_TankType(client)] : g_iSmashAbility2[ST_TankType(client)];
		int iSmashRangeChance = !g_bTankConfig[ST_TankType(client)] ? g_iSmashChance[ST_TankType(client)] : g_iSmashChance2[ST_TankType(client)];
		float flSmashRange = !g_bTankConfig[ST_TankType(client)] ? g_flSmashRange[ST_TankType(client)] : g_flSmashRange2[ST_TankType(client)];
		float flTankPos[3];
		GetClientAbsOrigin(client, flTankPos);
		for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
		{
			if (bIsSurvivor(iSurvivor))
			{
				float flSurvivorPos[3];
				GetClientAbsOrigin(iSurvivor, flSurvivorPos);
				float flDistance = GetVectorDistance(flTankPos, flSurvivorPos);
				if (flDistance <= flSmashRange)
				{
					vSmashHit(iSurvivor, iSmashRangeChance, iSmashAbility);
				}
			}
		}
	}
}

void vSmashHit(int client, int chance, int enabled)
{
	if (enabled == 1 && GetRandomInt(1, chance) == 1 && bIsSurvivor(client))
	{
		EmitSoundToAll(SOUND_SMASH, client);
		vAttachParticle(client, PARTICLE_BLOOD, 0.1, 0.0);
		ForcePlayerSuicide(client);
	}
}

void vAttachParticle(int client, char[] particlename, float time = 0.0, float origin = 0.0)
{
	if (bIsValidClient(client))
	{
		int iParticle = CreateEntityByName("info_particle_system");
		if (IsValidEntity(iParticle))
		{
			float flPos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", flPos);
			flPos[2] += origin;
			DispatchKeyValue(iParticle, "scale", "");
			DispatchKeyValue(iParticle, "effect_name", particlename);
			TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(iParticle);
			ActivateEntity(iParticle);
			AcceptEntityInput(iParticle, "Enable");
			AcceptEntityInput(iParticle, "Start");
			vSetEntityParent(iParticle, client);
			iParticle = EntIndexToEntRef(iParticle);
			vDeleteEntity(iParticle, time);
		}
	}
}

void vDeleteEntity(int entity, float time = 0.1)
{
	if (bIsValidEntRef(entity))
	{
		char sVariant[64];
		Format(sVariant, sizeof(sVariant), "OnUser1 !self:kill::%f:1", time);
		AcceptEntityInput(entity, "ClearParent");
		SetVariantString(sVariant);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

void vPrecacheParticle(char[] particlename)
{
	int iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(iParticle))
	{
		DispatchKeyValue(iParticle, "effect_name", particlename);
		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
		vSetEntityParent(iParticle, iParticle);
		iParticle = EntIndexToEntRef(iParticle);
		vDeleteEntity(iParticle);
	}
}

void vSetEntityParent(int entity, int parent)
{
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", parent);
}

bool bIsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client);
}

bool bIsValidEntRef(int entity)
{
	return entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE;
}
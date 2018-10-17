// Super Tanks++: Choke Ability
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <st_clone>
#define REQUIRE_PLUGIN

#include <super_tanks++>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ST++] Choke Ability",
	author = ST_AUTHOR,
	description = "The Super Tank sends survivors into space.",
	version = ST_VERSION,
	url = ST_URL
};

bool g_bCloneInstalled, g_bLateLoad, g_bChoke[MAXPLAYERS + 1], g_bChoke2[MAXPLAYERS + 1], g_bTankConfig[ST_MAXTYPES + 1];

char g_sChokeEffect[ST_MAXTYPES + 1][4], g_sChokeEffect2[ST_MAXTYPES + 1][4];

float g_flChokeAngle[MAXPLAYERS + 1][3], g_flChokeChance[ST_MAXTYPES + 1], g_flChokeChance2[ST_MAXTYPES + 1], g_flChokeDamage[ST_MAXTYPES + 1], g_flChokeDamage2[ST_MAXTYPES + 1], g_flChokeDelay[ST_MAXTYPES + 1], g_flChokeDelay2[ST_MAXTYPES + 1], g_flChokeDuration[ST_MAXTYPES + 1], g_flChokeDuration2[ST_MAXTYPES + 1], g_flChokeHeight[ST_MAXTYPES + 1], g_flChokeHeight2[ST_MAXTYPES + 1], g_flChokeRange[ST_MAXTYPES + 1], g_flChokeRange2[ST_MAXTYPES + 1], g_flChokeRangeChance[ST_MAXTYPES + 1], g_flChokeRangeChance2[ST_MAXTYPES + 1];

int g_iChokeAbility[ST_MAXTYPES + 1], g_iChokeAbility2[ST_MAXTYPES + 1], g_iChokeHit[ST_MAXTYPES + 1], g_iChokeHit2[ST_MAXTYPES + 1], g_iChokeHitMode[ST_MAXTYPES + 1], g_iChokeHitMode2[ST_MAXTYPES + 1], g_iChokeMessage[ST_MAXTYPES + 1], g_iChokeMessage2[ST_MAXTYPES + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!bIsValidGame(false) && !bIsValidGame())
	{
		strcopy(error, err_max, "[ST++] Choke Ability only supports Left 4 Dead 1 & 2.");

		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bCloneInstalled = LibraryExists("st_clone");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "st_clone", false))
	{
		g_bCloneInstalled = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "st_clone", false))
	{
		g_bCloneInstalled = false;
	}
}

public void OnPluginStart()
{
	LoadTranslations("super_tanks++.phrases");

	if (g_bLateLoad)
	{
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer))
			{
				OnClientPutInServer(iPlayer);
			}
		}

		g_bLateLoad = false;
	}
}

public void OnMapStart()
{
	vReset();
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

	g_bChoke[client] = false;
}

public void OnMapEnd()
{
	vReset();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!ST_PluginEnabled())
	{
		return Plugin_Continue;
	}

	if (g_bChoke2[client])
	{
		TeleportEntity(client, NULL_VECTOR, g_flChokeAngle[client], NULL_VECTOR);
	}

	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (ST_PluginEnabled() && damage > 0.0)
	{
		char sClassname[32];
		GetEntityClassname(inflictor, sClassname, sizeof(sClassname));

		if ((iChokeHitMode(attacker) == 0 || iChokeHitMode(attacker) == 1) && ST_TankAllowed(attacker) && ST_CloneAllowed(attacker, g_bCloneInstalled) && IsPlayerAlive(attacker) && bIsSurvivor(victim))
		{
			if (StrEqual(sClassname, "weapon_tank_claw") || StrEqual(sClassname, "tank_rock"))
			{
				vChokeHit(victim, attacker, flChokeChance(attacker), iChokeHit(attacker), 1, "1");
			}
		}
		else if ((iChokeHitMode(victim) == 0 || iChokeHitMode(victim) == 2) && ST_TankAllowed(victim) && ST_CloneAllowed(victim, g_bCloneInstalled) && IsPlayerAlive(victim) && bIsSurvivor(attacker))
		{
			if (StrEqual(sClassname, "weapon_melee"))
			{
				vChokeHit(attacker, victim, flChokeChance(victim), iChokeHit(victim), 1, "2");
			}
		}
	}
}

public void ST_Configs(const char[] savepath, bool main)
{
	KeyValues kvSuperTanks = new KeyValues("Super Tanks++");
	kvSuperTanks.ImportFromFile(savepath);
	for (int iIndex = ST_MinType(); iIndex <= ST_MaxType(); iIndex++)
	{
		char sTankName[MAX_NAME_LENGTH + 1];
		Format(sTankName, sizeof(sTankName), "Tank #%d", iIndex);
		if (kvSuperTanks.JumpToKey(sTankName, true))
		{
			if (main)
			{
				g_bTankConfig[iIndex] = false;

				g_iChokeAbility[iIndex] = kvSuperTanks.GetNum("Choke Ability/Ability Enabled", 0);
				g_iChokeAbility[iIndex] = iClamp(g_iChokeAbility[iIndex], 0, 1);
				kvSuperTanks.GetString("Choke Ability/Ability Effect", g_sChokeEffect[iIndex], sizeof(g_sChokeEffect[]), "123");
				g_iChokeMessage[iIndex] = kvSuperTanks.GetNum("Choke Ability/Ability Message", 0);
				g_iChokeMessage[iIndex] = iClamp(g_iChokeMessage[iIndex], 0, 3);
				g_flChokeChance[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Chance", 33.3);
				g_flChokeChance[iIndex] = flClamp(g_flChokeChance[iIndex], 0.1, 100.0);
				g_flChokeDamage[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Damage", 5.0);
				g_flChokeDamage[iIndex] = flClamp(g_flChokeDamage[iIndex], 1.0, 9999999999.0);
				g_flChokeDelay[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Delay", 1.0);
				g_flChokeDelay[iIndex] = flClamp(g_flChokeDelay[iIndex], 0.1, 9999999999.0);
				g_flChokeDuration[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Duration", 5.0);
				g_flChokeDuration[iIndex] = flClamp(g_flChokeDuration[iIndex], 0.1, 9999999999.0);
				g_flChokeHeight[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Height", 300.0);
				g_flChokeHeight[iIndex] = flClamp(g_flChokeHeight[iIndex], 0.1, 9999999999.0);
				g_iChokeHit[iIndex] = kvSuperTanks.GetNum("Choke Ability/Choke Hit", 0);
				g_iChokeHit[iIndex] = iClamp(g_iChokeHit[iIndex], 0, 1);
				g_iChokeHitMode[iIndex] = kvSuperTanks.GetNum("Choke Ability/Choke Hit Mode", 0);
				g_iChokeHitMode[iIndex] = iClamp(g_iChokeHitMode[iIndex], 0, 2);
				g_flChokeRange[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Range", 150.0);
				g_flChokeRange[iIndex] = flClamp(g_flChokeRange[iIndex], 1.0, 9999999999.0);
				g_flChokeRangeChance[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Range Chance", 15.0);
				g_flChokeRangeChance[iIndex] = flClamp(g_flChokeRangeChance[iIndex], 0.1, 100.0);
			}
			else
			{
				g_bTankConfig[iIndex] = true;

				g_iChokeAbility2[iIndex] = kvSuperTanks.GetNum("Choke Ability/Ability Enabled", g_iChokeAbility[iIndex]);
				g_iChokeAbility2[iIndex] = iClamp(g_iChokeAbility2[iIndex], 0, 1);
				kvSuperTanks.GetString("Choke Ability/Ability Effect", g_sChokeEffect2[iIndex], sizeof(g_sChokeEffect2[]), g_sChokeEffect[iIndex]);
				g_iChokeMessage2[iIndex] = kvSuperTanks.GetNum("Choke Ability/Ability Message", g_iChokeMessage[iIndex]);
				g_iChokeMessage2[iIndex] = iClamp(g_iChokeMessage2[iIndex], 0, 3);
				g_flChokeChance2[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Chance", g_flChokeChance[iIndex]);
				g_flChokeChance2[iIndex] = flClamp(g_flChokeChance2[iIndex], 0.1, 100.0);
				g_flChokeDamage2[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Damage", g_flChokeDamage[iIndex]);
				g_flChokeDamage2[iIndex] = flClamp(g_flChokeDamage2[iIndex], 1.0, 9999999999.0);
				g_flChokeDelay2[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Delay", g_flChokeDelay[iIndex]);
				g_flChokeDelay2[iIndex] = flClamp(g_flChokeDelay2[iIndex], 0.1, 9999999999.0);
				g_flChokeDuration2[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Duration", g_flChokeDuration[iIndex]);
				g_flChokeDuration2[iIndex] = flClamp(g_flChokeDuration2[iIndex], 0.1, 9999999999.0);
				g_flChokeHeight2[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Height", g_flChokeHeight[iIndex]);
				g_flChokeHeight2[iIndex] = flClamp(g_flChokeHeight2[iIndex], 0.1, 9999999999.0);
				g_iChokeHit2[iIndex] = kvSuperTanks.GetNum("Choke Ability/Choke Hit", g_iChokeHit[iIndex]);
				g_iChokeHit2[iIndex] = iClamp(g_iChokeHit2[iIndex], 0, 1);
				g_iChokeHitMode2[iIndex] = kvSuperTanks.GetNum("Choke Ability/Choke Hit Mode", g_iChokeHitMode[iIndex]);
				g_iChokeHitMode2[iIndex] = iClamp(g_iChokeHitMode2[iIndex], 0, 2);
				g_flChokeRange2[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Range", g_flChokeRange[iIndex]);
				g_flChokeRange2[iIndex] = flClamp(g_flChokeRange2[iIndex], 1.0, 9999999999.0);
				g_flChokeRangeChance2[iIndex] = kvSuperTanks.GetFloat("Choke Ability/Choke Range Chance", g_flChokeRangeChance[iIndex]);
				g_flChokeRangeChance2[iIndex] = flClamp(g_flChokeRangeChance2[iIndex], 0.1, 100.0);
			}

			kvSuperTanks.Rewind();
		}
	}

	delete kvSuperTanks;
}

public void ST_PluginEnd()
{
	vReset();
}

public void ST_Ability(int tank)
{
	if (ST_TankAllowed(tank) && ST_CloneAllowed(tank, g_bCloneInstalled) && IsPlayerAlive(tank))
	{
		int iChokeAbility = !g_bTankConfig[ST_TankType(tank)] ? g_iChokeAbility[ST_TankType(tank)] : g_iChokeAbility2[ST_TankType(tank)];

		float flChokeRange = !g_bTankConfig[ST_TankType(tank)] ? g_flChokeRange[ST_TankType(tank)] : g_flChokeRange2[ST_TankType(tank)],
			flChokeRangeChance = !g_bTankConfig[ST_TankType(tank)] ? g_flChokeRangeChance[ST_TankType(tank)] : g_flChokeRangeChance2[ST_TankType(tank)],
			flTankPos[3];

		GetClientAbsOrigin(tank, flTankPos);

		for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
		{
			if (bIsSurvivor(iSurvivor))
			{
				float flSurvivorPos[3];
				GetClientAbsOrigin(iSurvivor, flSurvivorPos);

				float flDistance = GetVectorDistance(flTankPos, flSurvivorPos);
				if (flDistance <= flChokeRange)
				{
					vChokeHit(iSurvivor, tank, flChokeRangeChance, iChokeAbility, 2, "3");
				}
			}
		}
	}
}

static void vChokeHit(int survivor, int tank, float chance, int enabled, int message, const char[] mode)
{
	if (enabled == 1 && GetRandomFloat(0.1, 100.0) <= chance && bIsSurvivor(survivor) && !g_bChoke[survivor])
	{
		g_bChoke[survivor] = true;

		GetClientEyeAngles(survivor, g_flChokeAngle[survivor]);

		float flChokeDelay = !g_bTankConfig[ST_TankType(tank)] ? g_flChokeDelay[ST_TankType(tank)] : g_flChokeDelay2[ST_TankType(tank)];

		DataPack dpChokeLaunch;
		CreateDataTimer(flChokeDelay, tTimerChokeLaunch, dpChokeLaunch, TIMER_FLAG_NO_MAPCHANGE);
		dpChokeLaunch.WriteCell(GetClientUserId(survivor));
		dpChokeLaunch.WriteCell(GetClientUserId(tank));
		dpChokeLaunch.WriteCell(message);
		dpChokeLaunch.WriteCell(enabled);

		char sChokeEffect[4];
		sChokeEffect = !g_bTankConfig[ST_TankType(tank)] ? g_sChokeEffect[ST_TankType(tank)] : g_sChokeEffect2[ST_TankType(tank)];
		vEffect(survivor, tank, sChokeEffect, mode);

		if (iChokeMessage(tank) == message || iChokeMessage(tank) == 3)
		{
			char sTankName[MAX_NAME_LENGTH + 1];
			ST_TankName(tank, sTankName);
			PrintToChatAll("%s %t", ST_PREFIX2, "Choke", sTankName, survivor);
		}
	}
}

static void vReset()
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsValidClient(iPlayer))
		{
			g_bChoke[iPlayer] = false;
		}
	}
}

static void vReset2(int survivor, int tank, int message)
{
	g_bChoke[survivor] = false;
	g_bChoke2[survivor] = false;

	SetEntityMoveType(survivor, MOVETYPE_WALK);

	if (iChokeMessage(tank) == message || iChokeMessage(tank) == 3)
	{
		PrintToChatAll("%s %t", ST_PREFIX2, "Choke2", survivor);
	}
}

static float flChokeChance(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_flChokeChance[ST_TankType(tank)] : g_flChokeChance2[ST_TankType(tank)];
}

static int iChokeHit(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iChokeHit[ST_TankType(tank)] : g_iChokeHit2[ST_TankType(tank)];
}

static int iChokeHitMode(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iChokeHitMode[ST_TankType(tank)] : g_iChokeHitMode2[ST_TankType(tank)];
}

static int iChokeMessage(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iChokeMessage[ST_TankType(tank)] : g_iChokeMessage2[ST_TankType(tank)];
}

public Action tTimerChokeLaunch(Handle timer, DataPack pack)
{
	pack.Reset();

	int iSurvivor = GetClientOfUserId(pack.ReadCell());
	if (!bIsSurvivor(iSurvivor) || !g_bChoke[iSurvivor])
	{
		g_bChoke[iSurvivor] = false;

		return Plugin_Stop;
	}

	int iTank = GetClientOfUserId(pack.ReadCell());
	if (!ST_TankAllowed(iTank) || !ST_TypeEnabled(ST_TankType(iTank)) || !IsPlayerAlive(iTank) || !ST_CloneAllowed(iTank, g_bCloneInstalled))
	{
		g_bChoke[iSurvivor] = false;

		return Plugin_Stop;
	}

	int iChokeChat = pack.ReadCell(), iChokeAbility = pack.ReadCell();
	if (iChokeAbility == 0)
	{
		g_bChoke[iSurvivor] = false;

		return Plugin_Stop;
	}

	float flChokeHeight = !g_bTankConfig[ST_TankType(iTank)] ? g_flChokeHeight[ST_TankType(iTank)] : g_flChokeHeight2[ST_TankType(iTank)],
		flVelocity[3];

	flVelocity[0] = 0.0;
	flVelocity[1] = 0.0;
	flVelocity[2] = flChokeHeight;

	TeleportEntity(iSurvivor, NULL_VECTOR, NULL_VECTOR, flVelocity);
	SetEntityGravity(iSurvivor, 0.1);

	DataPack dpChokeDamage;
	CreateDataTimer(1.0, tTimerChokeDamage, dpChokeDamage, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	dpChokeDamage.WriteCell(GetClientUserId(iSurvivor));
	dpChokeDamage.WriteCell(GetClientUserId(iTank));
	dpChokeDamage.WriteCell(iChokeChat);
	dpChokeDamage.WriteCell(iChokeAbility);
	dpChokeDamage.WriteFloat(GetEngineTime());

	return Plugin_Continue;
}

public Action tTimerChokeDamage(Handle timer, DataPack pack)
{
	pack.Reset();

	int iSurvivor = GetClientOfUserId(pack.ReadCell());
	if (!bIsSurvivor(iSurvivor) || !g_bChoke[iSurvivor])
	{
		g_bChoke[iSurvivor] = false;
		g_bChoke2[iSurvivor] = false;

		return Plugin_Stop;
	}

	int iTank = GetClientOfUserId(pack.ReadCell()), iChokeChat = pack.ReadCell();
	if (!ST_TankAllowed(iTank) || !ST_TypeEnabled(ST_TankType(iTank)) || !IsPlayerAlive(iTank) || !ST_CloneAllowed(iTank, g_bCloneInstalled))
	{
		vReset2(iSurvivor, iTank, iChokeChat);

		return Plugin_Stop;
	}

	int iChokeAbility = pack.ReadCell();
	float flTime = pack.ReadFloat(),
		flChokeDuration = !g_bTankConfig[ST_TankType(iTank)] ? g_flChokeDuration[ST_TankType(iTank)] : g_flChokeDuration2[ST_TankType(iTank)];

	if (iChokeAbility == 0 || (flTime + flChokeDuration) < GetEngineTime())
	{
		vReset2(iSurvivor, iTank, iChokeChat);

		return Plugin_Stop;
	}

	g_bChoke2[iSurvivor] = true;

	float flVelocity[3] = {0.0, 0.0, 0.0};
	TeleportEntity(iSurvivor, NULL_VECTOR, NULL_VECTOR, flVelocity);

	SetEntityMoveType(iSurvivor, MOVETYPE_NONE);
	SetEntityGravity(iSurvivor, 1.0);

	float flChokeDamage = !g_bTankConfig[ST_TankType(iTank)] ? g_flChokeDamage[ST_TankType(iTank)] : g_flChokeDamage2[ST_TankType(iTank)];
	SDKHooks_TakeDamage(iSurvivor, iTank, iTank, flChokeDamage);

	return Plugin_Continue;
}
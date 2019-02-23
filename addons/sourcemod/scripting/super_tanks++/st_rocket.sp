/**
 * Super Tanks++: a L4D/L4D2 SourceMod Plugin
 * Copyright (C) 2019  Alfred "Crasher_3637/Psyk0tik" Llagas
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

#include <sourcemod>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <st_clone>
#define REQUIRE_PLUGIN

#include <super_tanks++>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ST++] Rocket Ability",
	author = ST_AUTHOR,
	description = "The Super Tank sends survivors into space.",
	version = ST_VERSION,
	url = ST_URL
};

bool g_bLateLoad;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!bIsValidGame(false) && !bIsValidGame())
	{
		strcopy(error, err_max, "\"[ST++] Rocket Ability\" only supports Left 4 Dead 1 & 2.");

		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;

	return APLRes_Success;
}

#define SPRITE_FIRE "sprites/sprite_fire01.vmt"

#define SOUND_EXPLOSION "ambient/explosions/exp2.wav"
#define SOUND_FIRE "weapons/rpg/rocketfire1.wav"
#define SOUND_LAUNCH "npc/env_headcrabcanister/launch.wav"

#define ST_MENU_ROCKET "Rocket Ability"

bool g_bCloneInstalled, g_bRocket[MAXPLAYERS + 1], g_bRocket2[MAXPLAYERS + 1], g_bRocket3[MAXPLAYERS + 1], g_bRocket4[MAXPLAYERS + 1], g_bRocket5[MAXPLAYERS + 1], g_bTankConfig[ST_MAXTYPES + 1];

float g_flHumanCooldown[ST_MAXTYPES + 1], g_flHumanCooldown2[ST_MAXTYPES + 1], g_flRocketChance[ST_MAXTYPES + 1], g_flRocketChance2[ST_MAXTYPES + 1], g_flRocketDelay[ST_MAXTYPES + 1], g_flRocketDelay2[ST_MAXTYPES + 1], g_flRocketRange[ST_MAXTYPES + 1], g_flRocketRange2[ST_MAXTYPES + 1], g_flRocketRangeChance[ST_MAXTYPES + 1], g_flRocketRangeChance2[ST_MAXTYPES + 1];

int g_iHumanAbility[ST_MAXTYPES + 1], g_iHumanAbility2[ST_MAXTYPES + 1], g_iHumanAmmo[ST_MAXTYPES + 1], g_iHumanAmmo2[ST_MAXTYPES + 1], g_iRocketAbility[ST_MAXTYPES + 1], g_iRocketAbility2[ST_MAXTYPES + 1], g_iRocketCount[MAXPLAYERS + 1], g_iRocketEffect[ST_MAXTYPES + 1], g_iRocketEffect2[ST_MAXTYPES + 1], g_iRocketHit[ST_MAXTYPES + 1], g_iRocketHit2[ST_MAXTYPES + 1], g_iRocketHitMode[ST_MAXTYPES + 1], g_iRocketHitMode2[ST_MAXTYPES + 1], g_iRocketMessage[ST_MAXTYPES + 1], g_iRocketMessage2[ST_MAXTYPES + 1], g_iRocketOwner[MAXPLAYERS + 1], g_iRocketSprite = -1;

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
	LoadTranslations("common.phrases");
	LoadTranslations("super_tanks++.phrases");

	RegConsoleCmd("sm_st_rocket", cmdRocketInfo, "View information about the Rocket ability.");

	if (g_bLateLoad)
	{
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer, ST_CHECK_INGAME|ST_CHECK_KICKQUEUE))
			{
				OnClientPutInServer(iPlayer);
			}
		}

		g_bLateLoad = false;
	}
}

public void OnMapStart()
{
	g_iRocketSprite = PrecacheModel(SPRITE_FIRE, true);

	PrecacheSound(SOUND_EXPLOSION, true);
	PrecacheSound(SOUND_FIRE, true);
	PrecacheSound(SOUND_LAUNCH, true);

	vReset();
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

	vReset3(client);
}

public void OnMapEnd()
{
	vReset();
}

public Action cmdRocketInfo(int client, int args)
{
	if (!ST_IsCorePluginEnabled())
	{
		ReplyToCommand(client, "%s Super Tanks++\x01 is disabled.", ST_TAG4);

		return Plugin_Handled;
	}

	if (!bIsValidClient(client, ST_CHECK_INDEX|ST_CHECK_INGAME|ST_CHECK_KICKQUEUE|ST_CHECK_FAKECLIENT))
	{
		ReplyToCommand(client, "%s This command is to be used only in-game.", ST_TAG);

		return Plugin_Handled;
	}

	switch (IsVoteInProgress())
	{
		case true: ReplyToCommand(client, "%s %t", ST_TAG2, "Vote in Progress");
		case false: vRocketMenu(client, 0);
	}

	return Plugin_Handled;
}

static void vRocketMenu(int client, int item)
{
	Menu mAbilityMenu = new Menu(iRocketMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
	mAbilityMenu.SetTitle("Rocket Ability Information");
	mAbilityMenu.AddItem("Status", "Status");
	mAbilityMenu.AddItem("Ammunition", "Ammunition");
	mAbilityMenu.AddItem("Buttons", "Buttons");
	mAbilityMenu.AddItem("Cooldown", "Cooldown");
	mAbilityMenu.AddItem("Details", "Details");
	mAbilityMenu.AddItem("Human Support", "Human Support");
	mAbilityMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int iRocketMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0: ST_PrintToChat(param1, "%s %t", ST_TAG3, iRocketAbility(param1) == 0 ? "AbilityStatus1" : "AbilityStatus2");
				case 1: ST_PrintToChat(param1, "%s %t", ST_TAG3, "AbilityAmmo", iHumanAmmo(param1) - g_iRocketCount[param1], iHumanAmmo(param1));
				case 2: ST_PrintToChat(param1, "%s %t", ST_TAG3, "AbilityButtons2");
				case 3: ST_PrintToChat(param1, "%s %t", ST_TAG3, "AbilityCooldown", flHumanCooldown(param1));
				case 4: ST_PrintToChat(param1, "%s %t", ST_TAG3, "RocketDetails");
				case 5: ST_PrintToChat(param1, "%s %t", ST_TAG3, iHumanAbility(param1) == 0 ? "AbilityHumanSupport1" : "AbilityHumanSupport2");
			}

			if (bIsValidClient(param1, ST_CHECK_INGAME|ST_CHECK_KICKQUEUE))
			{
				vRocketMenu(param1, menu.Selection);
			}
		}
		case MenuAction_Display:
		{
			char sMenuTitle[255];
			Panel panel = view_as<Panel>(param2);
			Format(sMenuTitle, sizeof(sMenuTitle), "%T", "RocketMenu", param1);
			panel.SetTitle(sMenuTitle);
		}
		case MenuAction_DisplayItem:
		{
			char sMenuOption[255];
			switch (param2)
			{
				case 0:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Status", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 1:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Ammunition", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 2:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Buttons", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 3:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Cooldown", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 4:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "Details", param1);
					return RedrawMenuItem(sMenuOption);
				}
				case 5:
				{
					Format(sMenuOption, sizeof(sMenuOption), "%T", "HumanSupport", param1);
					return RedrawMenuItem(sMenuOption);
				}
			}
		}
	}

	return 0;
}

public void ST_OnDisplayMenu(Menu menu)
{
	menu.AddItem(ST_MENU_ROCKET, ST_MENU_ROCKET);
}

public void ST_OnMenuItemSelected(int client, const char[] info)
{
	if (StrEqual(info, ST_MENU_ROCKET, false))
	{
		vRocketMenu(client, 0);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (ST_IsCorePluginEnabled() && bIsValidClient(victim, ST_CHECK_INDEX|ST_CHECK_INGAME|ST_CHECK_ALIVE|ST_CHECK_KICKQUEUE) && damage > 0.0)
	{
		char sClassname[32];
		GetEntityClassname(inflictor, sClassname, sizeof(sClassname));

		if ((iRocketHitMode(attacker) == 0 || iRocketHitMode(attacker) == 1) && ST_IsTankSupported(attacker) && ST_IsCloneSupported(attacker, g_bCloneInstalled) && bIsSurvivor(victim))
		{
			if (StrEqual(sClassname, "weapon_tank_claw") || StrEqual(sClassname, "tank_rock"))
			{
				vRocketHit(victim, attacker, flRocketChance(attacker), iRocketHit(attacker), ST_MESSAGE_MELEE, ST_ATTACK_CLAW);
			}
		}
		else if ((iRocketHitMode(victim) == 0 || iRocketHitMode(victim) == 2) && ST_IsTankSupported(victim) && ST_IsCloneSupported(victim, g_bCloneInstalled) && bIsSurvivor(attacker))
		{
			if (StrEqual(sClassname, "weapon_melee"))
			{
				vRocketHit(attacker, victim, flRocketChance(victim), iRocketHit(victim), ST_MESSAGE_MELEE, ST_ATTACK_MELEE);
			}
		}
	}
}

public void ST_OnConfigsLoaded(const char[] savepath, bool main)
{
	KeyValues kvSuperTanks = new KeyValues("Super Tanks++");
	kvSuperTanks.ImportFromFile(savepath);

	for (int iIndex = ST_GetMinType(); iIndex <= ST_GetMaxType(); iIndex++)
	{
		char sTankName[33];
		Format(sTankName, sizeof(sTankName), "Tank #%i", iIndex);
		if (kvSuperTanks.JumpToKey(sTankName))
		{
			switch (main)
			{
				case true:
				{
					g_bTankConfig[iIndex] = false;

					g_iHumanAbility[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Human Ability", 0);
					g_iHumanAbility[iIndex] = iClamp(g_iHumanAbility[iIndex], 0, 1);
					g_iHumanAmmo[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Human Ammo", 5);
					g_iHumanAmmo[iIndex] = iClamp(g_iHumanAmmo[iIndex], 0, 9999999999);
					g_flHumanCooldown[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Human Cooldown", 30.0);
					g_flHumanCooldown[iIndex] = flClamp(g_flHumanCooldown[iIndex], 0.0, 9999999999.0);
					g_iRocketAbility[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Ability Enabled", 0);
					g_iRocketAbility[iIndex] = iClamp(g_iRocketAbility[iIndex], 0, 1);
					g_iRocketEffect[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Ability Effect", 0);
					g_iRocketEffect[iIndex] = iClamp(g_iRocketEffect[iIndex], 0, 7);
					g_iRocketMessage[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Ability Message", 0);
					g_iRocketMessage[iIndex] = iClamp(g_iRocketMessage[iIndex], 0, 3);
					g_flRocketChance[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Rocket Chance", 33.3);
					g_flRocketChance[iIndex] = flClamp(g_flRocketChance[iIndex], 0.0, 100.0);
					g_flRocketDelay[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Rocket Delay", 1.0);
					g_flRocketDelay[iIndex] = flClamp(g_flRocketDelay[iIndex], 0.1, 9999999999.0);
					g_iRocketHit[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Rocket Hit", 0);
					g_iRocketHit[iIndex] = iClamp(g_iRocketHit[iIndex], 0, 1);
					g_iRocketHitMode[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Rocket Hit Mode", 0);
					g_iRocketHitMode[iIndex] = iClamp(g_iRocketHitMode[iIndex], 0, 2);
					g_flRocketRange[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Rocket Range", 150.0);
					g_flRocketRange[iIndex] = flClamp(g_flRocketRange[iIndex], 1.0, 9999999999.0);
					g_flRocketRangeChance[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Rocket Range Chance", 15.0);
					g_flRocketRangeChance[iIndex] = flClamp(g_flRocketRangeChance[iIndex], 0.0, 100.0);
				}
				case false:
				{
					g_bTankConfig[iIndex] = true;

					g_iHumanAbility2[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Human Ability", g_iHumanAbility[iIndex]);
					g_iHumanAbility2[iIndex] = iClamp(g_iHumanAbility2[iIndex], 0, 1);
					g_iHumanAmmo2[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Human Ammo", g_iHumanAmmo[iIndex]);
					g_iHumanAmmo2[iIndex] = iClamp(g_iHumanAmmo2[iIndex], 0, 9999999999);
					g_flHumanCooldown2[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Human Cooldown", g_flHumanCooldown[iIndex]);
					g_flHumanCooldown2[iIndex] = flClamp(g_flHumanCooldown2[iIndex], 0.0, 9999999999.0);
					g_iRocketAbility2[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Ability Enabled", g_iRocketAbility[iIndex]);
					g_iRocketAbility2[iIndex] = iClamp(g_iRocketAbility2[iIndex], 0, 1);
					g_iRocketEffect2[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Ability Effect", g_iRocketEffect[iIndex]);
					g_iRocketEffect2[iIndex] = iClamp(g_iRocketEffect2[iIndex], 0, 7);
					g_iRocketMessage2[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Ability Message", g_iRocketMessage[iIndex]);
					g_iRocketMessage2[iIndex] = iClamp(g_iRocketMessage2[iIndex], 0, 3);
					g_flRocketChance2[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Rocket Chance", g_flRocketChance[iIndex]);
					g_flRocketChance2[iIndex] = flClamp(g_flRocketChance2[iIndex], 0.0, 100.0);
					g_flRocketDelay2[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Rocket Delay", g_flRocketDelay[iIndex]);
					g_flRocketDelay2[iIndex] = flClamp(g_flRocketDelay2[iIndex], 0.1, 9999999999.0);
					g_iRocketHit2[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Rocket Hit", g_iRocketHit[iIndex]);
					g_iRocketHit2[iIndex] = iClamp(g_iRocketHit2[iIndex], 0, 1);
					g_iRocketHitMode2[iIndex] = kvSuperTanks.GetNum("Rocket Ability/Rocket Hit Mode", g_iRocketHitMode[iIndex]);
					g_iRocketHitMode2[iIndex] = iClamp(g_iRocketHitMode2[iIndex], 0, 2);
					g_flRocketRange2[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Rocket Range", g_flRocketRange[iIndex]);
					g_flRocketRange2[iIndex] = flClamp(g_flRocketRange2[iIndex], 1.0, 9999999999.0);
					g_flRocketRangeChance2[iIndex] = kvSuperTanks.GetFloat("Rocket Ability/Rocket Range Chance", g_flRocketRangeChance[iIndex]);
					g_flRocketRangeChance2[iIndex] = flClamp(g_flRocketRangeChance2[iIndex], 0.0, 100.0);
				}
			}

			kvSuperTanks.Rewind();
		}
	}

	delete kvSuperTanks;
}

public void ST_OnPluginEnd()
{
	for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
	{
		if (bIsSurvivor(iSurvivor, ST_CHECK_INGAME|ST_CHECK_ALIVE|ST_CHECK_KICKQUEUE) && g_bRocket[iSurvivor])
		{
			SetEntityGravity(iSurvivor, 1.0);
		}
	}
}

public void ST_OnEventFired(Event event, const char[] name, bool dontBroadcast)
{
	if (StrEqual(name, "player_death"))
	{
		int iTankId = event.GetInt("userid"), iTank = GetClientOfUserId(iTankId);
		if (ST_IsTankSupported(iTank, ST_CHECK_INDEX|ST_CHECK_INGAME|ST_CHECK_KICKQUEUE))
		{
			vRemoveRocket(iTank);
		}
	}
}

public void ST_OnAbilityActivated(int tank)
{
	if (ST_IsTankSupported(tank) && (!ST_IsTankSupported(tank, ST_CHECK_FAKECLIENT) || iHumanAbility(tank) == 0) && ST_IsCloneSupported(tank, g_bCloneInstalled) && iRocketAbility(tank) == 1)
	{
		vRocketAbility(tank);
	}
}

public void ST_OnButtonPressed(int tank, int button)
{
	if (ST_IsTankSupported(tank, ST_CHECK_INDEX|ST_CHECK_INGAME|ST_CHECK_ALIVE|ST_CHECK_KICKQUEUE|ST_CHECK_FAKECLIENT) && ST_IsCloneSupported(tank, g_bCloneInstalled))
	{
		if (button & ST_SUB_KEY == ST_SUB_KEY)
		{
			if (iRocketAbility(tank) == 1 && iHumanAbility(tank) == 1)
			{
				if (!g_bRocket2[tank] && !g_bRocket3[tank])
				{
					vRocketAbility(tank);
				}
				else if (g_bRocket2[tank])
				{
					ST_PrintToChat(tank, "%s %t", ST_TAG3, "RocketHuman3");
				}
				else if (g_bRocket3[tank])
				{
					ST_PrintToChat(tank, "%s %t", ST_TAG3, "RocketHuman4");
				}
			}
		}
	}
}

public void ST_OnChangeType(int tank, bool revert)
{
	vRemoveRocket(tank);
}

static void vRemoveRocket(int tank)
{
	for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
	{
		if (bIsHumanSurvivor(iSurvivor, ST_CHECK_INGAME|ST_CHECK_ALIVE|ST_CHECK_KICKQUEUE) && g_bRocket[iSurvivor] && g_iRocketOwner[iSurvivor] == tank)
		{
			g_bRocket[iSurvivor] = false;
			g_iRocketOwner[iSurvivor] = 0;
		}
	}

	vReset3(tank);
}

static void vReset()
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsValidClient(iPlayer, ST_CHECK_INGAME|ST_CHECK_KICKQUEUE))
		{
			vReset3(iPlayer);

			g_iRocketOwner[iPlayer] = 0;
		}
	}
}

static void vReset2(int survivor)
{
	g_bRocket[survivor] = false;
	g_iRocketOwner[survivor] = 0;

	SetEntityGravity(survivor, 1.0);
}

static void vReset3(int tank)
{
	g_bRocket[tank] = false;
	g_bRocket2[tank] = false;
	g_bRocket3[tank] = false;
	g_bRocket4[tank] = false;
	g_bRocket5[tank] = false;
	g_iRocketCount[tank] = 0;
}

static void vRocketAbility(int tank)
{
	if (g_iRocketCount[tank] < iHumanAmmo(tank) && iHumanAmmo(tank) > 0)
	{
		g_bRocket4[tank] = false;
		g_bRocket5[tank] = false;

		float flRocketRange = !g_bTankConfig[ST_GetTankType(tank)] ? g_flRocketRange[ST_GetTankType(tank)] : g_flRocketRange2[ST_GetTankType(tank)],
			flRocketRangeChance = !g_bTankConfig[ST_GetTankType(tank)] ? g_flRocketRangeChance[ST_GetTankType(tank)] : g_flRocketRangeChance2[ST_GetTankType(tank)],
			flTankPos[3];

		GetClientAbsOrigin(tank, flTankPos);

		int iSurvivorCount;

		for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
		{
			if (bIsSurvivor(iSurvivor, ST_CHECK_INGAME|ST_CHECK_ALIVE|ST_CHECK_KICKQUEUE))
			{
				float flSurvivorPos[3];
				GetClientAbsOrigin(iSurvivor, flSurvivorPos);

				float flDistance = GetVectorDistance(flTankPos, flSurvivorPos);
				if (flDistance <= flRocketRange)
				{
					vRocketHit(iSurvivor, tank, flRocketRangeChance, iRocketAbility(tank), ST_MESSAGE_RANGE, ST_ATTACK_RANGE);

					iSurvivorCount++;
				}
			}
		}

		if (iSurvivorCount == 0)
		{
			if (ST_IsTankSupported(tank, ST_CHECK_FAKECLIENT) && iHumanAbility(tank) == 1)
			{
				ST_PrintToChat(tank, "%s %t", ST_TAG3, "RocketHuman5");
			}
		}
	}
	else if (ST_IsTankSupported(tank, ST_CHECK_FAKECLIENT) && iHumanAbility(tank) == 1)
	{
		ST_PrintToChat(tank, "%s %t", ST_TAG3, "RocketAmmo");
	}
}

static void vRocketHit(int survivor, int tank, float chance, int enabled, int messages, int flags)
{
	if (enabled == 1 && bIsSurvivor(survivor))
	{
		if (g_iRocketCount[tank] < iHumanAmmo(tank) && iHumanAmmo(tank) > 0)
		{
			if (GetRandomFloat(0.1, 100.0) <= chance && !g_bRocket[survivor])
			{
				int iFlame = CreateEntityByName("env_steam");
				if (!bIsValidEntity(iFlame))
				{
					return;
				}

				g_bRocket[survivor] = true;
				g_iRocketOwner[survivor] = tank;

				if (ST_IsTankSupported(tank, ST_CHECK_FAKECLIENT) && iHumanAbility(tank) == 1 && (flags & ST_ATTACK_RANGE) && !g_bRocket2[tank])
				{
					g_bRocket2[tank] = true;
					g_iRocketCount[tank]++;

					ST_PrintToChat(tank, "%s %t", ST_TAG3, "RocketHuman", g_iRocketCount[tank], iHumanAmmo(tank));
				}

				float flRocketDelay = !g_bTankConfig[ST_GetTankType(tank)] ? g_flRocketDelay[ST_GetTankType(tank)] : g_flRocketDelay2[ST_GetTankType(tank)],
					flPosition[3], flAngles[3];

				GetEntPropVector(survivor, Prop_Send, "m_vecOrigin", flPosition);
				flPosition[2] += 30.0;
				flAngles[0] = 90.0;
				flAngles[1] = 0.0;
				flAngles[2] = 0.0;

				DispatchKeyValue(iFlame, "spawnflags", "1");
				DispatchKeyValue(iFlame, "Type", "0");
				DispatchKeyValue(iFlame, "InitialState", "1");
				DispatchKeyValue(iFlame, "Spreadspeed", "10");
				DispatchKeyValue(iFlame, "Speed", "800");
				DispatchKeyValue(iFlame, "Startsize", "10");
				DispatchKeyValue(iFlame, "EndSize", "250");
				DispatchKeyValue(iFlame, "Rate", "15");
				DispatchKeyValue(iFlame, "JetLength", "400");

				SetEntityRenderColor(iFlame, 180, 70, 10, 180);

				TeleportEntity(iFlame, flPosition, flAngles, NULL_VECTOR);
				DispatchSpawn(iFlame);
				vSetEntityParent(iFlame, survivor);

				iFlame = EntIndexToEntRef(iFlame);
				vDeleteEntity(iFlame, 3.0);

				EmitSoundToAll(SOUND_FIRE, survivor, _, _, _, 1.0);

				DataPack dpRocketLaunch;
				CreateDataTimer(flRocketDelay, tTimerRocketLaunch, dpRocketLaunch, TIMER_FLAG_NO_MAPCHANGE);
				dpRocketLaunch.WriteCell(GetClientUserId(survivor));
				dpRocketLaunch.WriteCell(GetClientUserId(tank));
				dpRocketLaunch.WriteCell(ST_GetTankType(tank));
				dpRocketLaunch.WriteCell(enabled);

				DataPack dpRocketDetonate;
				CreateDataTimer(flRocketDelay + 1.5, tTimerRocketDetonate, dpRocketDetonate, TIMER_FLAG_NO_MAPCHANGE);
				dpRocketDetonate.WriteCell(GetClientUserId(survivor));
				dpRocketDetonate.WriteCell(GetClientUserId(tank));
				dpRocketDetonate.WriteCell(ST_GetTankType(tank));
				dpRocketDetonate.WriteCell(enabled);
				dpRocketDetonate.WriteCell(messages);

				int iRocketEffect = !g_bTankConfig[ST_GetTankType(tank)] ? g_iRocketEffect[ST_GetTankType(tank)] : g_iRocketEffect2[ST_GetTankType(tank)];
				vEffect(survivor, tank, iRocketEffect, flags);
			}
			else if ((flags & ST_ATTACK_RANGE) && !g_bRocket2[tank])
			{
				if (ST_IsTankSupported(tank, ST_CHECK_FAKECLIENT) && iHumanAbility(tank) == 1 && !g_bRocket4[tank])
				{
					g_bRocket4[tank] = true;

					ST_PrintToChat(tank, "%s %t", ST_TAG3, "RocketHuman2");
				}
			}
		}
		else if (ST_IsTankSupported(tank, ST_CHECK_FAKECLIENT) && iHumanAbility(tank) == 1 && !g_bRocket5[tank])
		{
			g_bRocket5[tank] = true;

			ST_PrintToChat(tank, "%s %t", ST_TAG3, "RocketAmmo");
		}
	}
}

static float flHumanCooldown(int tank)
{
	return !g_bTankConfig[ST_GetTankType(tank)] ? g_flHumanCooldown[ST_GetTankType(tank)] : g_flHumanCooldown2[ST_GetTankType(tank)];
}

static float flRocketChance(int tank)
{
	return !g_bTankConfig[ST_GetTankType(tank)] ? g_flRocketChance[ST_GetTankType(tank)] : g_flRocketChance2[ST_GetTankType(tank)];
}

static int iHumanAbility(int tank)
{
	return !g_bTankConfig[ST_GetTankType(tank)] ? g_iHumanAbility[ST_GetTankType(tank)] : g_iHumanAbility2[ST_GetTankType(tank)];
}

static int iHumanAmmo(int tank)
{
	return !g_bTankConfig[ST_GetTankType(tank)] ? g_iHumanAmmo[ST_GetTankType(tank)] : g_iHumanAmmo2[ST_GetTankType(tank)];
}

static int iRocketAbility(int tank)
{
	return !g_bTankConfig[ST_GetTankType(tank)] ? g_iRocketAbility[ST_GetTankType(tank)] : g_iRocketAbility2[ST_GetTankType(tank)];
}

static int iRocketHit(int tank)
{
	return !g_bTankConfig[ST_GetTankType(tank)] ? g_iRocketHit[ST_GetTankType(tank)] : g_iRocketHit2[ST_GetTankType(tank)];
}

static int iRocketHitMode(int tank)
{
	return !g_bTankConfig[ST_GetTankType(tank)] ? g_iRocketHitMode[ST_GetTankType(tank)] : g_iRocketHitMode2[ST_GetTankType(tank)];
}

public Action tTimerRocketLaunch(Handle timer, DataPack pack)
{
	pack.Reset();

	int iSurvivor = GetClientOfUserId(pack.ReadCell());
	if (!ST_IsCorePluginEnabled() || !bIsSurvivor(iSurvivor))
	{
		g_bRocket[iSurvivor] = false;
		g_iRocketOwner[iSurvivor] = 0;

		return Plugin_Stop;
	}

	int iTank = GetClientOfUserId(pack.ReadCell()), iType = pack.ReadCell(), iRocketEnabled = pack.ReadCell();
	if (!ST_IsTankSupported(iTank) || !ST_IsTypeEnabled(ST_GetTankType(iTank)) || !ST_IsCloneSupported(iTank, g_bCloneInstalled) || iType != ST_GetTankType(iTank) || iRocketEnabled == 0 || !g_bRocket[iSurvivor])
	{
		g_bRocket2[iTank] = false;

		vReset2(iSurvivor);

		return Plugin_Stop;
	}

	float flVelocity[3];
	flVelocity[0] = 0.0;
	flVelocity[1] = 0.0;
	flVelocity[2] = 800.0;

	EmitSoundToAll(SOUND_EXPLOSION, iSurvivor, _, _, _, 1.0);
	EmitSoundToAll(SOUND_LAUNCH, iSurvivor, _, _, _, 1.0);

	TeleportEntity(iSurvivor, NULL_VECTOR, NULL_VECTOR, flVelocity);
	SetEntityGravity(iSurvivor, 0.1);

	return Plugin_Continue;
}

public Action tTimerRocketDetonate(Handle timer, DataPack pack)
{
	pack.Reset();

	int iSurvivor = GetClientOfUserId(pack.ReadCell());
	if (!ST_IsCorePluginEnabled() || !bIsSurvivor(iSurvivor))
	{
		g_bRocket[iSurvivor] = false;
		g_iRocketOwner[iSurvivor] = 0;

		return Plugin_Stop;
	}

	int iTank = GetClientOfUserId(pack.ReadCell()), iType = pack.ReadCell(), iRocketEnabled = pack.ReadCell();
	if (!ST_IsTankSupported(iTank) || !ST_IsTypeEnabled(ST_GetTankType(iTank)) || !ST_IsCloneSupported(iTank, g_bCloneInstalled) || iType != ST_GetTankType(iTank) || iRocketEnabled == 0 || !g_bRocket[iSurvivor])
	{
		g_bRocket2[iTank] = false;

		vReset2(iSurvivor);

		return Plugin_Stop;
	}

	float flPosition[3];
	GetClientAbsOrigin(iSurvivor, flPosition);

	TE_SetupExplosion(flPosition, g_iRocketSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();

	ForcePlayerSuicide(iSurvivor);
	SetEntityGravity(iSurvivor, 1.0);

	int iMessage = pack.ReadCell(), iRocketMessage = !g_bTankConfig[ST_GetTankType(iTank)] ? g_iRocketMessage[ST_GetTankType(iTank)] : g_iRocketMessage2[ST_GetTankType(iTank)];
	if (iRocketMessage & iMessage)
	{
		char sTankName[33];
		ST_GetTankName(iTank, sTankName);
		ST_PrintToChatAll("%s %t", ST_TAG2, "Rocket", sTankName, iSurvivor);
	}

	g_bRocket[iSurvivor] = false;
	g_bRocket2[iTank] = false;
	g_iRocketOwner[iSurvivor] = 0;

	if (ST_IsTankSupported(iTank, ST_CHECK_FAKECLIENT) && iHumanAbility(iTank) == 1 && (iMessage & ST_MESSAGE_RANGE) && !g_bRocket3[iTank])
	{
		g_bRocket3[iTank] = true;

		ST_PrintToChat(iTank, "%s %t", ST_TAG3, "RocketHuman6");

		if (g_iRocketCount[iTank] < iHumanAmmo(iTank) && iHumanAmmo(iTank) > 0)
		{
			CreateTimer(flHumanCooldown(iTank), tTimerResetCooldown, GetClientUserId(iTank), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			g_bRocket3[iTank] = false;
		}
	}

	return Plugin_Continue;
}

public Action tTimerResetCooldown(Handle timer, int userid)
{
	int iTank = GetClientOfUserId(userid);
	if (!ST_IsTankSupported(iTank, ST_CHECK_INDEX|ST_CHECK_INGAME|ST_CHECK_ALIVE|ST_CHECK_KICKQUEUE|ST_CHECK_FAKECLIENT) || !ST_IsCloneSupported(iTank, g_bCloneInstalled) || !g_bRocket3[iTank])
	{
		g_bRocket3[iTank] = false;

		return Plugin_Stop;
	}

	g_bRocket3[iTank] = false;

	ST_PrintToChat(iTank, "%s %t", ST_TAG3, "RocketHuman7");

	return Plugin_Continue;
}
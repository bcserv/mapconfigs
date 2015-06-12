/*
	12.06.2015 Updated to 1.3a for Sourcemod 1.7.2 by Nerus.
*/

#include <sourcemod>
#include <sdktools>

// enforce semicolons after each code statement
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.3a"

#define CONFIG_DIR "sourcemod/map-cfg/"



/*****************************************************************


		P L U G I N   I N F O


*****************************************************************/

public Plugin myinfo = {
	name = "Map configs",
	author = "Berni updated by Nerus",
	description = "Map specific configs execution with prefix support",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=607079"
}



/*****************************************************************


		G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
Handle mc_version = INVALID_HANDLE;

// Misc



/*****************************************************************


		F O R W A R D   P U B L I C S


*****************************************************************/

public void OnPluginStart() {
	
	// ConVars
	mc_version = CreateConVar("mc_version", PLUGIN_VERSION, "Map Configs plugin version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(mc_version, PLUGIN_VERSION);
}

public void OnAutoConfigsBuffered() {
	ExecuteMapSpecificConfigs();
}



/*****************************************************************


		P L U G I N   F U N C T I O N S


*****************************************************************/

public void ExecuteMapSpecificConfigs() {
	
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	int mapSepPos = FindCharInString(currentMap, '/', true);
	if (mapSepPos != -1) {
		strcopy(currentMap, sizeof(currentMap), currentMap[mapSepPos+1]);
	}

	LogMessage("Searching specific configs for %s", currentMap);

	Handle adt_configs = CreateArray(PLATFORM_MAX_PATH);

	char cfgdir[PLATFORM_MAX_PATH];
	
	Format(cfgdir, sizeof(cfgdir), "cfg/%s", CONFIG_DIR);
	
	Handle dir = OpenDirectory(cfgdir);
	
	if (dir == INVALID_HANDLE) {
		
		LogMessage("Error iterating folder %s, folder doesn't exist !", cfgdir);
		return;
	}
	
	char configFile[PLATFORM_MAX_PATH];
	char explode[2][64];
	FileType fileType;
	
	while (ReadDirEntry(dir, configFile, sizeof(configFile), fileType)) {
		if (fileType == FileType_File) {
			
			ExplodeString(configFile, ".", explode, 2, sizeof(explode[]));
			
			if (StrEqual(explode[1], "cfg", false)) {
				
				if (strncmp(currentMap, explode[0], strlen(explode[0]), false) == 0) {
					PushArrayString(adt_configs, configFile);
				}
			}
		}
	}
	
	SortADTArray(adt_configs, Sort_Ascending, Sort_String);
	
	int size = GetArraySize(adt_configs);
	
	for (int i=0; i<size; ++i) {
		GetArrayString(adt_configs, i, configFile, sizeof(configFile));
		
		LogMessage("Executing map specific config: %s", configFile);
		
		ServerCommand("exec %s%s", CONFIG_DIR, configFile);
	}
	
	CloseHandle(dir);
	CloseHandle(adt_configs);
	
	return;
}

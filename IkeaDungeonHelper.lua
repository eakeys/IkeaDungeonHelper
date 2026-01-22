-- Namespace for the addon data (to avoid interfering with other addons)
IDH = {
	name = "IkeaDungeonHelper",

	savedVars = {},
	
	defaultVars = {
		OffsetX = 600, OffsetY = 100,
		trackAchievs = {},
		trackNormalAchievsOnVet = false,

		goodColour = { 0, 1, 0, 1 },
		badColour = { 1, 0, 0, 1 }, 
	},
	
	variableVersion = 1,

	ZoneIDs = {
		RUINS_OF_MAZZATUN = 843,
		CRADLE_OF_SHADOWS = 848,
		
		BLOODROOT_FORGE = 973,
		FALKREATH_HOLD = 974,
		
		FANG_LAIR = 1009,
		SCALECALLER_PEAK = 1010,
		
		MOON_HUNTER_KEEP = 1052,
		MARCH_OF_SACRIFICES = 1055,
		
		FROSTVAULT = 1080,
		DEPTHS_OF_MALATAR = 1081,
		
		MOONGRAVE_FANE = 1122,
		LAIR_OF_MAARSELOK = 1123,
		
		ICEREACH = 1152,
		UNHALLOWED_GRAVE = 1153,
		
		STONE_GARDEN = 1197,
		CASTLE_THORN = 1201,
		
		BLACK_DRAKE_VILLA = 1228,
		THE_CAULDRON = 1229,
		
		RED_PETAL_BASTION = 1267,
		THE_DREAD_CELLAR = 1268,
		
		CORAL_AERIE = 1301,
		SHIPWRIGHTS_REGRET = 1302,

		EARTHEN_ROOT_ENCLAVE = 1360,
		GRAVEN_DEEP = 1361,

		BAL_SUNNAR = 1389,
		SCRIVENERS_HALL = 1390,

		OATHSWORN_PIT = 1470,
		BEDLAM_VEIL = 1471,

		EXILED_REDOUBT = 1496,
		LEP_SECLUSA = 1497,

		NAJ_CALDEESH = 1551,
		BLACK_GEM_FOUNDRY = 1552,
	},
	
	ShortNames = {
		[843] = "RoM", 	[848] = "CoS",
		[973] = "BRF", 	[974] = "FH",
		[1009] = "FL", 	[1010] = "SCP",
		[1052] = "MHK",	[1055] = "MoS",
		[1080] = "FV",	[1081] = "DoM",
		[1122] = "MGF",	[1123] = "LoM",
		[1152] = "IR",	[1153] = "UG",
		[1197] = "SG",	[1201] = "CT",
		[1228] = "BDV",	[1229] = "TC",
		[1267] = "RPB",	[1268] = "TDC",
		[1301] = "CA",	[1302] = "SR",
		[1360] = "ERE", [1361] = "GD",
		[1389] = "BS",	[1390] = "SH",
		[1470] = "OP",	[1471] = "BV",
		[1496] = "ER",	[1497] = "LS",
		[1551] = "NC",	[1552] = "BGF",
	},
	
	-- Note: there are other 'avoidance' achievements that are not
	-- planned for implementation, as they are easy to see (e.g. ones that
	-- cause an instant death or noticeable knockback effect, such as the
	-- wraiths in Fang Lair HM or getting teleported on the Indrik fight 
	-- in vMoS).
	AchievementIDs = {
		
		-- Shadows of the Hist
		SAPPED_SLUDGE_SLINGERS = 1514,
		VENOMOUS_EVASION = 1536,
		
		-- Horns of the Reach
		COOLING_YOUR_HEELS = 1816,
		WILDLIFE_SANCTUARY = 1819,
		
		-- Dragon Bones
		FUNGI_FREE = 1968,
		STARVED_SCARABS = 1969,
		NONPLUSSED = 1972,
		PUSTULENT_PROBLEMS = 1984,
		WATCH_YOUR_STEP = 1989,
		
		-- Wolfhunter
		ON_A_SHORT_LEASH = 2300,
		BLOODY_MESS = 2307,
		SIDESTEPPING_STRANGLERS = 2308,
		ROOT_OF_THE_PROBLEM = 2309,
		STALWART_SISTERHOOD = 2310,
		ELEMENT_OF_SURPRISE = 2311,
		
		-- Wrathstone
		-- None planned.
		
		-- Scalebreaker
		DUCK_AND_WEAVE = 2576,
		
		-- Harrowstorm
		SPIT_TAKE = 2672,
		SHATTERED_SHIELDS = 2681,
		
		-- Stonethorn
		SPORE_STOMPER = 2823,
		
		-- Flames of Ambition
		SHAKE_IT_UP = 2882,
		
		-- Waking Flame
		STAMPEDE_SHUFFLE = 3037,
		DREADLESS_RUNNER = 3043,
		
		-- Ascending Tide
		SUMMERSET_PRESERVATION_SOCIETY = 3125,

		-- Lost Depths
		CONTAGION_CONTAINED = 3384,

		-- Fallen Banners
		TACTICAL_RECKLESSNESS = 4144,
		UNSINGED_BOOTS = 4252,
		UNBURNT_AND_UNSCATHED = 4138,

		-- Feast of Shadows
		TOTAL_SELF_CONTROL = 4319,
		PARCHED_STONEWORK = 4320,
		FIGHT_THROUGH_PAIN = 4322,		
	},
	
	AchievementsSupported = {
		-- Shadows of the Hist (only Cradle of Shadows)
		[1536] = true, 		-- Venomous Evasion
		
		-- Horns of the Reach (only Bloodroot Forge)
		[1816] = true,		-- Cooling your Heels
		[1819] = true,		-- Wildlife Sanctuary
		
		-- Dragon Bones
		[1968] = false,		-- Fungi Free. Not implemented
		[1969] = true,		-- Starved Scarabs. Work in progress
		[1972] = true,		-- Nonplussed. Work in progress
		[1984] = false,		-- Pustulent Problems. Not implemented
		[1989] = false,		-- Watch your step. Not implemented

		-- ...

		-- Lost Depths
		[3384] = true,

		-- Feast of Shadows
	},

	AchievementTrackModes = {
		DISABLED = 0,
		CHAT = 1,
		ON_SCREEN = 2,

		["Disabled"] = 0,
		["Track in chat"] = 1,
		["Track with UI"] = 2,
	},

	zoneID = 0,
	prevZoneID = 0,
	activeMapName = "",
	isVet = false,
	endUnloadCallback = nil,

	GetTrackingMode = function(achievId, canBeDoneOnNormal)
		if (not IDH.isVet and not canBeDoneOnNormal) or (IDH.isVet and canBeDoneOnNormal and not IDH.savedVars.trackNormalAchievsOnVet) then
			return IDH.AchievementTrackModes.DISABLED
		end
		return IDH.AchievementTrackModes[IDH.savedVars.trackAchievs[achievId] or "Disabled"]
	end,
}

IDH.ShowProminentAlert = function(msg, sound, volume, duration)
	for i=1, volume or 1 do
		PlaySound(sound or SOUNDS.DUEL_START)
	end
	IDH_Prominent_Text:SetText(msg)
	IDH_Prominent:SetHidden(false)
	IDH.prominentAlertRefCount = (IDH.prominentAlertRefCount or 0) + 1
	zo_callLater(function() 
		IDH.prominentAlertRefCount = IDH.prominentAlertRefCount - 1
		if IDH.prominentAlertRefCount == 0 then
			IDH_Prominent:SetHidden(true)
		end
	end, duration or 2500)
end


--- UI Management nonsense ---

------ End of UI management ----

local function OnLoadUI(eventCode, initial)
	IDH.prevZoneID = IDH.zoneID
	IDH.zoneID = GetZoneId(GetUnitZoneIndex("player"))
	IDH.isVet = GetCurrentZoneDungeonDifficulty() == DUNGEON_DIFFICULTY_VETERAN

	-- for debugging so I dont need to play vet :p
	-- IDH.isVet = true

	-- this can change if you open the map and scroll but resets with every load screen, so this should always be correct
	IDH.activeMapName = GetMapName()

	if IDH.endUnloadCallback then
		IDH.endUnloadCallback()
		IDH.endUnloadCallback = nil
	end
	
	local namespace = nil
	
	if IDH.ShortNames[IDH.zoneID] then
		namespace = _G["IDH_" .. IDH.ShortNames[IDH.zoneID]]
	end
	
	if namespace and namespace.Load then
		namespace.Load()
	else
		IDH_UI:SetHidden(true)
	end
end

local function OnUnloadUI(eventCode)
	local namespace = nil
	if IDH.ShortNames[IDH.zoneID] then
		namespace = _G["IDH_" .. IDH.ShortNames[IDH.zoneID]]
	end

	if namespace then
		if namespace.BeginUnload then
			namespace.BeginUnload()
		end

		if namespace.EndUnload then
			IDH.endUnloadCallback = namespace.EndUnload
		end
	end
end


local function OnAddOnLoaded(event, addonName)
	if addonName ~= IDH.name then return end
	
	-- Load default achievements to track as those we don't have.
	for key, value in pairs(IDH.AchievementIDs) do
		name, desc, pts, ico, done = GetAchievementInfo(value)
		IDH.defaultVars.trackAchievs[value] = done and "Disabled" or "Chat"
	end
	
	IDH.savedVars = ZO_SavedVars:NewAccountWide("IDHSavedVariables", IDH.variableVersion, nil, IDH.defaultVars)

	EVENT_MANAGER:RegisterForEvent(IDH.name, EVENT_PLAYER_ACTIVATED, OnLoadUI)
	EVENT_MANAGER:RegisterForEvent(IDH.name, EVENT_PLAYER_DEACTIVATED, OnUnloadUI)
	
	-- Handle the settings menu stuff --
	IDH.CreateSettingsMenu()
	
	-- UI management nonsense again --
	IDH_UI:ClearAnchors()
	IDH_UI:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, IDH.savedVars.OffsetX, IDH.savedVars.OffsetY)

	IDH_Timer_Ctrl:ClearAnchors()
	IDH_Timer_Ctrl:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, IDH.savedVars.TimerX, IDH.savedVars.TimerY)

	IDH_Prominent:ClearAnchors()
	IDH_Prominent:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, IDH.savedVars.ProminentX or 1000, IDH.savedVars.ProminentY or 500)
	
	-- Unregister addon load.
	EVENT_MANAGER:UnregisterForEvent(IDH.name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(IDH.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
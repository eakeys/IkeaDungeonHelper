IDH_CoS = {
	atVelidreth = 0,
	numHitsYou = 0,
	numHitsOthers = 0,
	
	bossNumber = 0,
}

local function UpdateText()
	you = IDH_CoS.numHitsYou
	oth = IDH_CoS.numHitsOthers
	if you == 0 and oth == 0 then
		IDH_UILineII:SetText("OK")
		IDH_UILineII:SetColor(unpack(IDH.savedVars.goodColour))
	else
		IDH_UILineII:SetText("Need to reset")
		IDH_UILineII:SetColor(unpack(IDH.savedVars.badColour))
	end
end

local function OnCombatEvent_VenomSac(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
	
	-- If you want to debug/find out information about a combat event, just copy the below:
	--df("Combat event. Deta: eventCode = %d, result = %d, abilityName = %s, abilityActionSlotType = %d, sourceName = %s, sourceType = %d, targetName = %s, targetType = %d, hitValue = %d, powerType = %d, damageType = %d, sourceUnitId = %d, targetUnitId = %d, abilityId = %d",
	--	eventCode, result, abilityName, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, sourceUnitId, targetUnitId, abilityId)
	
	-- Open Q: should we include this check? i.e. if you're hit by a sac during ult suck mechanic, does that invalidate the achievement?
	-- if hitValue == 0 then return end
	
	-- Check if it was you or a groupmate.
	if targetType == COMBAT_UNIT_TYPE_PLAYER then
		IDH_CoS.numHitsYou = IDH_CoS.numHitsYou + 1
	elseif targetType == COMBAT_UNIT_TYPE_GROUP then
		IDH_CoS.numHitsOthers = IDH_CoS.numHitsOthers + 1
	end
	
	local mode = IDH.GetTrackingMode(IDH.AchievementIDs.VENOMOUS_EVASION, true)

	if mode == IDH.AchievementTrackModes.ON_SCREEN then
		UpdateText()
	elseif mode == IDH.AchievementTrackModes.CHAT then
		d("|cffff00[IDH] Failed |H1:achievement:1536:0:0|h|h: player hit by venom sac (total: " .. tostring(IDH_CoS.numHitsYou + IDH_CoS.numHitsOthers) .. " hits)")
	end
	
end

local function OnChangeCombatState(eventCode, inCombat)
	-- If you just left combat, then reset everything.
	if inCombat == false then
		IDH_CoS.numHitsYou = 0
		IDH_CoS.numHitsOthers = 0
		UpdateText()
	end
	
	-- Show the addon if you haven't killed velidreth yet, but you've gotten to her.
	-- (and if you want to track)
	if inCombat and GetUnitName("boss1") == "Velidreth" and IDH.GetTrackingMode(IDH.AchievementIDs.VENOMOUS_EVASION, true) == IDH.AchievementTrackModes.ON_SCREEN then
		IDH_UI:SetHidden(false)
		UpdateText()
	elseif inCombat == false then
		IDH_UI:SetHidden(true)
	end
end

IDH_CoS.Load = function()
	EVENT_MANAGER:RegisterForEvent("IDH_CoS_VenomSac", EVENT_COMBAT_EVENT, OnCombatEvent_VenomSac)
	EVENT_MANAGER:AddFilterForEvent("IDH_CoS_VenomSac", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 79443)
	
	-- Leaving combat (possibly due to death) should reset the tracker.
	EVENT_MANAGER:RegisterForEvent("IDH_CoS", EVENT_PLAYER_COMBAT_STATE, OnChangeCombatState)
	
	-- Also set up the top line of UI component, but not if you're in combat.
	IDH_UILineI:SetText("Venomous Evasion")
	UpdateText()
	d("[IDH] Finished loading Cradle of Shadows.")
end

-- Using EndUnload because we need to know the new zone id and location.
IDH_CoS.EndUnload = function()
	-- If you're not in combat, then we can unload everything
	-- (If you are, it's *probably* because you're being banished
	-- to the catacombs)

	local zone, x, y, z = GetUnitRawWorldPosition("player")

	-- The threshold for being in Velidreth's lair, as opposed to, say, the beginning or mid-way through.
	if zone == IDH.ZoneIDs.CRADLE_OF_SHADOWS and x >= 60000 then return end

	EVENT_MANAGER:UnregisterForEvent("IDH_CoS_VenomSac", EVENT_COMBAT_EVENT)
	EVENT_MANAGER:UnregisterForEvent("IDH_CoS", EVENT_PLAYER_COMBAT_STATE)
		-- Also reset data in case you go in a second time.
	IDH_CoS.atVelidreth = 0
	IDH_CoS.numHitsYou = 0
	IDH_CoS.numHitsOthers = 0

	d("[IDH] Unloading Cradle of Shadows, at new location " .. x .. ", " .. y .. ", " .. z)
end
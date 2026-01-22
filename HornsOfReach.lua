IDH_BRF = {
	bossNumber = 0,
	
	
	hrAdds = {},
	
	lavaTicks = 0,
	shalkFail = false
}

local function InvalidateWildlifeSanctuary()
    local mode = IDH.GetTrackingMode(IDH.AchievementIDs.WILDLIFE_SANCTUARY, false)
    if mode == IDH.AchievementTrackModes.ON_SCREEN then
        IDH_UILineII:SetText("Need to reset")
        IDH.ColourLineII(false)
    elseif mode == IDH.AchievementTrackModes.CHAT then
        d("|cffff00[IDH] Failed |H1:achievement:1819:0:0|h|h: add stayed in forest for 3s")
    end
end

local function HagravenCombatEvent(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
	
	if result == ACTION_RESULT_EFFECT_GAINED_DURATION then -- Entered the forest
		IDH_BRF.hrAdds[targetUnitId] = 1
		zo_callLater(function()
			if IDH_BRF.hrAdds[targetUnitId] then
				InvalidateWildlifeSanctuary()
			end
		end, 3000)
	elseif result == ACTION_RESULT_EFFECT_FADED then -- Left the forest
		IDH_BRF.hrAdds[targetUnitId] = nil
	end
end

local function OnLavaHit(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
	
	if hitValue == 0 or not IDH.savedVars.trackAchievs[IDH.AchievementIDs.COOLING_YOUR_HEELS] then return end
	
	-- If we get this far, then the player has been hit by the molten nirncrux
	IDH_BRF.lavaTicks = IDH_BRF.lavaTicks + 1
	
    local mode = IDH.GetTrackingMode(IDH.AchievementIDs.COOLING_YOUR_HEELS, false)
    if mode == IDH.AchievementTrackModes.ON_SCREEN then
        -- Update the text
        IDH_UI:SetHidden(false)
        IDH_UILineI:SetText("")
        IDH_UILineII:SetText("Lava ticks: " .. IDH_BRF.lavaTicks)
        IDH.ColourLineII(false)
    elseif mode == IDH.AchievementTrackModes.CHAT then
        d(zo_strformat("|cffff00[IDH] Failed |H1:achievement:1816:0:0|h|h: took <<1[no ticks/one tick/$d ticks]>> of lava damage in total.", IDH_BRF.lavaTicks))
    end
end

local function ForgeChangeCombatState(eventcode, state)
	-- Entering combat?
	if state then
		-- Check if we're at an appropriate point.
		bossName = GetUnitName("boss1")
		if bossName == "Caillaoife" and IDH.GetTrackingMode(IDH.AchievementIDs.WILDLIFE_SANCTUARY, false) ~= IDH.AchievementTrackModes.DISABLED then
			IDH_BRF.bossNumber = 2
			
			EVENT_MANAGER:RegisterForEvent("IDH_BRF_Hagraven", EVENT_COMBAT_EVENT, HagravenCombatEvent)
			EVENT_MANAGER:AddFilterForEvent("IDH_BRF_Hagraven", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 90129)
			
            local mode = IDH.GetTrackingMode(IDH.AchievementIDs.WILDLIFE_SANCTUARY, false)

            if mode == IDH.AchievementTrackModes.ON_SCREEN then
                IDH_UI:SetHidden(false)
                IDH_UILineI:SetText("Wildlife Sanctuary")
                IDH_UILineII:SetText("OK!")
                IDH.ColourLineII(true)
            end
		end
	else -- Exiting combat
		if IDH_BRF.bossNumber == 2 then
			-- Unregister events
			-- TODO: shouldn't this id be IDH_BRF_Hagraven?
			EVENT_MANAGER:UnregisterForEvent("IDH_BRF", EVENT_COMBAT_EVENT)
			IDH_BRF.bossNumber = 0
			IDH_UI:SetHidden(true)
		end
	end
end

IDH_BRF.Load = function()
	-- Do nothing unless vet
	if not IDH.isVet then return end
	EVENT_MANAGER:RegisterForEvent("IDH_BRF", EVENT_PLAYER_COMBAT_STATE, ForgeChangeCombatState)
	

	EVENT_MANAGER:RegisterForEvent("IDH_BRF_Lava", EVENT_COMBAT_EVENT, OnLavaHit)
	EVENT_MANAGER:AddFilterForEvent("IDH_BRF_Lava", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 87303) -- molten nirncrux
    -- lava achievement is for self only
	EVENT_MANAGER:AddFilterForEvent("IDH_BRF_Lava", EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
end

-- lava is persistent throughout the dungeon, so it's not enough to unload.
IDH_BRF.EndUnload = function()
	if not IDH.isVet then return end

	EVENT_MANAGER:UnregisterForEvent("IDH_BRF", EVENT_PLAYER_COMBAT_STATE)
	EVENT_MANAGER:UnregisterForEvent("IDH_BRF_Lava", EVENT_PLAYER_COMBAT_STATE)

    -- Only if we actually left (or ported into a new version): reset the lava tick counter
    local zone, x, y, z = GetUnitRawWorldPosition("player")
    if zone ~= IDH.ZoneIDs.BLOODROOT_FORGE or z >= 90000 then
        IDH_BRF.lavaTicks = 0
        IDH_BRF.bossNumber = 0
    end
end
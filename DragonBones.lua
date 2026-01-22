IDH_FL = {
	bossNumber = 0,
	
	spectreCount = 0,
	acidCount = 0,
}

local function HitBySpectre(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
	
	-- A few sanity checks that probably aren't necessary
	if hitValue == nil or hitValue == 0 then return end
    if targetType ~= COMBAT_UNIT_TYPE_GROUP and targetType ~= COMBAT_UNIT_TYPE_PLAYER then
		return
	end
	
    local mode = IDH.GetTrackingMode(IDH.AchievementIDs.NONPLUSSED)

	IDH_FL.spectreCount = IDH_FL.spectreCount + 1

    if mode == IDH.AchievementTrackModes.ON_SCREEN then
        IDH_UILineII:SetText("Need to reset!")
        IDH.ColourLineII(false)
    elseif mode == IDH.AchievementTrackModes.CHAT then
        -- Don't send this more than once (normally we get a bunch of them back to back, just annoying)
        if IDH_FL.spectreCount == 1 then 
            d("|cffff00[IDH] Failed |H1:achievement:1972:0:0|h|h: player hit by spectre")
        end
    end
end

local function HitByAcid(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
	
	-- Should hit a player (this bit is confusing, as there are lots
	-- of effects called Degenerative Acid. But I think this is the one that actually
	-- hits someone; another one is a scarab applying a buff to itself.
	-- I might be (read: am probably) wrong, and really need to test this.)
	if targetType ~= COMBAT_UNIT_TYPE_GROUP and targetType ~= COMBAT_UNIT_TYPE_PLAYER then
		return
	end

    local mode = IDH.GetTrackingMode(IDH.AchievementIDs.STARVED_SCARABS)
	IDH_FL.acidCount = IDH_FL.acidCount + 1

    if mode == IDH.AchievementTrackModes.ON_SCREEN then
        IDH_UILineII:SetText("Need to reset!")
        IDH.ColourLineII(false)
    elseif mode == IDH.AchievementTrackModes.CHAT then
        d("|cffff00[IDH] Failed |H1:achievement:1969:0:0|h|h: player hit by acid")
    end
end

local function OnChangeCombatState(eventcode, state)
    local relAchIDs = {
        ["Cadaverous Bear"] = IDH.AchievementIDs.FUNGI_FREE,
        ["Ulfnor"] = IDH.AchievementIDs.NONPLUSSED,
        ["Thurvokun"] = IDH.AchievementIDs.STARVED_SCARABS,
        ["Orryn the Black"] = IDH.AchievementIDs.STARVED_SCARABS,
    }

    local bossIndices = {
        ["Cadaverous Bear"] = 2,
        ["Ulfnor"] = 4,
        ["Thurvokun"] = 5,
        ["Orryn the Black"] = 5,
    }

	-- Just entered combat
	if state then
		-- Check the boss we're on.
		local bossName = GetUnitName("boss1")
        local mode = IDH.GetTrackingMode(relAchIDs[bossName])
        IDH_FL.bossNumber = bossIndices[bossName] or 0

        if IDH_FL.bossNumber == 2 then
            -- not implemented
        elseif IDH_FL.bossNumber == 4 then
            EVENT_MANAGER:RegisterForEvent("IDH_FL_SpectreHit", EVENT_COMBAT_EVENT, HitBySpectre)
			EVENT_MANAGER:AddFilterForEvent("IDH_FL_SpectreHit", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 98598)

            if mode == IDH.AchievementTrackModes.ON_SCREEN then
                IDH_UI:SetHidden(false)
                IDH_UILineI:SetText("Nonplussed")
                IDH_UILineII:SetText("OK")
                IDH.ColourLineII(true)
            end

        elseif IDH_FL.bossNumber == 5 then
            EVENT_MANAGER:RegisterForEvent("IDH_FL_Acid", EVENT_COMBAT_EVENT, HitByAcid)
            EVENT_MANAGER:AddFilterForEvent("IDH_FL_Acid", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 97201)

            if mode == IDH.AchievementTrackModes.ON_SCREEN then
                IDH_UI:SetHidden(false)
                IDH_UILineI:SetText("Starved Scarabs")
                IDH_UILineII:SetText("OK")
                IDH.ColourLineII(true)
            end
        end
	-- Just left combat. Clean up.
	else
		if IDH_FL.bossNumber == 2 then
			-- doesnt do anything atm
		elseif IDH_FL.bossNumber == 4 then
			EVENT_MANAGER:UnregisterForEvent("IDH_FL_SpectreHit", EVENT_COMBAT_EVENT)
			IDH_FL.spectreCount = 0
		elseif IDH_FL.bossNumber == 5 then
			EVENT_MANAGER:UnregisterForEvent("IDH_FL_Acid", EVENT_COMBAT_EVENT)
			IDH_FL.acidCount = 0
		end
		-- Reset, we're not on a boss now.
		IDH_FL.bossNumber = 0
        IDH_UI:SetHidden(true)
	end
end

IDH_FL.Load = function()
    -- nothing needed for normal mode
	if not IDH.isVet then return end

	EVENT_MANAGER:RegisterForEvent("IDH_FL", EVENT_PLAYER_COMBAT_STATE, OnChangeCombatState)
	d("[IDH] Loaded module for Fang Lair.")
end

IDH_FL.BeginUnload = function()
    -- nothing needed for normal mode
	if not IDH.isVet then return end

	EVENT_MANAGER:UnregisterForEvent("IDH_FL", EVENT_PLAYER_COMBAT_STATE)
    -- These things only matter in single fights, so safe to clear whenever we unload
    IDH_FL.bossNumber = 0
    IDH_FL.spectreCount = 0
    IDH_FL.acidCount = 0
    d("[IDH] Unloaded module for Fang Lair.")
end
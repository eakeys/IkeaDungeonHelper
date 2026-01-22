IDH_ERE = {
    lastTickTimes = {},
    lastTick = nil,
    lastTickUnitId = nil,
}

-- Here's a log from ERE. We didn't get the achievement in any of our runs.
-- https://www.esologs.com/reports/39QA8yCjqRKHNZb6
-- We have a bunch of things called Root Corruption and Root Infection. Not sure which is which.
-- The achievement says 'nobody gets hit by root infection within 1s of someone else getting hit'.
-- It seems Root Corruption is the initial hit, which places a DoT called Root Infection.
-- Root Infection is also counted as a buff, and as a debuff.
-- List of possible things:
-- 178969, Buff "Corruption". Probably not it because it's applied from main boss' 'Boughroot Slash' and only hits tank
-- 178875, Buff "Infection". Probably not it, as it seems to last only a couple of seconds.
-- 178864, Buff "Infection". Also probably not it as it seems to last an instant.
-- 178863, Buff "Infection". Probably a good one as it seems to last 20s and the dot ticks every 2s for 20s.
-- 
-- 171752: Debuff and damage taken "Corruption". Happens on normal. Based on logs, 2s after this happens, buff 178863 is applied for 20s
-- (so until 22s after this hit). Maybe this is the thing to track? Getting hit by this multiple times doesn't reapply the dot though.
-- As a buff: Corruption = 178969, Infection = 178875 or 178863. The latter seems to last 20s and is not refreshed
-- upon getting hit again. Maybe tracking this is key?
-- 

local function UpdateText()

end

local function DeclareContagionFail()
    d("Fail")
end

local function OnChangeCombatState(eventCode, inCombat)
	-- If you just left combat, then reset everything.
	if inCombat == false then
		IDH_ERE.lastTickTimes = {}
        IDH_ERE.lastTick = nil
        IDH_ERE.lastTickUnitId = nil
        d("Exit combat")
		UpdateText()
	end
	
	-- Show the addon if you haven't killed velidreth yet, but you've gotten to her.
	-- (and if you want to track)
	if inCombat and GetUnitName("boss1") == "Corruption of Root" and IDH.GetTrackingMode(IDH.AchievementIDs.CONTAGION_CONTAINED, false) == IDH.AchievementTrackModes.ON_SCREEN then
		IDH_UI:SetHidden(false)
		--UpdateText()
	elseif inCombat == false then
		IDH_UI:SetHidden(true)
	end
end

local function OnCombatEvent_RootInf(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
	
	-- If you want to debug/find out information about a combat event, just copy the below:
	--df("Combat event. Deta: eventCode = %d, result = %d, abilityName = %s, abilityActionSlotType = %d, sourceName = %s, sourceType = %d, targetName = %s, targetType = %d, hitValue = %d, powerType = %d, damageType = %d, sourceUnitId = %d, targetUnitId = %d, abilityId = %d",
	--	eventCode, result, abilityName, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, sourceUnitId, targetUnitId, abilityId)
	
	-- if hitValue == 0 then return end
	
	-- Check if it was you or a groupmate.
	if targetType == COMBAT_UNIT_TYPE_PLAYER or targetType == COMBAT_UNIT_TYPE_GROUP then
        --d("Target id = " .. targetUnitId)
		local thisTick = GetFrameTimeMilliseconds()
        -- if the buff is refreshed by this hit
        if (not IDH_ERE.lastTickTimes[targetUnitId]) or IDH_ERE.lastTickTimes[targetUnitId] + 22000 < thisTick then
            d("Root infection tick on player " .. targetUnitId .. " at time " .. thisTick .. " " .. zo_strformat("<<1>>", targetName))
            -- if the last refreshing activation happened within 22s of now, then (because we're in this block)
            -- it was on a different player, and now 2 people have the debuff so we fail.
            if IDH_ERE.lastTick and (IDH_ERE.lastTick >= thisTick - 22000) then
                DeclareContagionFail()
            end
            IDH_ERE.lastTickTimes[targetUnitId] = thisTick
            IDH_ERE.lastTick = thisTick
            IDH_ERE.lastTickUnitId = targetUnitId
        end
        --d("[IDH] Root Infection tick at time " .. thisTick)
	end
	
	local mode = IDH.GetTrackingMode(IDH.AchievementIDs.VENOMOUS_EVASION, true)

	if mode == IDH.AchievementTrackModes.ON_SCREEN then
		UpdateText()
	elseif mode == IDH.AchievementTrackModes.CHAT then
		d("|cffff00[IDH] Failed |H1:achievement:3384:0:0|h|h: player hit by venom sac")
	end
	
end

IDH_ERE.Load = function()
    -- put this back in once done testing
    -- if not IDH.isVet then return end

    d("[IDH] Loaded module for Earthen Root Enclave.")

    EVENT_MANAGER:RegisterForEvent("IDH_ERE_RootInf", EVENT_COMBAT_EVENT, OnCombatEvent_RootInf)
	EVENT_MANAGER:AddFilterForEvent("IDH_ERE_RootInf", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 171752) -- root 
	
	-- Leaving combat (possibly due to death) should reset the tracker.
	EVENT_MANAGER:RegisterForEvent("IDH_ERE_CombatState", EVENT_PLAYER_COMBAT_STATE, OnChangeCombatState)
end
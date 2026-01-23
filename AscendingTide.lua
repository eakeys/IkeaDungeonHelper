-- Coral Aerie
IDH_CA = {

}

local function HandleVarallionTide(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)

    if IDH.savedVars.CA_Varallion_TFAlerts then
        IDH.ShowProminentAlert("TIDAL FORCE", "DUEL_BOUNDARY_WARNING", 3, 2500)
    end

    IDH_CA.lastWave = GetFrameTimeMilliseconds()
end

local function UpdateTideTimer()
    local dt = (GetFrameTimeMilliseconds() - IDH_CA.lastWave) / 1000
    if (dt < 60) and (dt > 16) then
        IDHStatusTimer1:SetText(string.format("Tidal Force: %.0fs", 60 - dt))
    elseif (dt <= 16) then
        IDHStatusTimer1:SetText(string.format("Tidal Force: Active (%.0fs)", dt))
    else
        IDHStatusTimer1:SetText("Tidal Force: SOON")
    end
end

local function OnChangeCombatState(eventcode, is_entering)
    if is_entering then
        IDH_CA.currentBossName = GetUnitName("boss1")
        local boss_name = GetUnitName("boss1")
        if boss_name == "Varallion" and
                (IDH.savedVars.CA_Varallion_TFAlerts or IDH.savedVars.CA_Varallion_TFTimer) then
            --d("[IDH] Fighting Varallion!")
            IDH_CA.currentBoss = 3

            EVENT_MANAGER:RegisterForEvent("IDH_CA_Varallion_WaveCheck",
                EVENT_COMBAT_EVENT, HandleVarallionTide)
            local id = 159421 -- normal
            if IDH.isVet then
                local currentHP, maxHP = GetUnitPower("boss1", POWERTYPE_HEALTH)
                if maxHP > 11000000 then -- HM
                    id = 168661
                end
            end
            EVENT_MANAGER:AddFilterForEvent("IDH_CA_Varallion_WaveCheck", EVENT_COMBAT_EVENT,
                REGISTER_FILTER_ABILITY_ID, id)
            EVENT_MANAGER:AddFilterForEvent("IDH_CA_Varallion_WaveCheck", EVENT_COMBAT_EVENT,
                REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_BEGIN)
        
            if IDH.savedVars.CA_Varallion_TFTimer then
                IDH_CA.lastWave = 0
                IDH.ShowTimer("Tidal Force: SOON", 1)
                EVENT_MANAGER:RegisterForUpdate("IDH_CA_Varallion_WaveTimerUpdate", 50, UpdateTideTimer)
            end
        end
    else
        if IDH_CA.currentBoss == 3 then
            IDH_CA.currentBoss = 0
            --d("[IDH] Varallion despawned!")
            EVENT_MANAGER:UnregisterForEvent("IDH_CA_Varallion_WaveCheck", EVENT_COMBAT_EVENT)
            EVENT_MANAGER:UnregisterForUpdate("IDH_CA_Varallion_WaveTimerUpdate")
            IDH.HideTimer(1)
        end
    end
end

IDH_CA.Load = function()
    d("[IDH] Loaded module for Coral Aerie.")
    EVENT_MANAGER:RegisterForEvent("IDH_CA", EVENT_PLAYER_COMBAT_STATE, OnChangeCombatState)
    --EVENT_MANAGER:RegisterForEvent("IDH_blah1_samplemechevent", 
    --    EVENT_COMBAT_EVENT, function() zo_callLater(GenerateRuptureIcons, 1000) end)
    -- 240244 is the ID of 'Rupture 2 Hide' in logs, which is the start of the mechanic.
    --EVENT_MANAGER:AddFilterForEvent("IDH_blah1_samplemechevent", 
    --    EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 240244)
end

IDH_CA.BeginUnload = function()
    d("[IDH] Unloaded module for Coral Aerie.")

    EVENT_MANAGER:UnregisterForEvent("IDH_CA", EVENT_PLAYER_COMBAT_STATE)
end

IDH_CA.EndUnload = nil
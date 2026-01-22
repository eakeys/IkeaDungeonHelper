-- Coral Aerie
IDH_CA = {

}

local function SarydilTakesDamage(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
    if (zo_strformat("<<1>>", targetName) == IDH_CA.currentBossName) then
        d("Sarydil just took " .. hitValue .. " damage from " .. abilityName)
    else
        d("Unknown target: " .. zo_strformat("<<1>>", targetName))
    end
end

local function SarydilCombatEvent(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)

    if (zo_strformat("<<1>>", targetName) == IDH_CA.currentBossName) then
        
    end

    if not (sourceName:find("Ascendant Thundermaul")) then
        return
    end

    --d(string.format("Combat event. Code %d", eventCode))
end

local function UpdateStormshaperTimer()
    local now = GetFrameTimeMilliseconds()
    if now < IDH_CA.nextInterruptDue then
        IDHStatusTimer1:SetText(string.format("Stormshaper: %.1fs", (IDH_CA.nextInterruptDue - now) / 1000))
    else
        IDHStatusTimer1:SetText("Stormshaper: SOON")
   end 
end

-- To do: figure out the trigger for calling this function.
local function StormshaperDidChannel()
    IDH.ShowProminentAlert("Interrupt Stormshaper!", "DUEL_BOUNDARY_WARNING", 3, 2000)
    IDH_CA.nextInterruptDue = GetFrameTimeMilliseconds() + 30000
end

EA_GLOBAL_DEBUG_FN = function() 
        StormshaperDidChannel()
    end

local function ShowStormshaperTimer()
    EVENT_MANAGER:UnregisterForEvent("IDH_CA_Sarydil_ChatCheck", EVENT_CHAT_MESSAGE_CHANNEL)
    EVENT_MANAGER:UnregisterForUpdate("IDH_CA_Sarydil_HPCheck")
    --d("Showing stormshaper timer!")
    IDH.ShowTimer("Stormshaper: SOON", 1)

    -- Temporary
    IDH_CA.nextInterruptDue = GetFrameTimeMilliseconds() + 30000

    EVENT_MANAGER:RegisterForUpdate("IDH_CA_Sarydil_TimerUpdate", 50, UpdateStormshaperTimer)

    
end

local function HandleSarydilDialogue(evCode, channelType, fromName, text, isCustomerService, fromDisplayName)
    if text == "Time to clear you all out." or text == "Mages, into position!" then
        ShowStormshaperTimer()
    end
end

local function DoSarydilHealthCheck()
    local currentTargetHP, maxTargetHP, effmaxTargetHP = GetUnitPower("boss1", POWERTYPE_HEALTH)
    if maxTargetHP > 1 and currentTargetHP < maxTargetHP * 0.66 then
        ShowStormshaperTimer()
    end
end

local function HandleVarallionTide(eventCode, result, isError, abilityName, abilityGraphic,
	abilityActionSlotType, sourceName, sourceType, targetName, targetType,
	hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)

    if IDH.savedVars.CA_Varallion_TFAlerts then
        IDH.ShowProminentAlert("TIDAL FORCE", "DUEL_BOUNDARY_WARNING", 3, 2500)
    end

    IDH_CA.lastWave = GetFrameTimeMilliseconds()
end

local function OnChangeCombatState(eventcode, is_entering)
    if is_entering then
        IDH_CA.currentBossName = GetUnitName("boss1")
        local boss_name = GetUnitName("boss1")
        if IDH.savedVars.CA_Sarydil_Interrupts and (boss_name == "Sarydil") then
            --d("[IDH] Fighting Sarydil!")
            IDH_CA.currentBoss = 2
            --EVENT_MANAGER:RegisterForEvent("IDH_CA_Sarydil", EVENT_COMBAT_EVENT, SarydilTakesDamage)
            --EVENT_MANAGER:AddFilterForEvent("IDH_CA_Sarydil", EVENT_COMBAT_EVENT, 
            --    REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DAMAGE)
        
            EVENT_MANAGER:RegisterForEvent("IDH_CA_Sarydil_ChatCheck",
                EVENT_CHAT_MESSAGE_CHANNEL, HandleSarydilDialogue)
            
            EVENT_MANAGER:RegisterForUpdate("IDH_CA_Sarydil_HPCheck", 500, DoSarydilHealthCheck)
        elseif (boss_name == "Varallion" and
                (IDH.savedVars.CA_Varallion_TFAlerts or IDH.savedVars.CA_Varallion_TFTimer)) then
            --d("[IDH] Fighting Varallion!")
            IDH_CA.currentBoss = 3

            EVENT_MANAGER:RegisterForEvent("IDH_CA_Varallion_WaveCheck",
                EVENT_COMBAT_EVENT, HandleVarallionTide)
            local id = 159421 -- normal
            if IDH.isVet then
                local currentHP, maxHP = GetUnitPower("boss1", POWERTYPE_HEALTH)
                if maxHP > 11000000 then -- HM
                    id = 168661
                else
                    id = 9999999 -- Don't know the ability id for non-HM
                end
            end
            d("Registering " .. id)
            EVENT_MANAGER:AddFilterForEvent("IDH_CA_Varallion_WaveCheck", EVENT_COMBAT_EVENT,
                REGISTER_FILTER_ABILITY_ID, id)
            EVENT_MANAGER:AddFilterForEvent("IDH_CA_Varallion_WaveCheck", EVENT_COMBAT_EVENT,
                REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_BEGIN)
        
            if IDH.savedVars.CA_Varallion_TFTimer then
                IDH_CA.lastWave = 0
                local updateText = function()
                    local dt = (GetFrameTimeMilliseconds() - IDH_CA.lastWave) / 1000
                    if (dt < 60) and (dt > 17) then
                        IDHStatusTimer1:SetText(string.format("Tidal Force: %.0fs", 60 - dt))
                    elseif (dt <= 17) then
                        IDHStatusTimer1:SetText(string.format("Tidal Force: Active (%.0fs)", dt))
                    else
                        IDHStatusTimer1:SetText("Tidal Force: SOON")
                    end
                end
                IDH.ShowTimer("Tidal Force: SOON", 1)
                EVENT_MANAGER:RegisterForUpdate("IDH_CA_Varallion_WaveTimerUpdate", 50, updateText)
            end
        end
    else
        if IDH_CA.currentBoss == 2 then
            --d("[IDH] Sarydil despawned!")
            IDH_CA.currentBoss = 0
            EVENT_MANAGER:UnregisterForEvent("IDH_CA_Sarydil", EVENT_COMBAT_EVENT)
            EVENT_MANAGER:UnregisterForEvent("IDH_CA_Sarydil_ChatCheck", EVENT_CHAT_MESSAGE_CHANNEL)
            EVENT_MANAGER:UnregisterForUpdate("IDH_CA_Sarydil_HPCheck")
            EVENT_MANAGER:UnregisterForUpdate("IDH_CA_Sarydil_TimerUpdate")
            IDH.HideTimer(1)
        elseif IDH_CA.currentBoss == 3 then
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
IDH_LS = {
    slowDescentExpiry = 0,
}

local function SlowDescentEvent(params)
    if params.targetType ~= COMBAT_UNIT_TYPE_PLAYER then 
        d("Well this is bad!!!")
        return
    end

    local now = GetFrameTimeMilliseconds()
    -- GAINED_DURATION also happens, but only the first time (and alongside GAINED), so ignore it
    if params.result == ACTION_RESULT_EFFECT_GAINED then
        IDH_LS.slowDescentExpiry = now + GetAbilityDuration(229625)
    elseif params.result == ACTION_RESULT_EFFECT_FADED then
        if IDH_LS.slowDescentExpiry > now then
            IDH_LS.slowDescentExpiry = now
        end
    end
end

local function UpdateSlowDescentTimer()
    local now = GetFrameTimeMilliseconds()
    if IDH_LS.slowDescentExpiry > now then
        IDH.ShowTimer(string.format("|c00ff00Slow Descent: ACTIVE %.1fs", 
            (IDH_LS.slowDescentExpiry - now) / 1000.0), 1)
    else
        IDH.ShowTimer("|cff0000Slow Descent: INACTIVE", 1)
    end
end

local function OnChangeCombatState(eventcode, is_entering)
    if is_entering then
        IDH_LS.currentBossName = GetUnitName("boss1")
        if IDH_LS.currentBossName == "Orpheon the Tactician" and IDH.savedVars.LS_SlowDescentTrack then
            IDH_LS.currentBoss = 6
            EVENT_MANAGER:RegisterForEvent("IDH_LS_SlowDescent", EVENT_COMBAT_EVENT, 
                IDH.MakeCombatEventFunction(SlowDescentEvent))
            EVENT_MANAGER:AddFilterForEvent("IDH_LS_SlowDescent", EVENT_COMBAT_EVENT, 
                REGISTER_FILTER_ABILITY_ID, 229625)
            EVENT_MANAGER:AddFilterForEvent("IDH_LS_SlowDescent", EVENT_COMBAT_EVENT,
                REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
            EVENT_MANAGER:RegisterForUpdate("IDH_LS_SlowDescentUpdate", 50, UpdateSlowDescentTimer)
        end
    else
        if IDH_LS.currentBoss == 6 then
            EVENT_MANAGER:UnregisterForEvent("IDH_LS_SlowDescent", EVENT_COMBAT_EVENT)
            EVENT_MANAGER:UnregisterForUpdate("IDH_LS_SlowDescentUpdate")
            IDH.HideTimer(1)
            IDH_LS.currentBoss = 0
        end
        
    end
end

IDH_LS.Load = function()
    d("[IDH] Loaded module for Lep Seclusa.")

    EVENT_MANAGER:RegisterForEvent("IDH_LS_Combat", EVENT_PLAYER_COMBAT_STATE, OnChangeCombatState)
end

IDH_LS.BeginUnload = function()
    d("[IDH] Unloaded module for Lep Seclusa.")
    EVENT_MANAGER:UnregisterForEvent("IDH_LS_Combat", EVENT_PLAYER_COMBAT_STATE)

    if IDH_LS.currentBoss == 6 then
        EVENT_MANAGER:UnregisterForEvent("IDH_LS_SlowDescent", EVENT_COMBAT_EVENT)
        EVENT_MANAGER:UnregisterForUpdate("IDH_LS_SlowDescentUpdate")
        IDH.HideTimer(1)
        IDH_LS.currentBoss = 0
    end
end
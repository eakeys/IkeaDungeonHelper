-- Black Gem Foundry
IDH_BGF = {
    ruptureIcons = {},
}

IDH_NC = {
    totemCounter = 0,

    BSArenaCentreX = 53849,
    BSArenaCentreZ = 148769,
    BSArenaSafeRadiusSquared = 1800 * 1800,
    spamSoundCounter = 1,
    isInDanger = false,
    dangerBorder = nil
}

local function TestQuarrymasterHM()
    local currentTargetHP, maxTargetHP, effmaxTargetHP = GetUnitPower("boss1", POWERTYPE_HEALTH)
    -- Can't remember the exact health amounts but HM is around 13m, non HM around 8m.
    return maxTargetHP > 10000000
end

local function UpdateRuptureIcons()
    local zone, x, y, z = GetUnitRawWorldPosition("player")
    local cX = 175073
    local cZ = 75189
    
    local distCentre = math.sqrt((x - cX) * (x - cX) + (z - cZ) * (z - cZ))
    -- vector pointing outward
    local xNorm = (x - cX) / distCentre
    local zNorm = (z - cZ) / distCentre
    
    -- flip inward if far out, 16m seems a good threshold
    if distCentre > 1600 then
        xNorm = -xNorm
        zNorm = -zNorm
    end
    
    local numPoints = IDH.savedVars.BGF_RuptureLinePointCount

    for i = 1, numPoints do
        local targetX = x + xNorm * i * 1500 / numPoints
        local targetZ = z + zNorm * i * 1500 / numPoints
        IDH_BGF.ruptureIcons[i].x = targetX
        IDH_BGF.ruptureIcons[i].z = targetZ
    end
end

local function DeleteRuptureIcons()
    local numPoints = IDH.savedVars.BGF_RuptureLinePointCount
    for i = 1, numPoints do
        OSI.DiscardPositionIcon(IDH_BGF.ruptureIcons[i])
    end
    EVENT_MANAGER:UnregisterForUpdate("IDH_BGF_QuarryUpdate")
end

local function GenerateRuptureIcons()
    local isEnabled = IDH.savedVars.BGF_EnableRuptureLines

    if not isEnabled or not OSI then return end

    local numPoints = IDH.savedVars.BGF_RuptureLinePointCount
    local pointSize = IDH.savedVars.BGF_RuptureLinePointScale

    for i = 1, numPoints do
        IDH_BGF.ruptureIcons[i] = OSI.CreatePositionIcon(0, 32800, 0, "OdySupportIcons/icons/squares/squaretwo_yellow.dds", pointSize * OSI.GetIconSize() / 100.0)
    end

    UpdateRuptureIcons()
    EVENT_MANAGER:RegisterForUpdate("IDH_BGF_QuarryUpdate", 16, UpdateRuptureIcons)

    -- todo: check that the HM amount is accurate (can't test it alone)
    local duration = TestQuarrymasterHM() and 15500 or 6500

    zo_callLater(DeleteRuptureIcons, duration)
end

IDH_BGF.Load = function()
    d("[IDH] Loaded module for Black Gem Foundry.")
    EVENT_MANAGER:RegisterForEvent("IDH_BGF_RuptureStart", EVENT_COMBAT_EVENT, function() zo_callLater(GenerateRuptureIcons, 1000) end)
    -- 240244 is the ID of 'Rupture 2 Hide' in logs, which is the start of the mechanic.
    EVENT_MANAGER:AddFilterForEvent("IDH_BGF_RuptureStart", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 240244)
end

IDH_BGF.BeginUnload = function()
    d("[IDH] Unloaded module for Black Gem Foundry.")
    EVENT_MANAGER:UnregisterForEvent("IDH_BGF_RuptureStart", EVENT_COMBAT_EVENT)
end

local function PoxitoEffigy(args)
    if args.result == ACTION_RESULT_EFFECT_GAINED then
        IDH_NC.totemCounter = IDH_NC.totemCounter + 1
    elseif args.result == ACTION_RESULT_EFFECT_FADED then
        IDH_NC.totemCounter = IDH_NC.totemCounter - 1
    end
    IDH.ShowTimer("Totems: " .. IDH_NC.totemCounter, 1)
end

local function CheckBarSakkaDangerZone()
    local _, x, y, z = GetUnitRawWorldPosition("player")
    local relX = x - IDH_NC.BSArenaCentreX
    local relZ = z - IDH_NC.BSArenaCentreZ
    
    if (relX * relX + relZ * relZ) > IDH_NC.BSArenaSafeRadiusSquared then
        IDH_NC.spamSoundCounter = IDH_NC.spamSoundCounter - 1
        if IDH_NC.spamSoundCounter <= 0 then
            IDH_NC.spamSoundCounter = 8
            if IDH.savedVars.NC_BS_UnsafeSound then
                PlaySound(SOUNDS.DUEL_BOUNDARY_WARNING)
            end
        end
        if not IDH_NC.isInDanger then
            IDH_NC.dangerBorder:Enable(0xAA00FF77, nil, "IDH_NC_Border")
            if IDH.savedVars.NC_BS_UnsafeMsg then
                IDHProminentLabel:SetText("MOVE CLOSER")
                IDHProminent:SetHidden(false)
            end
            IDH_NC.isInDanger = true
        end
    else
        IDH_NC.spamSoundCounter = 1
        IDH_NC.isInDanger = false
        IDHProminent:SetHidden(true)
        IDH_NC.dangerBorder:Disable("IDH_NC_Border")
    end

    --IDH.ShowProminentAlert(string.format("Distance: %.1fm", math.sqrt(relX * relX + relZ * relZ) / 100), SOUNDS.DUEL_START, 1, 1000)
end

local function NajChangeCombatState(eventcode, is_entering)
    if is_entering then
        local bossName = GetUnitName("boss1")
        if bossName == "Poxito" then
            IDH_NC.currentBoss = 1
            if IDH.savedVars.NC_Poxito_TotemCounter then
                EVENT_MANAGER:RegisterForEvent("IDH_NC_Effigy", EVENT_COMBAT_EVENT, IDH.MakeCombatEventFunction(PoxitoEffigy))
                -- 242338 = id of "Create Effigy", seems to be given on creation and removed on kill
                EVENT_MANAGER:AddFilterForEvent("IDH_NC_Effigy", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 242338)
            end
        elseif bossName == "Talen-Lah" then
            IDH_NC.currentBoss = 3
            if IDH.savedVars.NC_BS_UnsafeWarn then
                EVENT_MANAGER:RegisterForUpdate("IDH_NC_Circle", 50, CheckBarSakkaDangerZone)
            end
        end
    else
        if IDH_NC.currentBoss == 1 then
            IDH_NC.currentBoss = 0
            EVENT_MANAGER:UnregisterForEvent("IDH_NC_Effigy", EVENT_COMBAT_EVENT)
            IDH_NC.totemCounter = 0
            IDH.HideTimer(1)
        elseif IDH_NC.currentBoss == 3 then
            IDH_NC.currentBoss = 0
            EVENT_MANAGER:UnregisterForUpdate("IDH_NC_Circle")
        end
    end
end

IDH_NC.Load = function()
    if not IDH_NC.dangerBorder then
        IDH_NC.dangerBorder = LibCombatAlerts.ScreenBorder:New()
    end
    d("[IDH] Loaded module for Naj-Caldeesh.")

    EVENT_MANAGER:RegisterForEvent("IDH_NC_CS", EVENT_PLAYER_COMBAT_STATE, NajChangeCombatState)
end

IDH_NC.BeginUnload = function()
    d("[IDH] Unloaded module for Naj-Caldeesh.")
    EVENT_MANAGER:UnregisterForEvent("IDH_NC_CS", EVENT_PLAYER_COMBAT_STATE)
end

EA_GLOBAL_DEBUG_FN = function() EVENT_MANAGER:RegisterForUpdate("IDH_NC_Circle", 50, CheckBarSakkaDangerZone) end
-- Black Gem Foundry
IDH_BGF = {
    ruptureIcons = {},
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

local function OnChangeCombatState()

end

IDH_BGF.Load = function()
    d("[IDH] Loaded module for Black Gem Foundry.")
    EVENT_MANAGER:RegisterForEvent("IDH_BGF_RuptureStart", EVENT_COMBAT_EVENT, function() zo_callLater(GenerateRuptureIcons, 1000) end)
    -- 240244 is the ID of 'Rupture 2 Hide' in logs, which is the start of the mechanic.
    EVENT_MANAGER:AddFilterForEvent("IDH_BGF_RuptureStart", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 240244)
end

IDH_BGF.BeginUnload = function()
    d("[IDH] Unloaded module for Black Gem Foundry.")
end
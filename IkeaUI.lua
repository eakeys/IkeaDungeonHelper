function IDH.ColourLineII(pass)
	if pass then
		IDH_UILineII:SetColor(unpack(IDH.savedVars.goodColour))
	else
        IDH_UILineII:SetColor(unpack(IDH.savedVars.badColour))
	end
end

function IDH.SaveDragLocation()
	IDH.savedVars.OffsetX = IDH_UI:GetLeft()
	IDH.savedVars.OffsetY = IDH_UI:GetTop()

	IDH.savedVars.TimerX = IDHStatus:GetLeft()
	IDH.savedVars.TimerY = IDHStatus:GetTop()

	IDH.savedVars.ProminentX = IDHProminent:GetLeft()
	IDH.savedVars.ProminentY = IDHProminent:GetTop()
end

local function ResetAchievementTracking(method)
	if method == "missing" then
		for key,value in pairs(IDH.AchievementIDs) do
			-- Check if you have this achievement.
			if IDH.AchievementsSupported[value] then
				buffer1, buffer2, buffer3, buffer4, completed = GetAchievementInfo(value)
				boxname = "IDH_CHECKBOX_" .. value
				ctrlRef = _G[boxname]
				IDH.savedVars.trackAchievs[value] = completed and "Disabled" or "Track in chat"
				ctrlRef:UpdateValue()
			end
		end
	elseif method == "all" then
		enable = true
		-- If anything is enabled, this button should switch all off.
		for key,value in pairs(IDH.AchievementIDs) do
			if IDH.AchievementsSupported[value] and IDH.savedVars.trackAchievs[value] ~= "Disabled" then
				enable = false
				break
			end
		end
		
		-- Now set all of these.
		for key,value in pairs(IDH.AchievementIDs) do
			if IDH.AchievementsSupported[value] then
				IDH.savedVars.trackAchievs[value] = enable and "Track in chat" or "Disabled"
				_G["IDH_CHECKBOX_" .. value]:UpdateValue()
			end
		end
	end
end

function IDH.CreateSettingsMenu()
	local LAM = LibAddonMenu2
	
	local panelData = {
		type = "panel",
		name = "Ikea Dungeon Helper"
	}
	
	LAM:RegisterAddonPanel("IDHOptions", panelData)
	
	-- Fill with general settings at first.
	local optionsData = {
		{
			type = "header",
			name = "General",
		},
		
		{
			type = "checkbox",
			name = "Track normal achievements on veteran",
			getFunc = function() return IDH.savedVars.trackNormalOnVet end,
			setFunc = function(t) IDH.savedVars.trackNormalOnVet = t end,
			tooltip = "Tracks progress towards achievements obtainable on normal mode, even if you're in the veteran instance of the relevant dungeon."
		},
		
		{
			type = "checkbox",
			name = "Unlock UI",
			getFunc = function() return false end, -- don't load in a default.
			setFunc = function(t)
				IDH.UnlockUI(t)
			end
		},
		
		{
			type = "button",
			name = "Track unearned",
			tooltip = "Reset tracking options to monitor achievements you don't have (and no others).",
			func = function() ResetAchievementTracking("missing") end,
			width = "half",
		},
		
		{
			type = "button",
			name = "Enable/disable all",
			func = function() ResetAchievementTracking("all") end,
			width = "half",
		},
	}
	
	local addHeading = function(_name, dat)
		dat[#dat + 1] = {
			type = "header",
			name = _name,
		}
	end

    local addSubmenu = function(_name, dat)
        dat[#dat + 1] = {
            type = "submenu",
            name = _name,
            controls = {},
        }

        return dat[#dat].controls
    end
	
	local addAch = function(_id, dat)
	
		-- Get data about achievement.
		name, desc, pts, icon, comp, dateattained, timeattained = GetAchievementInfo(_id)
	
		dat[#dat + 1] = {
			type = "dropdown",
			name = "Tracking Achievement: " .. name,
            choices = {"Disabled", "Track in chat", "Track with UI"},
			getFunc = function() return IDH.savedVars.trackAchievs[_id] or "Disabled" end,
			setFunc = function(t)
				IDH.savedVars.trackAchievs[_id] = t
				-- to allow for turning off the ui in response to it showing up
				if t ~= "Track with UI" then
					IDH_UI:SetHidden(true)
				end
			end,
			disabled = IDH.AchievementsSupported[_id] ~= true,
            width = "full",
			reference = "IDH_CHECKBOX_" .. _id
		}
		
		if comp then
			dat[#dat].tooltip = name .. "\n" .. desc .. "\n\nYou |c00ff00have|r this achievement."
		else
			dat[#dat].tooltip = name .. "\n" .. desc .. "\n\nYou |cff0000do not have|r this achievement."
		end
		
		if IDH.AchievementsSupported[_id] ~= true then
			dat[#dat].getFunc = function() return false end
			dat[#dat].setFunc = function(t) end
			dat[#dat].tooltip = dat[#dat].tooltip .. "\n|cff0000This achievement is not supported yet.|r"
		end
	end
	
	-- For convenience
	achIDs = IDH.AchievementIDs
	
	local submenu = addSubmenu("Ruins of Mazzatun", optionsData)
	addAch(achIDs.SAPPED_SLUDGE_SLINGERS, submenu)
    local submenu = addSubmenu("Cradle of Shadows", optionsData)
	addAch(achIDs.VENOMOUS_EVASION, submenu)
	
	submenu = addSubmenu("Bloodroot Forge", optionsData)
	addAch(achIDs.COOLING_YOUR_HEELS, submenu)
	addAch(achIDs.WILDLIFE_SANCTUARY, submenu)
	
	submenu = addSubmenu("Fang Lair", optionsData)
	addAch(achIDs.FUNGI_FREE, submenu)
	addAch(achIDs.NONPLUSSED, submenu)
	addAch(achIDs.STARVED_SCARABS, submenu)

    submenu = addSubmenu("Scalecaller Peak", optionsData)
	addAch(achIDs.PUSTULENT_PROBLEMS, submenu)
	addAch(achIDs.WATCH_YOUR_STEP, submenu)
	
	submenu = addSubmenu("Moon Hunter Keep", optionsData)
	addAch(achIDs.ON_A_SHORT_LEASH, submenu)
	addAch(achIDs.BLOODY_MESS, submenu)
	addAch(achIDs.SIDESTEPPING_STRANGLERS, submenu)
	addAch(achIDs.ROOT_OF_THE_PROBLEM, submenu)

    submenu = addSubmenu("March of Sacrifices", optionsData)
	addAch(achIDs.STALWART_SISTERHOOD, submenu)
	addAch(achIDs.ELEMENT_OF_SURPRISE, submenu)
	
	submenu = addSubmenu("Lair of Maarselok", optionsData)
	addAch(achIDs.DUCK_AND_WEAVE, submenu)
	
	
	submenu = addSubmenu("Icereach", optionsData)
	addAch(achIDs.SPIT_TAKE, submenu)

    submenu = addSubmenu("Unhallowed Grave", optionsData)
	addAch(achIDs.SHATTERED_SHIELDS, submenu)
	
	submenu = addSubmenu("Stone Garden", optionsData)
	addAch(achIDs.SPORE_STOMPER, submenu)
	
	submenu = addSubmenu("Black Drake Villa", optionsData)
	addAch(achIDs.SHAKE_IT_UP, submenu)
	
	submenu = addSubmenu("Red Petal Bastion", optionsData)
	addAch(achIDs.STAMPEDE_SHUFFLE, submenu) -- check the name for this

    submenu = addSubmenu("The Dread Cellar", optionsData)
	addAch(achIDs.DREADLESS_RUNNER, submenu)
	
	submenu = addSubmenu("Coral Aerie", optionsData)
	addHeading("Sarydil", submenu)
	addAch(achIDs.SUMMERSET_PRESERVATION_SOCIETY, submenu)
	submenu[#submenu + 1] = {
		type = "checkbox",
			name = "[HM] Show Stormshaper interrupt timers",
			getFunc = function() return IDH.savedVars.CA_Sarydil_Interrupts == true end, -- false if nil.
			setFunc = function(t)
				IDH.savedVars.CA_Sarydil_Interrupts = t
			end,
		tooltip = "If enabled, will show a countdown to the Ascendant Stormshapers' next interruptible area denial attack. (Experimental!)"
	}
	addHeading("Varallion", submenu)
	submenu[#submenu + 1] = {
		type = "checkbox",
		name = "Show Tidal Force timer",
		getFunc = function() return IDH.savedVars.CA_Varallion_TFTimer == true end,
		setFunc = function(t)
			IDH.savedVars.CA_Varallion_TFTimer = t 
		end,
		tooltip = "If enabled, will show a countdown to the next Tidal Force mechanic. This is the mechanic with three sets of waves that block off a third of the arena. 2 waves per set on HM, 1 on non-HM and normal.",
	}
	submenu[#submenu + 1] = {
		type="checkbox",
		name = "Show Tidal Force alerts",
		getFunc = function() return IDH.savedVars.CA_Varallion_TFAlerts == true end,
		setFunc = function(t) 
			IDH.savedVars.CA_Varallion_TFAlerts = t 
		end,
		tooltip = "If enabled, will show a prominent alert with each Tidal Force mechanic. This is the mechanic with three sets of waves that block off a third of the arena. 2 waves per set on HM, 1 on non-HM and normal.",
	}

    submenu = addSubmenu("Earthen Root Enclave", optionsData)
    addAch(achIDs.CONTAGION_CONTAINED, submenu)

    submenu = addSubmenu("Lep Seclusa", optionsData)
    addAch(achIDs.TACTICAL_RECKLESSNESS, submenu)
    addAch(achIDs.UNSINGED_BOOTS, submenu)
    addAch(achIDs.UNBURNT_AND_UNSCATHED, submenu)

    submenu = addSubmenu("Naj-Caldeesh", optionsData)
    addAch(achIDs.TOTAL_SELF_CONTROL, submenu)
    addAch(achIDs.PARCHED_STONEWORK, submenu)
    addAch(achIDs.FIGHT_THROUGH_PAIN, submenu)

    submenu = addSubmenu("Black Gem Foundry", optionsData)
    submenu[#submenu + 1] = {
        type = "checkbox",
        name = "[Quarrymaster Saldezaar] Show Rupture Lines",
        tooltip = "If enabled, shows a line for where the rupture mechanic will push you. Requires OdySupportIcons.",
        getFunc = function() return IDH.savedVars.BGF_EnableRuptureLines or false end,
        setFunc = function(to) IDH.savedVars.BGF_EnableRuptureLines = to end,
    }
    submenu[#submenu + 1] = {
        type = "slider",
        name = "Point Count",
        tooltip = "The rupture line is marked by individual points; adjust the number of points here. If you just want to see the end location, set this to 1.",
        min = 1,
        max = 25,
        step = 1,
        getFunc = function() return IDH.savedVars.BGF_RuptureLinePointCount end,
        setFunc = function(to) IDH.savedVars.BGF_RuptureLinePointCount = to end,
        width = "half",
        default = 10,
    }
    submenu[#submenu + 1] = {
        type = "slider",
        name = "Point Size",
        tooltip = "The rupture line is marked by individual points; adjust the size of them here. Size is a percentage relative to your chosen default size in OdySupportIcons.",
        min = 1,
        max = 100,
        getFunc = function() return IDH.savedVars.BGF_RuptureLinePointScale end,
        setFunc = function(to) IDH.savedVars.BGF_RuptureLinePointScale = to end,
        width = "half",
        default = 0.3,
    }

	LAM:RegisterOptionControls("IDHOptions", optionsData)
end

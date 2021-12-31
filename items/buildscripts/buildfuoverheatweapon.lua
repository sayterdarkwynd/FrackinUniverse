require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"

--apparently this entire file is unused.

function build(directory, config, parameters, level, seed)
	local function split(str, pat)
		local t = {}	-- NOTE: use {n = 0} in Lua-5.0
		local fpat = "(.-)" .. pat
		local last_end = 1
		local s, e, cap = str:find(fpat, 1)
		while s do
			if s ~= 1 or cap ~= "" then
				 table.insert(t, cap)
			end
			last_end = e+1
			s, e, cap = str:find(fpat, last_end)
		end
		if last_end <= #str then
			cap = str:sub(last_end)
			table.insert(t, cap)
		end
		return t
	end

	local configParameterDeep = function(keyName, defaultValue)
		local sets=split(keyName,"%.")
		local mergedBuffer=util.mergeTable(copy(config),copy(parameters))
		for _,v in pairs(sets) do
			if mergedBuffer[v] then
				mergedBuffer=mergedBuffer[v]
			else
				mergedBuffer=defaultValue
				break
			end
		end
		return mergedBuffer
	end
	local configParameter = function(keyName, defaultValue)
		if parameters[keyName] ~= nil then
			return parameters[keyName]
		elseif config[keyName] ~= nil then
			return config[keyName]
		else
			return defaultValue
		end
	end

	if level and not configParameter("fixedLevel", true) then
		parameters.level = level
	end
	setupAbility(config, parameters, "primary")
	setupAbility(config, parameters, "alt")
	-- elemental type and config (for alt ability)
	local elementalType = configParameter("elementalType", "physical")
	replacePatternInData(config, nil, "<elementalType>", elementalType)
	replacePatternInData(config, nil, "<elementalName>", elementalType:gsub("^%l", string.upper))
	if config.altAbility and config.altAbility.elementalConfig then
		--The difference is here, i added an if null-coalescing operation that checks if the alt ability has the elementalType in the elementalConfig list and replaces it with the physical type if it doesn't exist.
		util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType] or config.altAbility.elementalConfig["physical"])

	end

	-- calculate damage level multiplier
	config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

	local primaryAbility=configParameterDeep("primaryAbility")
	local altAbility=configParameterDeep("altAbility")

	-- palette swaps
	config.paletteSwaps = ""
	if config.palette then
		local palette = root.assetJson(util.absolutePath(directory, config.palette))
		local selectedSwaps = palette.swaps[configParameter("colorIndex", 1)]
		for k, v in pairs(selectedSwaps) do
			config.paletteSwaps = string.format("%s?replace=%s=%s", config.paletteSwaps, k, v)
		end
	end
	if type(config.inventoryIcon) == "string" then
		config.inventoryIcon = config.inventoryIcon .. config.paletteSwaps
	else
		for _, drawable in ipairs(config.inventoryIcon) do
			if drawable.image then drawable.image = drawable.image .. config.paletteSwaps end
		end
	end

	-- gun offsets
	if config.baseOffset then
		construct(config, "animationCustom", "animatedParts", "parts", "middle", "properties")
		config.animationCustom.animatedParts.parts.middle.properties.offset = config.baseOffset
		if config.muzzleOffset then
			config.muzzleOffset = vec2.add(config.muzzleOffset, config.baseOffset)
		end
	end

	-- populate tooltip fields
	if config.tooltipKind ~= "base" then
		config.tooltipFields = {}
		config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
		config.tooltipFields.dpsLabel = util.round((primaryAbility.baseDps or 0) * config.damageLevelMultiplier, 1)
		config.tooltipFields.speedLabel = util.round(1 / (primaryAbility.fireTime or 1.0), 1)
		config.tooltipFields.damagePerShotLabel = util.round((primaryAbility.baseDps or 0) * (primaryAbility.fireTime or 1.0) * config.damageLevelMultiplier, 1)
		config.tooltipFields.energyPerShotLabel = util.round((primaryAbility.energyUsage or 0) * (primaryAbility.fireTime or 1.0), 1)

		config.tooltipFields.overheatLabel = util.round(primaryAbility.overheatLevel / primaryAbility.heatGain, 1)
		config.tooltipFields.cooldownLabel = util.round(primaryAbility.overheatLevel / primaryAbility.heatLossRateMax, 1)
		-- *******************************
		-- FU ADDITIONS

			config.tooltipFields.critChanceLabel = util.round(configParameter("critChance",0), 0)
			config.tooltipFields.critBonusLabel = util.round(configParameter("critBonus",0), 0)
			config.tooltipFields.stunChanceLabel = util.round(configParameter("stunChance",0), 0)

		-- *******************************
		if elementalType ~= "physical" then
			config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
		end
		if config.primaryAbility then
			config.tooltipFields.primaryAbilityTitleLabel = "Primary:"
			config.tooltipFields.primaryAbilityLabel = config.primaryAbility.name or "unknown"
		end
		if config.altAbility then
			config.tooltipFields.altAbilityTitleLabel = "Special:"
			config.tooltipFields.altAbilityLabel = config.altAbility.name or "unknown"
		end
	end

	-- set price
	-- TODO: should this be handled elsewhere?
	config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

	return config, parameters
end

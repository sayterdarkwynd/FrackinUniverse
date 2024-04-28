require "/scripts/util.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"

function build(directory, config, parameters, level, seed)
	local configParameter = function(keyName, defaultValue)
		if parameters[keyName] ~= nil then
			return parameters[keyName]
		elseif config[keyName] ~= nil then
			return config[keyName]
		else
			return defaultValue
		end
	end

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

	if level and not configParameter("fixedLevel", true) then
		parameters.level = level
	end

	-- select, load and merge abilities
	setupAbility(config, parameters, "alt")
	setupAbility(config, parameters, "primary")

	-- elemental type
	local elementalType = parameters.elementalType or config.elementalType or "physical"
	replacePatternInData(config, nil, "<elementalType>", elementalType)
	replacePatternInData(config, nil, "<elementalName>", elementalType:gsub("^%l", string.upper))

	-- calculate damage level multiplier
	config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

	--Populate tooltip fields
	local primaryAbility=configParameterDeep("primaryAbility")
	local altAbility=configParameterDeep("altAbility")

	if config.tooltipKind ~= "base" then
		config.tooltipFields = {}
		config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
		config.tooltipFields.subtitle = parameters.category
		config.tooltipFields.damageLabel = util.round(primaryAbility.projectileParameters.power * primaryAbility.dynamicDamageMultiplier * primaryAbility.drawTime * config.damageLevelMultiplier, 2) or 0
		config.tooltipFields.perfectDrawTimeLabel = util.round(primaryAbility.powerProjectileTime, 2)
		config.tooltipFields.perfectDamageLabel = util.round(primaryAbility.powerProjectileParameters.power or primaryAbility.projectileParameters.power * primaryAbility.dynamicDamageMultiplier * primaryAbility.drawTime * config.damageLevelMultiplier, 2) or 0
		config.tooltipFields.airborneBonusLabel = util.round(primaryAbility.airborneBonus, 2)
		if altAbility then
			config.tooltipFields.drawTimeLabel = util.round(primaryAbility.drawTime - (altAbility.drawTimeReduction or 0), 2) or 0
		else
			config.tooltipFields.drawTimeLabel = util.round(primaryAbility.drawTime, 2) or 0
		end
		config.tooltipFields.drawEnergyLabel = util.round(primaryAbility.energyPerShot, 2) or 0
		config.tooltipFields.holdEnergyLabel = util.round(primaryAbility.holdEnergyUsage, 2) or 0
		if elementalType ~= "physical" then
			config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
		end
		if altAbility then
			config.tooltipFields.altAbilityTitleLabel = "Special:"
			config.tooltipFields.altAbilityLabel = altAbility.name or "unknown"
		end

		--Frackin' Universe critical fields
		if config.tooltipFields.critChanceLabel then
			local cChance=util.round(configParameter("critChance", 0), 0)
			if cChance == 0 then
				config.tooltipFields.critChanceTitleLabel = ""
				config.tooltipFields.critChanceLabel = ""
			else
				config.tooltipFields.critChanceTitleLabel = "^orange;Crit %^reset;"
				config.tooltipFields.critChanceLabel = util.round(configParameter("critChance", 0), 0)
			end

			local cBonus=util.round(configParameter("critBonus", 0), 0)
			if cBonus == 0 then
				config.tooltipFields.critBonusTitleLabel = ""
				config.tooltipFields.critBonusLabel = ""
			else
				config.tooltipFields.critBonusTitleLabel = "^yellow;C.Dmg%^reset;"
				config.tooltipFields.critBonusLabel = util.round(configParameter("critBonus", 0), 0)
			end
		end

		if config.tooltipFields.stunChance then
			config.tooltipFields.stunChance = util.round(configParameter("stunChance", 0), 0)
		end
	end

	-- set price
	config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

	return config, parameters
end

require "/scripts/util.lua"
require "/items/buildscripts/abilities.lua"

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

	-- calculate damage level multiplier
	config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

	local primaryAbility=configParameterDeep("primaryAbility")
	local altAbility=configParameterDeep("altAbility")

	config.tooltipFields = {}
	config.tooltipFields.subtitle = parameters.category
	config.tooltipFields.speedLabel = util.round(1 / primaryAbility.fireTime, 1)
	config.tooltipFields.damagePerShotLabel = util.round((primaryAbility.crackDps + primaryAbility.chainDps) * primaryAbility.fireTime * config.damageLevelMultiplier, 1)
	if config.elementalType and config.elementalType ~= "physical" then
		config.tooltipFields.damageKindImage = "/interface/elements/"..config.elementalType..".png"
	end
	if altAbility then
		config.tooltipFields.altAbilityTitleLabel = "Special:"
		config.tooltipFields.altAbilityLabel = altAbility.name or "unknown"
	end
		-- *******************************
		-- FU ADDITIONS
			config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
			config.tooltipFields.critChanceLabel = util.round(configParameter("critChance",0), 0)
			config.tooltipFields.critBonusLabel = util.round(configParameter("critBonus",0), 0)
			config.tooltipFields.stunChance = util.round(configParameter("stunChance",0), 0)

		-- *******************************
	-- set price
	config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

	return config, parameters
end

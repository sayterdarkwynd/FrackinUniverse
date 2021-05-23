require "/scripts/util.lua"
require "/scripts/versioningutils.lua"
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

	-- select, load and merge abilities
	setupAbility(config, parameters, "alt")
	setupAbility(config, parameters, "primary")

	-- elemental type
	local elementalType = parameters.elementalType or config.elementalType or "physical"
	replacePatternInData(config, nil, "<elementalType>", elementalType)
	replacePatternInData(config, nil, "<elementalName>", elementalType:gsub("^%l", string.upper))

	local primaryAbility=configParameterDeep("primaryAbility")
	local altAbility=configParameterDeep("altAbility")

	-- calculate damage level multiplier
	config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

	config.tooltipFields = {}
	config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
	config.tooltipFields.subtitle = parameters.category
	config.tooltipFields.energyPerShotLabel = primaryAbility.energyPerShot or 0
	local bestDrawTime = (primaryAbility.powerProjectileTime[1] + primaryAbility.powerProjectileTime[2]) / 2
	local bestDrawMultiplier = root.evalFunction(primaryAbility.drawPowerMultiplier, bestDrawTime)
	config.tooltipFields.maxDamageLabel = util.round(primaryAbility.projectileParameters.power * config.damageLevelMultiplier * bestDrawMultiplier, 1)
	if elementalType ~= "physical" then
		config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
	end

	-- *******************************
	-- FU ADDITIONS
	config.tooltipFields.critChanceLabel = util.round(configParameter("critChance",0), 0)
	config.tooltipFields.critBonusLabel = util.round(configParameter("critBonus",0), 0)
	config.tooltipFields.stunChance = util.round(configParameter("stunChance",0), 0)
	-- *******************************
	-- set price
	config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

	return config, parameters
end

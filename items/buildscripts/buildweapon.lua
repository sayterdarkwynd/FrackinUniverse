require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/scripts/staticrandom.lua"
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

	if level and not configParameter("fixedLevel", false) then
		parameters.level = level
	end

	-- initialize randomization
	if seed then
		parameters.seed = seed
	else
		seed = configParameter("seed")
		if not seed then
			math.randomseed(util.seedTime())
			seed = math.random(1, 4294967295)
			parameters.seed = seed
		end
	end

	-- select the generation profile to use
	local builderConfig = {}
	if config.builderConfig then
		builderConfig = randomFromList(config.builderConfig, seed, "builderConfig")
	end

	-- select, load and merge abilities
	setupAbility(config, parameters, "alt", builderConfig, seed)
	setupAbility(config, parameters, "primary", builderConfig, seed)

	-- elemental type
	if not parameters.elementalType and builderConfig.elementalType then
		parameters.elementalType = randomFromList(builderConfig.elementalType, seed, "elementalType")
	end
	local elementalType = configParameter("elementalType", "physical")

	-- elemental config
	if builderConfig.elementalConfig then
		util.mergeTable(config, builderConfig.elementalConfig[elementalType])
	end
	if config.altAbility and config.altAbility.elementalConfig and config.altAbility.elementalConfig[elementalType] then
		util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType])
	end

	-- elemental tag
	replacePatternInData(config, nil, "<elementalType>", elementalType)
	replacePatternInData(config, nil, "<elementalName>", elementalType:gsub("^%l", string.upper))

	-- name
	if not parameters.shortdescription and builderConfig.nameGenerator then
		parameters.shortdescription = root.generateName(util.absolutePath(directory, builderConfig.nameGenerator), seed)
	end

	-- merge damage properties
	if builderConfig.damageConfig then
		util.mergeTable(config.damageConfig or {}, builderConfig.damageConfig)
	end

	-- preprocess shared primary attack config
	parameters.primaryAbility = parameters.primaryAbility or {}
	parameters.primaryAbility.fireTimeFactor = valueOrRandom(parameters.primaryAbility.fireTimeFactor, seed, "fireTimeFactor")
	parameters.primaryAbility.baseDpsFactor = valueOrRandom(parameters.primaryAbility.baseDpsFactor, seed, "baseDpsFactor")
	parameters.primaryAbility.energyUsageFactor = valueOrRandom(parameters.primaryAbility.energyUsageFactor, seed, "energyUsageFactor")

	config.primaryAbility.fireTime = scaleConfig(parameters.primaryAbility.fireTimeFactor, config.primaryAbility.fireTime)
	config.primaryAbility.baseDps = scaleConfig(parameters.primaryAbility.baseDpsFactor, config.primaryAbility.baseDps)
	config.primaryAbility.energyUsage = scaleConfig(parameters.primaryAbility.energyUsageFactor, config.primaryAbility.energyUsage) or 0

	-- preprocess melee primary attack config
	if config.primaryAbility.damageConfig and config.primaryAbility.damageConfig.knockbackRange then
		config.primaryAbility.damageConfig.knockback = scaleConfig(parameters.primaryAbility.fireTimeFactor, config.primaryAbility.damageConfig.knockbackRange)
	end

	-- preprocess ranged primary attack config
	if config.primaryAbility.projectileParameters then
		config.primaryAbility.projectileType = randomFromList(config.primaryAbility.projectileType, seed, "projectileType")
		config.primaryAbility.projectileCount = randomIntInRange(config.primaryAbility.projectileCount, seed, "projectileCount") or 1
		config.primaryAbility.fireType = randomFromList(config.primaryAbility.fireType, seed, "fireType") or "auto"
		config.primaryAbility.burstCount = randomIntInRange(config.primaryAbility.burstCount, seed, "burstCount")
		config.primaryAbility.burstTime = randomInRange(config.primaryAbility.burstTime, seed, "burstTime")
		if config.primaryAbility.projectileParameters.knockbackRange then
			config.primaryAbility.projectileParameters.knockback = scaleConfig(parameters.primaryAbility.fireTimeFactor, config.primaryAbility.projectileParameters.knockbackRange)
		end
	end

	-- calculate damage level multiplier
	config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

	-- build palette swap directives
	config.paletteSwaps = ""
	if builderConfig.palette then
		local selectedSwaps = {}
		if parameters.WA_customPalettes then
			local layers = root.assetJson(util.absolutePath(directory,"/items/active/weapons/colors/WA_layers.weaponcolors"))
			local weaponPalette = string.match(builderConfig.palette, "/([^/]+)%.weaponcolors")
			for layer, targetColors in pairs(parameters.WA_customPalettes) do
				local sourceColors = layers[weaponPalette .. layer]
				for i in ipairs(sourceColors) do selectedSwaps[ sourceColors[i] ] = targetColors[i] end
			end
		else
			local palette = root.assetJson(util.absolutePath(directory, builderConfig.palette))
			selectedSwaps = randomFromList(palette.swaps, seed, "paletteSwaps")
		end
		for k, v in pairs(selectedSwaps) do
			config.paletteSwaps = string.format("%s?replace=%s=%s", config.paletteSwaps, k, v)
		end
	end

	-- merge extra animationCustom
	if builderConfig.animationCustom then
		util.mergeTable(config.animationCustom or {}, builderConfig.animationCustom)
	end

	-- animation parts
	if builderConfig.animationParts then
		config.animationParts = config.animationParts or {}
		if parameters.animationPartVariants == nil then parameters.animationPartVariants = {} end
		for k, v in pairs(builderConfig.animationParts) do
			if type(v) == "table" then
				if v.variants and (not parameters.animationPartVariants[k] or parameters.animationPartVariants[k] > v.variants) then
					parameters.animationPartVariants[k] = randomIntInRange({1, v.variants}, seed, "animationPart"..k)
				end
				config.animationParts[k] = util.absolutePath(directory, string.gsub(v.path, "<variant>", parameters.animationPartVariants[k] or ""))
				if v.paletteSwap then
					config.animationParts[k] = config.animationParts[k] .. config.paletteSwaps
				end
			else
				config.animationParts[k] = v
			end
		end
	end

	-- set gun part offsets
	local partImagePositions = {}
	if builderConfig.gunParts then
		construct(config, "animationCustom", "animatedParts", "parts")
		local imageOffset = {0,0}
		for _,part in ipairs(builderConfig.gunParts) do
			local imageSize = root.imageSize(config.animationParts[part])
			construct(config.animationCustom.animatedParts.parts, part, "properties")

			imageOffset = vec2.add(imageOffset, {imageSize[1] / 2, 0})
			config.animationCustom.animatedParts.parts[part].properties.offset = {config.baseOffset[1] + imageOffset[1] / 8, config.baseOffset[2]}
			partImagePositions[part] = copy(imageOffset)
			imageOffset = vec2.add(imageOffset, {imageSize[1] / 2, 0})
		end
		config.muzzleOffset = vec2.add(config.baseOffset, vec2.add(config.muzzleOffset or {0,0}, vec2.div(imageOffset, 8)))
	end

	-- elemental fire sounds
	if config.fireSounds then
		construct(config, "animationCustom", "sounds", "fire")
		local sound = randomFromList(config.fireSounds, seed, "fireSound")
		config.animationCustom.sounds.fire = type(sound) == "table" and sound or { sound }
	end

	-- build inventory icon
	if not config.inventoryIcon and config.animationParts then
		config.inventoryIcon = jarray()
		local parts = builderConfig.iconDrawables or {}
		for _,partName in pairs(parts) do
			local drawable = {
				image = config.animationParts[partName] .. config.paletteSwaps,
				position = partImagePositions[partName]
			}
			table.insert(config.inventoryIcon, drawable)
		end
	end

	-- populate tooltip fields

	local primaryAbility=configParameterDeep("primaryAbility")
	local altAbility=configParameterDeep("altAbility")

	config.tooltipFields = {}
	local fireTime = parameters.primaryAbility.fireTime or config.primaryAbility.fireTime or 1.0
	local baseDps = parameters.primaryAbility.baseDps or config.primaryAbility.baseDps or 0
	local energyUsage = parameters.primaryAbility.energyUsage or config.primaryAbility.energyUsage or 0
	config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
	config.tooltipFields.dpsLabel = util.round(baseDps * config.damageLevelMultiplier, 1)
	config.tooltipFields.speedLabel = util.round(1 / fireTime, 1)

	local damagePerShot = baseDps * fireTime * config.damageLevelMultiplier
	local energyPerShot = energyUsage * fireTime

	config.tooltipFields.damagePerShotLabel = util.round(baseDps * fireTime * config.damageLevelMultiplier, 1)
	config.tooltipFields.energyPerShotLabel = util.round(energyUsage * fireTime, 1)

	-- ***ORIGINAL CODE BY ALBERTO-ROTA and SAYTER***--and Khe
	-- FU ADDITIONS
	parameters.isAmmoBased = configParameter("isAmmoBased")
	if type(parameters.isAmmoBased)=="table" then
		if (#parameters.isAmmoBased >= 2) and (type(parameters.isAmmoBased[1]) == "number") and (type(parameters.isAmmoBased[2]) == "number") then
			parameters.isAmmoBased=math.random(parameters.isAmmoBased[1],parameters.isAmmoBased[2])
		elseif (#parameters.isAmmoBased == 1) and (type(parameters.isAmmoBased[1]) == "number") then
			parameters.isAmmoBased=parameters.isAmmoBased[1]
		else
			parameters.isAmmoBased=0
		end
	end
	local oldCTooltip = config.tooltipKind
	local oldPTooltip = parameters.tooltipKind

	if ( parameters.isAmmoBased == 1 ) then -- if its ammo based, we set the relevant data to the tooltip
		parameters.magazineSizeFactor = valueOrRandom(parameters.magazineSizeFactor, seed, "magazineSizeFactor")
		parameters.reloadTimeFactor = valueOrRandom(parameters.reloadTimeFactor, seed, "reloadTimeFactor")
		config.magazineSize = scaleConfig(parameters.primaryAbility.energyUsageFactor, config.magazineSize) or 0
	end

	local newMagSize = ((parameters.isAmmoBased == 1) and configParameter("magazineSize",0)) or 0
	if (parameters.isAmmoBased == 1) then
		if type(newMagSize) == "table" then
			if type(newMagSize[1]) == "number" and type(newMagSize[2]) == "number" then
				newMagSize = math.random(math.min(newMagSize[1],newMagSize[2]),math.max(newMagSize[1],newMagSize[2]))
			else
				newMagSize = 0
			end
		end
		if type(newMagSize) == "number" then
			newMagSize = util.round(newMagSize, 0)
		else
			newMagSize = 0
		end
	end
	if (parameters.isAmmoBased == 1) and (newMagSize >= 1) then
		config.tooltipKind = "gun2"
		parameters.tooltipKind = "gun2"
		config.magazineSize = newMagSize
		config.reloadTime = scaleConfig(parameters.reloadTimeFactor, config.reloadTime) or 0
		config.tooltipFields.energyPerShotLabel = util.round((energyUsage * fireTime)/2, 1)	-- these weapons have 50% energy cost
		config.tooltipFields.magazineSizeLabel = newMagSize -- label it!
		config.tooltipFields.reloadTimeLabel = util.round(configParameter("reloadTime",1),1) .. "s"
	else
		parameters.isAmmoBased = 0
		config.tooltipKind = oldCTooltip
		parameters.tooltipKind = oldPTooltip

		config.magazineSize = 0
		config.tooltipFields.magazineSizeLabel = "--"
		parameters.magazineSizeFactor = 0

		parameters.reloadTimeFactor = 0
		config.reloadTime = 0
		config.tooltipFields.reloadTimeLabel = "--"
	end

	if (configParameter("critChance")) then
		config.tooltipFields.critChanceLabel = util.round(configParameter("critChance",0), 0)
	else
		config.tooltipFields.critChanceLabel = "--"
	end

	if (configParameter("critBonus")) then
		config.tooltipFields.critBonusLabel = util.round(configParameter("critBonus",0), 0)
	else
		config.tooltipFields.critBonusLabel = "--"
	end

	if (configParameter("stunChance")) then
		config.tooltipFields.stunChanceLabel = util.round(configParameter("stunChance",0), 0)
	else
		config.tooltipFields.stunChanceLabel = "--"
	end

	config.tooltipFields.damagePerEnergyLabel = util.round(damagePerShot / energyPerShot, 1)

	config.tooltipFields.magazineSizeImage = "/interface/statuses/ammo.png"
	config.tooltipFields.reloadTimeImage = "/interface/statuses/reload.png"
	config.tooltipFields.critChanceImage = "/interface/statuses/crit2.png"
	config.tooltipFields.critBonusImage = "/interface/statuses/dmgplus.png"

	-- Staff and Wand specific --
	if primaryAbility and primaryAbility.projectileParameters then
		if primaryAbility.projectileParameters.baseDamage then
			config.tooltipFields.staffDamageLabel = (primaryAbility.projectileParameters.baseDamage) * configParameterDeep("damageLevelMultiplier",1) * configParameterDeep("baseDamageFactor",1)
		end
	end

	if primaryAbility.energyCost then
		config.tooltipFields.staffEnergyLabel = primaryAbility.energyCost
	end
	if primaryAbility.energyPerShot then
		config.tooltipFields.staffEnergyLabel = primaryAbility.energyPerShot
	end
	if primaryAbility.maxCastRange then
		config.tooltipFields.staffRangeLabel = primaryAbility.maxCastRange
	--else
		--config.tooltipFields.staffRangeLabel = 25
	end
	if primaryAbility.projectileCount then
		config.tooltipFields.staffProjectileLabel = primaryAbility.projectileCount
	--else
		--config.tooltipFields.staffProjectileLabel = 1
	end
	--

	if elementalType ~= "physical" then
		config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
	else
		config.tooltipFields.damageKindImage = "/interface/elements/physical.png"
	end

	if primaryAbility then
		config.tooltipFields.primaryAbilityTitleLabel = "Primary:"
		config.tooltipFields.primaryAbilityLabel = primaryAbility.name or "unknown"
	end

	if altAbility then
		config.tooltipFields.altAbilityTitleLabel = "Special:"
		config.tooltipFields.altAbilityLabel = altAbility.name or "unknown"
	end

	-- set price
	config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

	return config, parameters
end

function scaleConfig(ratio, value)
	ratio = ratio or 0.5
	if type(value) == "table" then
		return util.lerp(ratio, value[1], value[2])
	else
		return value
	end
end

require "/scripts/util.lua"
require "/scripts/vec2.lua"
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

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end
  setupAbility(config, parameters, "primary")
  setupAbility(config, parameters, "alt")
  -- elemental type and config (for alt ability)
  local elementalType = configParameter("elementalType", "physical")
  replacePatternInData(config, nil, "<elementalType>", elementalType)
  if (type(config.altAbility)=="table") and (type(config.altAbility.elementalConfig)=="table") and (type(elementalType)=="string") and ((type(config.altAbility.elementalConfig[elementalType])=="table") or (type(config.altAbility.elementalConfig["physical"])=="table"))  then
    --The difference is here, i added an if null-coalescing operation that checks if the alt ability has the elementalType in the elementalConfig list and replaces it with the physical type if it doesn't exist.
		util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType] or config.altAbility.elementalConfig["physical"] or {})
  --[[elseif config.altAbility then
    --debug code in case it's needed later.
	local buffer={}
	buffer["itemid"]=config.itemName
	--sb.logInfo("%s",config)
	buffer["elementalType"]=type(elementalType)
	if config.altAbility then
		buffer["altAbility"]=type(config.altAbility)
		if config.altAbility.elementalConfig then
			buffer["elementalConfig"]=type(config.altAbility.elementalConfig)
			if elementalType and config.altAbility.elementalConfig[elementalType] then
				buffer["eTypeConfig"]=type(config.altAbility.elementalConfig[elementalType])
			end
			if config.altAbility.elementalConfig["physical"] then
				buffer["physConfig"]=type(config.altAbility.elementalConfig["physical"])
			end
		end
	end
	sb.logInfo("REE %s",buffer)]]
  end

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))
  
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
    for i, drawable in ipairs(config.inventoryIcon) do
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
    config.tooltipFields.dpsLabel = util.round((config.primaryAbility.baseDps or 0) * config.damageLevelMultiplier, 1)
    config.tooltipFields.speedLabel = util.round(1 / (config.primaryAbility.fireTime or 1.0), 1)
    config.tooltipFields.damagePerShotLabel = util.round((config.primaryAbility.baseDps or 0) * (config.primaryAbility.fireTime or 1.0) * config.damageLevelMultiplier, 1)
    config.tooltipFields.energyPerShotLabel = util.round((config.primaryAbility.energyUsage or 0) * (config.primaryAbility.fireTime or 1.0), 1)
    -- *******************************
    -- FU ADDITIONS 
      if (configParameter("isAmmoBased")==1) then
        config.tooltipFields.energyPerShotLabel = util.round(((config.primaryAbility.energyUsage or 0) * (config.primaryAbility.fireTime or 1.0)/2), 1)
	config.tooltipFields.magazineSizeLabel = util.round(configParameter("magazineSize",0), 0)
	config.tooltipFields.reloadTimeLabel = configParameter("reloadTime",1) .. "s"	      
      else
        config.tooltipFields.magazineSizeLabel = "--"
        config.tooltipFields.reloadTimeLabel = "--"
      end
      
      config.tooltipFields.critChanceLabel = util.round(configParameter("critChance",1), 0)    -- rather than not applying a bonus to non-crit-enabled weapons, we just set it to always be at least 1
      
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
      
	config.tooltipFields.magazineSizeImage = "/interface/statuses/ammo.png"  
    	config.tooltipFields.reloadTimeImage = "/interface/statuses/reload.png"  
        config.tooltipFields.critBonusImage = "/interface/statuses/dmgplus.png"  
        config.tooltipFields.critChanceImage = "/interface/statuses/crit2.png" 
        
    -- weapon abilities
    
    --overheating
    if config.primaryAbility.overheatLevel then
	    config.tooltipFields.overheatLabel = util.round(config.primaryAbility.overheatLevel / config.primaryAbility.heatGain, 1)
	    config.tooltipFields.cooldownLabel = util.round(config.primaryAbility.overheatLevel / config.primaryAbility.heatLossRateMax, 1)    
    end

    -- Staff and Wand specific --
    if config.primaryAbility.projectileParameters then
	    if config.primaryAbility.projectileParameters.baseDamage then
		    config.tooltipFields.staffDamageLabel = config.primaryAbility.projectileParameters.baseDamage  
	    end	     
    end    

    if config.primaryAbility.energyCost then
	    config.tooltipFields.staffEnergyLabel = config.primaryAbility.energyCost
    end 
    if config.primaryAbility.energyPerShot then
	    config.tooltipFields.staffEnergyLabel = config.primaryAbility.energyPerShot
    end       
    if config.primaryAbility.maxCastRange then
	    config.tooltipFields.staffRangeLabel = config.primaryAbility.maxCastRange
    else
    	    config.tooltipFields.staffRangeLabel = 25
    end  
    if config.primaryAbility.projectileCount then
	    config.tooltipFields.staffProjectileLabel = config.primaryAbility.projectileCount
    else
    	    config.tooltipFields.staffProjectileLabel = 1
    end 
    
    -- Recoil
    if config.primaryAbility.recoilVelocity then
	    config.tooltipFields.isCrouch = configParameter("crouchReduction",false)
	    config.tooltipFields.recoilStrength = util.round(configParameter("recoilVelocity",0), 0)
	    config.tooltipFields.recoilCrouchStrength = util.round(configParameter("crouchRecoilVelocity",0), 0)    
    end
    

    
    -- *******************************
    if elementalType ~= "physical" then
      config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
    else
      config.tooltipFields.damageKindImage = "/interface/elements/physical.png"
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

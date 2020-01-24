require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/scripts/staticrandom.lua"

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

  if level and not configParameter("fixedLevel", false) then
    parameters.level = level
  end

  config.description = configParameter("description",0)
  config.shortdescription = configParameter("shortdescription",0)
  config.inventoryIcon = configParameter("inventoryIcon",0)

  if config.leveledStatusEffects then
    config.leveledStatusEffects[1].baseMultiplier = (config.leveledStatusEffects[1].baseMultiplier - 1) + 1
    config.leveledStatusEffects[3].amount = config.leveledStatusEffects[3].amount 
    config.leveledStatusEffects[4].amount = config.leveledStatusEffects[4].amount 
  end
  
  if config.statusEffects then
    config.statusEffects[3].amount = config.statusEffects[3].amount 
    config.statusEffects[4].amount = config.statusEffects[4].amount 
  end
  
  
  if config.level < 3 then
    config.rarity = "common"
  elseif config.level == 3 then
    config.rarity = "uncommon"
  elseif config.level >= 4 then
    config.rarity = "rare"
  elseif config.level >= 6 then 
    config.rarity = "legendary"
  elseif config.level == 8 then
    config.rarity = "essential"
  end


    
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))
  config.tooltipFields = {}
  
  config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
  
  if config.leveledStatusEffects then 
          config.tooltipFields.priceLabel = config.price
	  config.tooltipFields.cooldownLabel = parameters.cooldownTime or config.cooldownTime
	  config.tooltipFields.rarity = configParameter("rarity")
	  config.tooltipFields.blockLabel = configParameter("perfectBlockTime",0)
	  config.tooltipFields.stamLabel = configParameter("shieldStamina",0) * 100
	  config.tooltipFields.hpLabel = configParameter("shieldHealthBonus",0) * 100 
	  config.tooltipFields.energyLabel = configParameter("shieldEnergyBonus",0) * 100
	  config.tooltipFields.critBonusLabel = configParameter("critBonus,0")
	  config.tooltipFields.critChanceLabel = configParameter("critChance",0)
	  config.tooltipFields.shieldBashLabel = configParameter("shieldBash",0)
	  config.tooltipFields.shieldBashPushLabel = configParameter("shieldBashPush",0)  
	  config.tooltipFields.stunChance = util.round(configParameter("stunChance",0), 0)    
  end
  
  if config.statusEffects then
  -- this area should display Immunities, Resistances
  end
  
  

  
  return config, parameters
end


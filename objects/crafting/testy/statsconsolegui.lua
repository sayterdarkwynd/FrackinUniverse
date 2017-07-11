require("/scripts/util.lua")

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
  
  -- tooltip fields
  config.tooltipFields = {}
  config.tooltipFields.currentHealth = util.round(status.resource("health"))
  config.tooltipFields.currentEnergy = util.round(status.resource("energy"))
  
  config.tooltipFields.isOmnivore = util.round(status.stat("isOmnivore",0))
  config.tooltipFields.isCarnivore = util.round(status.stat("isCarnivore",0))
  config.tooltipFields.isHerbivore = util.round(status.stat("isHerbivore",0))
  
  config.tooltipFields.critChance = util.round(status.stat("critChance",0))
  config.tooltipFields.critBonus = util.round(status.stat("critBonus",0))
  config.tooltipFields.stunChance = util.round(status.stat("stunChance",0))
 
  config.tooltipFields.stunChance = util.round(status.stat("physicalResistance",0))
  config.tooltipFields.stunChance = util.round(status.stat("fireResistance",0))
  config.tooltipFields.stunChance = util.round(status.stat("iceResistance",0))
  config.tooltipFields.stunChance = util.round(status.stat("electricResistance",0))
  config.tooltipFields.stunChance = util.round(status.stat("poisonResistance",0))
  config.tooltipFields.stunChance = util.round(status.stat("shadowResistance",0))
  config.tooltipFields.stunChance = util.round(status.stat("cosmicResistance",0))
  config.tooltipFields.stunChance = util.round(status.stat("radioactiveResistance",0))
  
  
  return config, parameters
end
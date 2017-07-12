require "/scripts/util.lua"

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

  -- set price
  config.price = configParameter("price", 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  -- tooltip fields
  config.tooltipFields = {}
  config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
  config.tooltipFields.healthLabel = util.round(configParameter("baseShieldHealth", 0) * root.evalFunction("shieldLevelMultiplier", configParameter("level", 1)), 0)
  config.tooltipFields.cooldownLabel = parameters.cooldownTime or config.cooldownTime
  config.tooltipFields.blockLabel = configParameter("perfectBlockTime",0)
  config.tooltipFields.stamLabel = configParameter("shieldStamina",0) * 100
  config.tooltipFields.hpLabel = configParameter("shieldHealthBonus",0) * 100 
  config.tooltipFields.energyLabel = configParameter("shieldEnergyBonus",0) * 100
  config.tooltipFields.critBonusLabel = configParameter("critBonus,0")
  config.tooltipFields.critChanceLabel = configParameter("critChance",0)
  config.tooltipFields.shieldBashLabel = configParameter("shieldBash",0)
  config.tooltipFields.shieldBashPushLabel = configParameter("shieldBashPush",0)  
  return config, parameters
end

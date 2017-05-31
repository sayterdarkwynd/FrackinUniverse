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
  config.tooltipFields.blockLabel = configParameter("perfectBlockTime")
  config.tooltipFields.stamLabel = configParameter("shieldStamina") * 100
  config.tooltipFields.hpLabel = configParameter("shieldHealthBonus") * 100 
  config.tooltipFields.energyLabel = configParameter("shieldEnergyBonus") * 100
  config.tooltipFields.critBonusLabel = configParameter("critBonus")
  config.tooltipFields.critChanceLabel = configParameter("critChance")
  return config, parameters
end

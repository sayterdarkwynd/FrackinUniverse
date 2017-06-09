require "/scripts/util.lua"
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

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  config.tooltipFields = {}
  config.tooltipFields.subtitle = parameters.category
  config.tooltipFields.speedLabel = util.round(1 / config.primaryAbility.fireTime, 1)
  config.tooltipFields.damagePerShotLabel = util.round(
      (config.primaryAbility.crackDps + config.primaryAbility.chainDps) * config.primaryAbility.fireTime * config.damageLevelMultiplier, 1)
  if config.elementalType and config.elementalType ~= "physical" then
    config.tooltipFields.damageKindImage = "/interface/elements/"..config.elementalType..".png"
  end
  if config.altAbility then
    config.tooltipFields.altAbilityTitleLabel = "Special:"
    config.tooltipFields.altAbilityLabel = config.altAbility.name or "unknown"
  end
    -- *******************************
    -- FU ADDITIONS 
      config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
      config.tooltipFields.critChanceLabel = util.round(configParameter("critChance",0), 0)
      config.tooltipFields.critBonusLabel = util.round(configParameter("critBonus",0), 0)
      
      
    -- *******************************
  -- set price
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end

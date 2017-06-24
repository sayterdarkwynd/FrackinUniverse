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

  -- load and merge combo finisher
  local comboFinisherSource = configParameter("comboFinisherSource")
  if comboFinisherSource then
    local comboFinisherConfig = root.assetJson(comboFinisherSource)
    util.mergeTable(config, comboFinisherConfig)
  end

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  config.tooltipFields = {}
  config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
  config.tooltipFields.subtitle = parameters.category
  config.tooltipFields.speedLabel = util.round(1 / config.primaryAbility.fireTime, 1)
  config.tooltipFields.damagePerShotLabel = util.round(config.primaryAbility.baseDps * config.primaryAbility.fireTime * config.damageLevelMultiplier, 1)
  if config.comboFinisher then
    config.tooltipFields.comboFinisherTitleLabel = "Finisher:"
    config.tooltipFields.comboFinisherLabel = config.comboFinisher.name or "unknown"
  end

    -- *******************************
    -- FU ADDITIONS 
      config.tooltipFields.critChanceLabel = util.round(configParameter("critChance",0), 0)
      config.tooltipFields.critBonusLabel = util.round(configParameter("critBonus",0), 0)
    -- *******************************
    
  -- set price
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end

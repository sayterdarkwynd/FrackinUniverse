require "/scripts/util.lua"
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

  -- select, load and merge abilities
  setupAbility(config, parameters, "alt")
  setupAbility(config, parameters, "primary")

  -- elemental type
  local elementalType = parameters.elementalType or config.elementalType or "physical"
  replacePatternInData(config, nil, "<elementalType>", elementalType)

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  config.tooltipFields = {}
  config.tooltipFields.subtitle = parameters.category
  config.tooltipFields.maxDamageLabel = util.round(config.projectileParameters.power * config.damageLevelMultiplier, 1)
  if elementalType ~= "physical" then
    config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
  end
    -- *******************************
    -- FU ADDITIONS 
      config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
      config.tooltipFields.shieldPowerLabel = configParameter("shieldPower")
      config.tooltipFields.shieldHealthLabel = (configParameter("shieldHealth",1) * configParameter("level",1))
      config.tooltipFields.forceLabel = config.projectileParameters.controlForce or 0
      config.tooltipFields.knockbackLabel = config.projectileParameters.knockback or 0   
      config.tooltipFields.critChanceLabel = util.round(configParameter("critChance",0), 0)
      config.tooltipFields.critBonusLabel = util.round(configParameter("critBonus",0), 0)
    -- *******************************
  -- set price
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end

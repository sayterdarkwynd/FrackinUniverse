require "/quests/scripts/main.lua"
require('/quests/scripts/conditions/neb-damageTypeKills.lua')
--require('/quests/scripts/conditions/neb-monsterTypeKills.lua')

function buildConditions()
  local conditions = {}
  local conditionConfig = config.getParameter("conditions", {})

  for _,config in pairs(conditionConfig) do
    local newCondition
    if config.type == "gatherItem" then
      newCondition = buildGatherItemCondition(config)
    elseif config.type == "gatherTag" then
      newCondition = buildGatherTagCondition(config)
    elseif config.type == "shipLevel" then
      newCondition = buildShipLevelCondition(config)
    elseif config.type == "scanObjects" then
      newCondition = buildScanObjectsCondition(config)
    elseif config.type == "damageTypeKills" then
      newCondition = buildDamageTypeKillCondition(config)
    --elseif config.type == "killMonsterType" then
    --  newCondition = buildKillMonsterTypeCondition(config)
    end

    table.insert(conditions, newCondition)
  end

  return conditions
end
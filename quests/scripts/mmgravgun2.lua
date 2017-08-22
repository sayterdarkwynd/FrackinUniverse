require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require("/quests/scripts/portraits.lua")
require('/quests/scripts/conditions/gather.lua')
require('/quests/scripts/conditions/ship.lua')
require('/quests/scripts/conditions/scanning.lua')
require('/quests/scripts/messages.lua')

function init()
  self.conditions = buildConditions()
  self.failConditions = buildFailConditions()

  buildMessageHandlers()
  setPortraits()
end

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
    end

    table.insert(conditions, newCondition)
  end

  return conditions
end

function buildFailConditions()
  local conditions = config.getParameter("failConditions", {})

  for _,config in pairs(conditions) do
    if config.type == "proximity" then
      config.tracker = util.uniqueEntityTracker(config.entityUid)
    end
  end

  return conditions
end

function conditionsMet()
  for _, condition in pairs(self.conditions) do
    if not condition:conditionMet() then return false end
  end

  return true
end

function failConditionMet()
  for _,condition in pairs(self.failConditions) do
    if condition.type == "proximity" then
      local result = condition.tracker()
      if result and (condition.range < 0 or world.magnitude(result, entity.position()) < condition.range) then
        quest.setFailureText(condition.failureText)
        return true
      end
    end
  end

  return false
end

function questStart()
  for _, condition in pairs(self.conditions) do
    if condition.onQuestStart then condition:onQuestStart() end
  end

  local acceptItems = config.getParameter("acceptItems", {})
  for _,item in ipairs(acceptItems) do
    player.giveItem(item)
  end

  local associatedMission = config.getParameter("associatedMission")
  if associatedMission then
    player.enableMission(associatedMission)
  end
end

function questComplete()
  setPortraits()

  for _, condition in pairs(self.conditions) do
    if condition.onQuestComplete then condition:onQuestComplete() end
  end

  local mm = player.essentialItem("beamaxe")
  local newmm = root.createItem("mmgravgun2")

  -- Upgrades that this MM comes with (fake size upgrades for MMM compatibility)
  newmm.parameters.upgrades = { "size101", "size102", "size103", "size104", "liquidcollection" }

  -- Upgrades that the old MM may have obtained
  local possible = { "wiremode", "paintmode" }

  -- Add any upgrades from the old MM that we don't have
  for _,x in ipairs(mm.parameters.upgrades or {}) do
      for _,y in ipairs(possible) do
          if x == y then table.insert(newmm.parameters.upgrades, y) break end
      end
  end

  -- Add related stats to parameters
  local config = root.itemConfig("mmgravgun2").config
  newmm.parameters.blockRadius = config.blockRadius
  newmm.parameters.tileDamage = config.tileDamage
  newmm.parameters.canCollectLiquid = config.canCollectLiquid

  -- Finally, give the player the new MM
  player.giveEssentialItem("beamaxe", newmm)
  status.setStatusProperty("bonusBeamGunRadius", 0)

  questutil.questCompleteActions()
end

function update(dt)
  promises:update()

  -- Set objectives and progress bar
  local objectives = {}
  local progress = {}
  for _,condition in pairs(self.conditions) do
    if condition.objectiveText then
      local objectiveText = condition:objectiveText()
      if objectiveText then
        table.insert(objectives, { condition:objectiveText(), condition:conditionMet() })
      end
    end
    if condition.progress then
      table.insert(progress, condition:progress())
    end
  end
  quest.setObjectiveList(objectives)
  if #progress > 0 then
    quest.setProgress(util.sum(progress) / #progress)
  end

  if conditionsMet() then
    if config.getParameter("requireTurnIn", false) then
      quest.setCanTurnIn(true)
      if config.getParameter("turnInDescription") then
        quest.setObjectiveList({{config.getParameter("turnInDescription"), false}})
      end
    else
      quest.complete()
    end
  else
    quest.setCanTurnIn(false)
    for _, condition in pairs(self.conditions) do
      if condition.onUpdate then condition:onUpdate() end
    end
  end

  if failConditionMet() then
    quest.fail()
  end
end

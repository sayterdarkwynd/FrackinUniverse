require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/portraits.lua"
require "/quests/scripts/questutil.lua"

function init()
  setPortraits()

  storage.complete = storage.complete or false

  self.compassUpdate = config.getParameter("compassUpdate", 0.5)
  self.wagnerUid = config.getParameter("wagnerUid")
  self.repairQuest = config.getParameter("repairQuest")

  storage.stage = storage.stage or 1
  self.stages = {
    findWagner,
    killShoggoth
  }

  self.state = FSM:new()
  self.state:set(self.stages[storage.stage])
end

function questInteract(entityId)
  if self.onInteract then
    return self.onInteract(entityId)
  end
end

function questStart()
end

function update(dt)
  self.state:update(dt)

  if storage.complete then
    quest.setCanTurnIn(true)
  end
end

function questComplete()
  setPortraits()
  questutil.questCompleteActions()
end

function findWagner()
  quest.setParameter("wagner", {type = "entity", uniqueId = self.wagnerUid, indicator = "/interface/quests/questgiver.animation"})
  quest.setIndicators({"wagner"})

  quest.setObjectiveList({{config.getParameter("descriptions.findWagner"), false}})

  self.onInteract = function(entityId)
    if world.entityUniqueId(entityId) == self.wagnerUid then
      player.startQuest(self.repairQuest)
      self.onInteract = nil
      return true
    end
  end

  local findMechanic = util.uniqueEntityTracker(self.wagnerUid, self.compassUpdate)
  while not player.hasQuest(self.repairQuest) do
    questutil.pointCompassAt(findWagner())
    coroutine.yield()
  end

  storage.stage = 2
  self.state:set(self.stages[storage.stage])
end

function findShoggoth()
  quest.setIndicators({})
  quest.setCompassDirection(nil)
  quest.setCanTurnIn(true)

  quest.setObjectiveList({{config.getParameter("descriptions.findShoggoth"), false}})

  local trackShoggoth = util.uniqueEntityTracker(self.shoggothUid, self.compassUpdate)
  while true do
    questutil.pointCompassAt(trackShoggoth())

    coroutine.yield()
  end
end

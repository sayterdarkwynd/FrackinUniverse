require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/portraits.lua"
require "/quests/scripts/questutil.lua"

function init()
  setPortraits()

  storage.complete = storage.complete or false

  self.compassUpdate = config.getParameter("compassUpdate", 0.5)

  self.mechanicUid = config.getParameter("mechanicUid")
  self.drillUid = config.getParameter("drillUid")

  storage.stage = storage.stage or 1
  self.stages = {
    findCrystals,
    turnIn
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
  player.enableMission(config.getParameter("associatedMission"))
  player.playCinematic(config.getParameter("missionUnlockedCinema"))
end

function update(dt)
  self.state:update(dt)

  if storage.complete then
    quest.setCanTurnIn(true)
  end
end

function questComplete()
  if player.hasCompletedQuest("fu_byos") then
    player.giveItem({name = "supermatter", count = 20})
  else
    player.upgradeShip(config.getParameter("shipUpgrade"))
    player.playCinematic(config.getParameter("shipUpgradeCinema"))
  end
  
  setPortraits()
  questutil.questCompleteActions()
end


function findCrystals()
  quest.setParameter("drill", {type = "entity", uniqueId = self.drillUid})
  quest.setIndicators({"drill"})

  quest.setObjectiveList({{config.getParameter("descriptions.findCrystals"), false}})

  self.onInteract = function(entityId)
    if world.entityUniqueId(entityId) == self.drillUid then
      quest.setIndicators({})
      storage.stage = 2
      player.playCinematic(config.getParameter("acquireCrystalsCinema"))

      self.onInteract = nil
      return false
    end
  end

  util.wait(3.0)
  player.radioMessage(config.getParameter("missionRadioMessage"))

  local findDrill = util.uniqueEntityTracker(self.drillUid, self.compassUpdate)
  while storage.stage == 1 do
    questutil.pointCompassAt(findDrill())
    coroutine.yield()
  end

  self.state:set(self.stages[storage.stage])
end

function turnIn()
  quest.setIndicators({})
  quest.setCompassDirection(nil)
  quest.setObjectiveList({{config.getParameter("descriptions.turnIn"), false}})
  quest.setCanTurnIn(true)

  local findMechanic = util.uniqueEntityTracker(self.mechanicUid, self.compassUpdate)
  while storage.stage == 2 do
    questutil.pointCompassAt(findMechanic())
    coroutine.yield()
  end
end

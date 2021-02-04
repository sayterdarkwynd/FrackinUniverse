require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"

function init()
  storage.complete = storage.complete or false
  self.compassUpdate = config.getParameter("compassUpdate", 0.5)
  self.descriptions = config.getParameter("descriptions")

  self.techstationUid = config.getParameter("techstationUid")

  setPortraits()

  self.state = FSM:new()
  self.state:set(wakeSail)

  self.interactTimer = 0
  self.activationTimer = 1

  --temp until it's no longer a quest
  player.startQuest("fu_shipupgrades")
end

function questInteract(entityId)
  if self.interactTimer > 0 then return true end

  if world.entityUniqueId(entityId) == self.techstationUid then
	player.interact("ScriptPane", "/interface/ai/fu_byosai.config")
    self.interactTimer = 1.0
    return true
  end
end

function questStart()
end

function update(dt)
  self.state:update(dt)

  self.interactTimer = math.max(self.interactTimer - dt, 0)

  if self.questComplete then
	  world.sendEntityMessage(self.techstationUid, "activateShip")
    player.giveItem("statustablet")
    quest.complete()
  end
end

function wakeSail(dt)
  quest.setCompassDirection(nil)
  quest.setObjectiveList({
    {self.descriptions.wakeSail, false}
  })

  -- try to lounge in the teleporter for a bit
  util.wait(1.0, function()
    local teleporters = world.entityQuery(mcontroller.position(), 100, {includedTypes = {"object"}})
    teleporters = util.filter(teleporters, function(entityId)
      if string.find(world.entityName(entityId), "teleporterTier0") then
        return true
      end
    end)
    if #teleporters > 0 then
      player.lounge(teleporters[1])
      return true
    end
  end)

  util.wait(2.0)

  world.sendEntityMessage(self.techstationUid, "wakePlayer")

  local findTechStation = util.uniqueEntityTracker(self.techstationUid, self.compassUpdate)
  while true do
    questutil.pointCompassAt(findTechStation())

    local shipUpgrades = player.shipUpgrades()
    if shipUpgrades.shipLevel > 0 or world.getProperty("fu_byos") then
        self.questComplete = true
    end
    coroutine.yield()
  end
end

function questComplete()
  status.addEphemeralEffect("fu_byosfindship", 10)
  questutil.questCompleteActions()
end

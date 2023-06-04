require "/scripts/util.lua"
require "/quests/scripts/portraits.lua"
require "/quests/scripts/questutil.lua"

function init()
  setPortraits()

  storage.complete = storage.complete or false

  storage.stage = storage.stage or 1
  self.stages = {
    makeSTL,
    getErchius,
    makeFTL
  }

  self.descriptions = config.getParameter("descriptions")

  self.state = FSM:new()
  self.state:set(self.stages[storage.stage])
end

function questInteract(entityId)
end

function questStart()
  player.radioMessage("fu_byosftldrive-makeSTL")
end

function update(dt)
  self.state:update(dt)

  if storage.complete then
    quest.complete()
  end
end

function questComplete()
  setPortraits()
  questutil.questCompleteActions()
end

function makeSTL()
  while storage.stage == 1 do
    quest.setObjectiveList({{self.descriptions.makeSTL, false}})
    if player.hasItem({name = "fu_stldrive", count = 1}) then
      storage.stage = 2
    elseif player.hasItem({name = "fu_ftldrivesmall", count = 1}) then
      storage.complete = true
    end
    coroutine.yield()
  end

  self.state:set(self.stages[storage.stage])
end

function getErchius()
  player.radioMessage("fu_byosftldrive-getErchius1")
  player.radioMessage("fu_byosftldrive-getErchius2")
  player.radioMessage("fu_byosftldrive-getErchius3")

  while storage.stage == 2 do
    quest.setObjectiveList({{self.descriptions.getErchius, false}})
    quest.setProgress(player.hasCountOfItem("solidfuel") / 50)
    if player.hasItem({name = "solidfuel", count = 50}) then
      storage.stage = 3
    elseif player.hasItem({name = "fu_ftldrivesmall", count = 1}) then
      storage.complete = true
    end
    coroutine.yield()
  end

  self.state:set(self.stages[storage.stage])
end

function makeFTL()
  player.radioMessage("fu_byosftldrive-makeFTL")
  quest.setProgress(nil)

  while storage.stage == 3 do
    quest.setObjectiveList({{self.descriptions.makeFTL, false}})
    if player.hasItem({name = "fu_ftldrivesmall", count = 1}) then
      storage.complete = true
    end
    coroutine.yield()
  end
end

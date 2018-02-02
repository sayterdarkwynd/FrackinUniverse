require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/portraits.lua"

function init()
  storage.complete = storage.complete or false
  self.compassUpdate = config.getParameter("compassUpdate", 0.5)
  self.descriptions = config.getParameter("descriptions")

  self.gateRepairItem = config.getParameter("gateRepairItem")
  self.gateRepairCount = config.getParameter("gateRepairCount")

  if player.hasItem({name = "statustablet", count = 1}) then
    self.gateUid = "ancientgate2"
  else
    self.gateUid = "ancientgate"
  end
  
  self.techstationUid = config.getParameter("techstationUid")
  self.estherUid = config.getParameter("estherUid")

  self.findRange = config.getParameter("findRange")
  self.exploreTime = config.getParameter("exploreTime")
  storage.exploreTimer = storage.exploreTimer or 0
  storage.bookmarked = storage.bookmarked or false

  setPortraits()

  storage.stage = storage.stage or 1
  self.stages = {
    explore,
    findGate,
    collectRepairItem,
    repairGate,
    findEsther
  }

  self.state = FSM:new()
  self.state:set(self.stages[storage.stage])

  storage.gateActive = storage.gateActive or false
end

function questInteract(entityId)
  if self.onInteract then
    return self.onInteract(entityId)
  end
end

function questStart()
  player.upgradeShip(config.getParameter("shipUpgrade"))
  self.gateUid = "ancientgate"
end

function update(dt)
  self.state:update(dt)

  vinjGreeting()

  if not player.hasItem({name = "statustablet", count = 1}) then
    self.gateUid = "ancientgate"
  elseif player.hasItem({name = self.gateRepairItem, count = self.gateRepairCount}) or storage.stage >= 3 or player.hasItem({name = "statustablet", count = 1}) then 
    self.gateUid = "ancientgate2"  
  else
    self.gateUid = "ancientgate2" 
  end

  
  -- Skip ahead if the gate is already active 
  if storage.stage < 5 and gateActive() and player.hasItem({name = "statustablet", count = 1}) then
    storage.stage = 5
    self.gateUid = "ancientgate2" 
    self.state:set(gateRepaired)
  elseif storage.stage < 5 and gateActive() and not player.hasItem({name = "statustablet", count = 1}) then
    player.radioMessage("fu_start_needstricorder2")
  end

  if storage.complete then
    quest.setCanTurnIn(true)
  end
end


function vinjGreeting()
  if storage.exploreTimer >= 60 then
    player.radioMessage("fu_start_greetings0")
    player.radioMessage("fu_start_greetings1")
    player.radioMessage("fu_start_greetings2")
  end    
end


function gateActive()
  if storage.gateActive then return true end

  if not self.gatePromise then
    self.gatePromise = world.sendEntityMessage(self.gateUid, "isActive")
  else
    if self.gatePromise:finished() then
      if self.gatePromise:succeeded() then
        storage.gateActive = self.gatePromise:result() == true
      end
      self.gatePromise = nil
    end
  end

  return storage.gateActive
end

function explore()
  quest.setObjectiveList({{self.descriptions.explore, false}})
  self.gateUid = config.getParameter("gateUid")
  
  -- Wait until the player is no longer on the ship
  local findGate = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)
  local buffer = 0
  while storage.exploreTimer < self.exploreTime do
    local gatePosition = findGate()
    if gatePosition then
      -- Gate is on this world, put buffer onto the exploration timer
      storage.exploreTimer = storage.exploreTimer + buffer
      buffer = 0
      if world.magnitude(mcontroller.position(), gatePosition) < 200 then
        self.state:set(gateFound)
        coroutine.yield()
      end
    elseif gatePosition == nil then
      -- Gate is not in this world, discard the buffer
      buffer = 0
    end
    coroutine.yield()
  end

  storage.stage = 2

  player.radioMessage("gaterepair-findGate")

  util.wait(8)

  self.state:set(self.stages[storage.stage])
end


function findGate()
  quest.setProgress(nil)
  quest.setObjectiveList({{self.descriptions.findGate, false}})

  -- Wait until the player is no longer on the ship
  -- it is hard-set to ancientgate rather than self.gateUid to make sure the initial pointer goes to the right place.
  local findGate = util.uniqueEntityTracker("ancientgate", self.compassUpdate)
  while true do
    local result = findGate()
    questutil.pointCompassAt(result)
    if result and world.magnitude(mcontroller.position(), result) < 100 then
      self.state:set(gateFound)
    end
    coroutine.yield()
  end

  self.state:set(self.stages[storage.stage])
end

function gateFound()
  quest.setProgress(nil)
  quest.setCompassDirection(nil)
  player.radioMessage("gaterepair-gateFound1")
  --player.radioMessage("gaterepair-gateFound1b")
  player.radioMessage("gaterepair-gateFound2")
  storage.stage = 3
  self.gateUid = "ancientgate"
  util.wait(14)

  self.state:set(self.stages[storage.stage])
end

function collectRepairItem()
  quest.setCompassDirection(nil)

  quest.setParameter("ancientgate", {type = "entity", uniqueId = self.gateUid})
  quest.setIndicators({"ancientgate"})
  
  local findGate = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)
  while storage.stage == 3 do

    if player.hasItem({name = self.gateRepairItem, count = self.gateRepairCount}) and player.hasItem({name = "statustablet", count = 1}) then
      quest.setObjectiveList({{self.descriptions.collectRepairItem, false}})
      quest.setProgress(player.hasCountOfItem(self.gateRepairItem) / self.gateRepairCount)    
      self.gateUid = "ancientgate2"       
      storage.stage = 4
    elseif not player.hasItem({name = self.gateRepairItem, count = self.gateRepairCount}) and player.hasItem({name = "statustablet", count = 1}) then
      quest.setObjectiveList({{self.descriptions.collectRepairItem, false}})
      quest.setProgress(player.hasCountOfItem(self.gateRepairItem) / self.gateRepairCount)    
      self.gateUid = "ancientgate2"         
    else
      quest.setObjectiveList({{self.descriptions.makeTable, false}})    
      self.gateUid = "ancientgate"
      player.radioMessage("fu_start_needstricorder")
    end
       local result = findGate()
       questutil.pointCompassAt(result)   
       coroutine.yield()   
  end


  quest.setObjectiveList({})
  self.state:set(self.stages[storage.stage])
end

function repairGate()
  quest.setCompassDirection(nil)
  quest.setProgress(nil)

  quest.setParameter("ancientgate", {type = "entity", uniqueId = self.gateUid})
  quest.setIndicators({"ancientgate"})

  quest.setObjectiveList({
    {self.descriptions.repairGate, false}
  })

  local findGate = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)
  while storage.stage == 4 do
    questutil.pointCompassAt(findGate())

    -- Go back to last stage if player loses core fragments
    if not player.hasItem({name = self.gateRepairItem, count = self.gateRepairCount}) and player.hasItem({name = "statustablet", count = 1}) then
      storage.stage = 3
      self.gateUid = "ancientgate2"
      questutil.pointCompassAt(findGate())
      self.state:set(self.stages[storage.stage])
    elseif not player.hasItem({name = "statustablet", count = 1}) then
      storage.stage = 3
      quest.setObjectiveList({{self.descriptions.makeTable, false}})    
      self.gateUid = "ancientgate"
      player.radioMessage("fu_start_needstricorder")
      questutil.pointCompassAt(findGate())
      self.state:set(self.stages[storage.stage])
    end

    coroutine.yield()
  end

  self.onInteract = nil
  self.state:set(self.stages[storage.stage])
end

function gateRepaired()
  self.onInteract = nil
  quest.setCompassDirection(nil)
  quest.setProgress(nil)
  quest.setIndicators({})

  storage.stage = 5

  player.radioMessage("gaterepair-gateOpened1")
  player.radioMessage("gaterepair-gateOpened2")
  
  player.addTeleportBookmark(config.getParameter("outpostBookmark2"))
  player.radioMessage("fu_outpost1")  
  player.radioMessage("fu_outpost2")  
  
  self.state:set(self.stages[storage.stage])
end

function findEsther(dt)
  quest.setCompassDirection(nil)
  quest.setParameter("esther", {type = "entity", uniqueId = self.estherUid})
  quest.setIndicators({"esther"})
  quest.setObjectiveList({{self.descriptions.findEsther, false}})

  local trackEsther = util.uniqueEntityTracker(self.estherUid, self.compassUpdate)
  local trackGate = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)
  while true do
    if not storage.complete then
      local estherResult = trackEsther()
      questutil.pointCompassAt(estherResult)
      if estherResult then
        if not storage.bookmarked then
          player.addTeleportBookmark(config.getParameter("outpostBookmark"))
          storage.bookmarked = true
        end
        if world.magnitude(estherResult, mcontroller.position()) < self.findRange then
          player.playCinematic(config.getParameter("findEstherCinema"))
          storage.complete = true
        end
      end
    else
      quest.setCanTurnIn(true)
      quest.setIndicators({})
    end
    coroutine.yield()
  end
  self.state:set(self.stages[storage.stage])
end

function questComplete()
  setPortraits()
  questutil.questCompleteActions()
end

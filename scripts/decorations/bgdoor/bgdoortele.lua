require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.openAoe = config.getParameter("openAoe")
  self.openAoe[1] = object.toAbsolutePosition(self.openAoe[1])
  self.openAoe[2] = object.toAbsolutePosition(self.openAoe[2])

  self.connectedDoor = nil
  self.doorLocked = false
  self.lockInputLevel = nil
  self.forceOpenTimer = 0

  message.setHandler("openDoor", function()
    if animator.animationState("doorState") == "closed" or animator.animationState("doorState") == "transitioningclose" then
      animator.setAnimationState("doorState", "open")
      self.forceOpenTimer = 0.5
    end
  end
  )
  end

function update(dt)
  if not self.connectedDoor then
    checkConnections()
  end

--Input on 2nd node = no door open
  if object.isInputNodeConnected(1) then
    self.lockInputLevel = object.getInputNodeLevel(1)
    self.doorLocked = not self.lockInputLevel
  else
    self.doorLocked = false
  end
  self.forceOpenTimer = math.max(0, self.forceOpenTimer - dt)

--Look for nearby players
  local players = world.entityQuery(self.openAoe[1], self.openAoe[2], {
    includedTypes = {"player"},
    boundMode = "CollisionArea"
  })

     if #players > 0 and self.connectedDoor and animator.animationState("doorState") == "closed" and not self.doorLocked then
       animator.setAnimationState("doorState", "transitioningopen")
       animator.playSound("open")
     elseif #players == 0 and self.connectedDoor and animator.animationState("doorState") == "open" and self.forceOpenTimer == 0 and not self.doorLocked then
       animator.setAnimationState("doorState", "transitioningclose")
       animator.playSound("close")
     elseif not self.connectedDoor and animator.animationState("doorState") == "open" and self.forceOpenTimer == 0 and not self.doorLocked then
       animator.setAnimationState("doorState", "transitioningclose")
       animator.playSound("close")
     elseif animator.animationState("doorState") == "open" and self.doorLocked then
       animator.setAnimationState("doorState", "transitioningclose")
       animator.playSound("close")
     end

--If a door is connected, try to shut
  if self.connectedDoor and world.entityExists(self.connectedDoor) and not self.doorLocked then
    object.setInteractive(true)
  else
    object.setInteractive(false)
    self.connectedDoor = false
  end

--Debug openAoe and stored door connection ID, spazes out, but it works.
  local detectPoly = {self.openAoe[1], {self.openAoe[1][1], self.openAoe[2][2]}, self.openAoe[2], {self.openAoe[2][1], self.openAoe[1][2]}}
  world.debugPoly(detectPoly, "cyan")
  world.debugText("Lock: " .. sb.printJson(self.doorLocked), vec2.add(entity.position(), {0,1}), "yellow")
  world.debugText("Link ID: " .. sb.printJson(self.connectedDoor), vec2.add(entity.position(), {0,0}), "yellow")
  world.debugPoint(world.entityMouthPosition(entity.id()), "cyan")
  end

--Hit interact to do the time warp
function onInteraction(activator)
  local targetPosition = world.entityMouthPosition(self.connectedDoor)
  local interactor = activator.sourceId

  if self.connectedDoor then
    world.sendEntityMessage(interactor, "applyStatusEffect", "doorwarp", 0.1, self.connectedDoor)
  end
end

function onNodeChange()
  checkConnections()
end

function checkConnections()
  self.connectedDoor = nil
  for entityId, _ in pairs(object.getOutputNodeIds(0)) do
    if world.entityExists(entityId) then
      if world.getObjectParameter(entityId, "allowTele", false) then
        self.connectedDoor = entityId
      end
    end
  end
end

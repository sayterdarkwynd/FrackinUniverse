require "/scripts/vec2.lua"

function init()
  self.recoil = 0
  self.recoilRate = 0

  self.fireOffset = config.getParameter("fireOffset")
  updateAim()
  self.active = false
  
  storage.fireTimer = storage.fireTimer or 0
end


function raceroller()
  self.raceroller = math.random(20)
    if self.raceroller == 1 then 
      self.crewrace = "apex"
    elseif self.raceroller == 2 then
      self.crewrace = "avian"
    elseif self.raceroller == 3 then
      self.crewrace = "floran"
    elseif self.raceroller == 4 then
      self.crewrace = "glitch"
    elseif self.raceroller == 5 then
      self.crewrace = "human"
    elseif self.raceroller == 6 then
      self.crewrace = "hylotl"
    elseif self.raceroller == 7 then
      self.crewrace = "novakid"
    elseif self.raceroller == 8 then
      self.crewrace = "fenerox"
    elseif self.raceroller == 9 then
      self.crewrace = "shadow"    
    elseif self.raceroller == 10 then
      self.crewrace = "fuanodyne" 
    elseif self.raceroller == 11 then
      self.crewrace = "fudarkizku" 
    elseif self.raceroller == 12 then
      self.crewrace = "fuizku" 
    elseif self.raceroller == 13 then
      self.crewrace = "fukirhos" 
    elseif self.raceroller == 14 then
      self.crewrace = "fumantis" 
    elseif self.raceroller == 15 then
      self.crewrace = "fumantizi" 
    elseif self.raceroller == 16 then
      self.crewrace = "precursor" 
    elseif self.raceroller == 17 then
      self.crewrace = "radien" 
    elseif self.raceroller == 18 then
      self.crewrace = "thelusian"
    elseif self.raceroller == 19 then
      self.crewrace = "fupeglaci" 
    elseif self.raceroller == 20 then
      self.crewrace = "fufaleni"        
    else
      self.crewrace = "human"
    end  
end

function update(dt, fireMode, shiftHeld)
  updateAim()

  storage.fireTimer = math.max(storage.fireTimer - dt, 0)

  if self.active then
    self.recoilRate = 0
  else
    self.recoilRate = math.max(1, self.recoilRate + (10 * dt))
  end
  self.recoil = math.max(self.recoil - dt * self.recoilRate, 0)

  if self.active and not storage.firing and storage.fireTimer <= 0 then
    self.recoil = math.pi/2 - self.aimAngle
    activeItem.setArmAngle(math.pi/2)
    if animator.animationState("firing") == "off" then
      animator.setAnimationState("firing", "fire")
    end
    storage.fireTimer = config.getParameter("fireTime", 1.0)
    storage.firing = true

  end

  self.active = false
  
  if storage.firing and animator.animationState("firing") == "off" then
  raceroller()
    item.consume(1)
    local crewtype = config.getParameter("crewtype.crewname")
    local seed = math.random(255)
    local parameters = {}
    local crewrace = self.crewrace
      world.spawnNpc(activeItem.ownerAimPosition(), crewrace, crewtype, 1, seed, parameters)
      
    storage.firing = false
    return
  end
end

function activate(fireMode, shiftHeld)
  if not storage.firing then
    self.active = true
  end
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  self.aimAngle = self.aimAngle + self.recoil
  activeItem.setArmAngle(self.aimAngle)
  activeItem.setFacingDirection(self.aimDirection)
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(config.getParameter("inaccuracy", 0), 0))
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end

function holdingItem()
  return true
end

function recoil()
  return false
end

function outsideOfHand()
  return false
end

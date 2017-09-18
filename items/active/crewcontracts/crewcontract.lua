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
  self.isUnique = config.getParameter("isUnique")
  
  if self.isUnique then
    self.crewrace = config.getParameter("race")
  end
  
  if not self.isUnique then 
    self.raceroller = math.random(19)
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
    else
      self.crewrace = "human"
    end
  end    
end

function update(dt, fireMode, shiftHeld)
  updateAim()

  storage.fireTimer = math.max(storage.fireTimer - dt, 0)

  if self.active then
  raceroller()
    item.consume(1)
    local crewtype = config.getParameter("crewtype.crewname")
    local seed = math.random(255)
    local parameters = {}
      local crewrace = self.crewrace
      world.spawnNpc(mcontroller.position(), crewrace, crewtype, 1, seed, parameters)
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

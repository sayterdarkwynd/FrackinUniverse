require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/activeitem/stances.lua"
require "/scripts/companions/util.lua"

function callPetsSystem(message, ...)
  local owner = activeItem.ownerEntityId()
  local promise = world.sendEntityMessage(owner, message, ...)

  -- Message is sent only locally, so the promise should be fulfilled
  -- immediately.
  assert(promise:finished())

  if promise:succeeded() then
    return promise:result()
  else
    sb.logInfo("Error messaging pet system %s with %s: %s", owner, message, promise:error())
    return nil
  end
end

function init()
  initStances()

  self.podUuid = config.getParameter("podUuid")
  assert(self.podUuid ~= nil)

  self.collar = config.getParameter("currentCollar")
  --self.collar=nil
  self.pets = nil
  self.firstUpdate = true

  self.projectileId = nil
  self.returnProjectileId = nil
  setStance("idle")

  animator.setGlobalTag("health", "healthy")
end

function finishInit()
  if not config.getParameter("podItemHasPriority", false) then
    self.pets = callPetsSystem("pets.podPets", self.podUuid)
    if self.pets then
      callPetsSystem("pets.setPodCollar", self.podUuid, self.collar)
      activeItem.setInstanceValue("currentPets", self.pets)
      return
    end
  end

  -- The array of pets is in the parameters twice.
  -- 'currentPets' holds the state of the pets as they currently are.
  -- 'pets' is what they are restored to when the botpod is healed.
  -- This is so that, e.g. 'pets' can be [hemogoblin] while currentPets is
  -- [hemogoblinhead, hemogoblinbutt].
  self.pets = config.getParameter("currentPets") or config.getParameter("pets")
  activeItem.setInstanceValue("currentPets", self.pets)
  callPetsSystem("pets.setPodPets", self.podUuid, self.pets)
  callPetsSystem("pets.setPodCollar", self.podUuid, self.collar)
  activeItem.setInstanceValue("podItemHasPriority", false)
end

function updateHealthState()
  local health = arePetsAlive() and "healthy" or "dead"
  animator.setGlobalTag("health", health)
  activeItem.setInventoryIcon(config.getParameter("icons")[health])
end

function update(dt, fireMode, shiftHeld)
  if self.firstUpdate then
    finishInit()
    self.firstUpdate = false
  end

  self.pets = callPetsSystem("pets.podPets", self.podUuid)
  activeItem.setInstanceValue("currentPets", self.pets)
  updateHealthState()

  checkProjectiles()

  updateStance(dt)

  if fireMode ~= "primary" then
    self.fired = false
  end

  if self.stanceName == "idle" then
    if fireMode == "primary" and not self.fired then
      self.fired = true
      setStance("windup")
    end
  end

  if self.stanceName == "throw" then
    if not self.projectileId and not self.returnProjectileId then
      setStance("catch")
    end
  end

  updateAim()

  if self.stanceName == "dead" then
    shakePod()
  end
end

function shakePod()
  local frequency = config.getParameter("deadPodShake.frequency")
  local phase = math.rad(config.getParameter("deadPodShake.phase"))
  local amplitude = math.rad(config.getParameter("deadPodShake.amplitude"))

  local t = frequency * self.stanceTimer * math.pi * 2 + phase
  local armAngle = self.armAngle + amplitude * (math.abs(math.cos(t)) * 2 - 1)
  activeItem.setArmAngle(armAngle)
end

function uninit()
end

function showEnergyBall()
  animator.burstParticleEmitter("energyball")
end

function checkProjectiles()
  if self.projectileId then
    if not world.entityExists(self.projectileId) then
      self.projectileId = nil
      setStance("podTeleportCatch")
      showEnergyBall()
    elseif world.callScriptedEntity(self.projectileId, "monstersReleased") then
      self.returnProjectileId = self.projectileId
      self.projectileId = nil
    end
  elseif self.returnProjectileId then
    if not world.entityExists(self.returnProjectileId) then
      self.returnProjectileId = nil
    end
  end
end

function arePetsAlive()
  for _,pet in pairs(self.pets) do
    if not pet.status or not pet.status.dead then
      return true
    end
  end
  return false
end

function fire()
  if self.pets and not self.projectileId and not self.returnProjectileId then
    if arePetsAlive() then
      if callPetsSystem("pets.togglePod", self.podUuid) then
        throwProjectile()
        setStance("throw")
      else
        -- Monster was returned
        setStance("monsterEnergyCatch")
      end
    else
      animator.playSound("dead")
      activeItem.emote("sad")
      setStance("dead")
    end
  end
end

function throwProjectile()
  local position = firePosition()

  local params = config.getParameter("projectileParameters")

  params.podUuid = self.podUuid

  local collisionPoly = nil
  for _, pet in pairs(self.pets) do
    if not pet.collisionPoly then
      local movementSettings = root.monsterMovementSettings(pet.config.type)
      pet.collisionPoly = movementSettings.standingPoly or movementSettings.crouchingPoly or movementSettings.collisionPoly
    end
    if pet.collisionPoly then
      collisionPoly = pet.collisionPoly
      position = findCompanionSpawnPosition(position, collisionPoly)
      break
    end
  end

  params.movementSettings = {
      collisionPoly = collisionPoly
    }

  params.ownerAimPosition = activeItem.ownerAimPosition()
  if self.aimDirection < 0 then params.processing = "?flipx" end

  self.projectileId = world.spawnProjectile(
      config.getParameter("projectileType"),
      position,
      activeItem.ownerEntityId(),
      aimVector(),
      false,
      params
    )
  animator.playSound("throw")
end

require "/scripts/vec2.lua"

function init()
  self.fireOffset = config.getParameter("fireOffset")
  updateAim()

  storage.fireTimer = storage.fireTimer or 0
  self.recoilTimer = 0

  checkProjectile()
end

function activate(fireMode, shiftHeld)
  if fireMode == "primary" then
    if storage.projectileId and world.entityExists(storage.projectileId) then
      world.callScriptedEntity(storage.projectileId, "kill")
    elseif not world.pointTileCollision(firePosition())
        and status.overConsumeResource("energy", config.getParameter("fireEnergy")) then

      fire()
    end
  elseif fireMode == "alt"
      and storage.projectileId
      and not status.statPositive("activeMovementAbilities")
      and status.overConsumeResource("energy", config.getParameter("teleportEnergy")) then

    teleport()
  end
end

function update(dt, fireMode, shiftHeld)
  updateAim()

  self.recoilTimer = math.max(self.recoilTimer - dt, 0)
  activeItem.setRecoil(self.recoilTimer > 0)

  checkProjectile()
end

function uninit()

end

function fire()
  local projectileId = world.spawnProjectile(
      "translocatordisc2",
      firePosition(),
      activeItem.ownerEntityId(),
      aimVector(),
      false,
      {}
    )
  if projectileId then
    storage.projectileId = projectileId
    world.callScriptedEntity(projectileId, "setOwnerId", activeItem.ownerEntityId())
  end
  animator.playSound("fire")
  self.recoilTimer = config.getParameter("recoilTime", 0.12)
end

function teleport()
  if storage.projectileId then
    status.setStatusProperty("translocatorDiscId", storage.projectileId)
    status.addEphemeralEffect("translocate")
  end
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setArmAngle(self.aimAngle)
  activeItem.setFacingDirection(self.aimDirection)
end

function checkProjectile()
  if storage.projectileId
      and not (world.entityExists(storage.projectileId) and world.callScriptedEntity(storage.projectileId, "isTranslocatorDisc")) then

    animator.burstParticleEmitter("discReturn")
    storage.projectileId = nil
  end

  if storage.projectileId then
    activeItem.setCursor("/cursors/chargeready.cursor")
    animator.setAnimationState("disc", "hidden")
    animator.setLightActive("discGlow", false)
  else
    activeItem.setCursor("/cursors/reticle0.cursor")
    animator.setAnimationState("disc", "visible")
    animator.setLightActive("discGlow", true)
  end
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, self.aimAngle)
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end

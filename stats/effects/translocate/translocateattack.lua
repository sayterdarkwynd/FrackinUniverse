require "/scripts/vec2.lua"

function init()
  self.projectile = config.getParameter("baseProjectile")
  self.damage = config.getParameter("baseDamage",1)
  animator.playSound("activate")
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, 22)
  aimVector[1] = aimVector[1] * 1
  return aimVector
end

function update(dt)
  if animator.animationState("blink") == "none" then
    teleport()
  end
end

function teleport()
  local discId = status.statusProperty("translocatorDiscId")
  local teleportTarget = world.callScriptedEntity(discId, "teleportPosition", mcontroller.collisionPoly())

  damageConfig = { power = self.damage }

  if discId and world.entityExists(discId) then
    world.callScriptedEntity(status.statusProperty("translocatorDiscId"), "kill")
  end

  status.setStatusProperty("translocatorDiscId", nil)
  effect.setParentDirectives("")
  animator.burstParticleEmitter("translocate")
  animator.setAnimationState("blink", "blinkin")

  world.spawnProjectile(self.projectile,teleportTarget, discId, {0,-2}, false, damageConfig)
end



function uninit()

end

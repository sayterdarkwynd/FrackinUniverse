function reactionBuffCloud(operation, plan, triggerPosition)
  world.spawnProjectile("guardiandamagebuff", triggerPosition, entity.id(), dir, false, {speed = 5})
end

function reactionSpawnPiercingProjectile(operation, plan, triggerPosition)
  world.spawnProjectile("delayedplasmashot", triggerPosition, entity.id(), {1, 0}, false, {power = 5})
end

function init()


  --if mcontroller.onGround() then
      local projectileConfig = { power = 12 }
      animator.playSound("bombdrop")
      world.spawnProjectile("tentacleattack", mcontroller.position(), 0, {0, 0}, false, projectileConfig)
  --end

end

function update(dt)

end





function uninit()
   status.clearPersistentEffects("rootfu")
end
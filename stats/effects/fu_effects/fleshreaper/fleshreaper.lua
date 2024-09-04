function init()
  if mcontroller.onGround() then
      mcontroller.controlModifiers({airJumpModifier = self.airJumpModifier})
      local projectileConfig = { power = 12 }
      animator.playSound("bombdrop")
      world.spawnProjectile("bahamutboom", mcontroller.position(), 0, {0, 0}, false, projectileConfig)
  end

end

function update(dt)

end

function uninit()

end

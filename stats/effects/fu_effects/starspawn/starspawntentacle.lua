function init() 
  local bounds = mcontroller.boundBox()
  
  
  if mcontroller.onGround() then
      mcontroller.controlModifiers({airJumpModifier = self.airJumpModifier})
      local projectileConfig = { power = 12 }
      animator.playSound("bombdrop")  
      world.spawnProjectile("tentacleattack", mcontroller.position(), 0, {0, 0}, false, projectileConfig)    
      status.addPersistentEffect( "rootfu", math.huge)
  end  
  
end

function update(dt)

end





function uninit()
   status.clearPersistentEffects("rootfu")
end
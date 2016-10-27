function init() 
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end

function update(dt)
      world.spawnProjectile("bahamutboom", mcontroller.position(), 0, {0, 0}, false, projectileConfig)
end





function uninit()
  
end
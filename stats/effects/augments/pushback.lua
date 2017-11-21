function init()
  self.value = config.getParameter("refresh")
  script.setUpdateDelta(self.value)
end

function update(dt)
 
    local blastPower = { power = config.getParameter("damageAmount"), knockback = config.getParameter("knockbackAmount") }
    world.spawnProjectile("pushbackaugment", mcontroller.position(), entity.id(), {0, 0}, true, blastPower) 
    status.addEphemeralEffect("electricaura", 2)
end

function uninit()
  
end

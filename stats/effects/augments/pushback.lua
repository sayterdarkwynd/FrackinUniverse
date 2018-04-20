function init()
  self.value = config.getParameter("refresh",0)
  script.setUpdateDelta(self.value)
end

function update(dt)
 
    local blastPower = { power = config.getParameter("damageAmount",0), knockback = config.getParameter("knockbackAmount",0) }
    world.spawnProjectile("pushbackaugment", mcontroller.position(), entity.id(), {0, 0}, true, blastPower) 
    status.addEphemeralEffect("electricaura", 2)
end

function uninit()
  
end

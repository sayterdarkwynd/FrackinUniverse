function init()
	self.value = config.getParameter("refresh",0)
	script.setUpdateDelta(self.value)
	self.blastPower={ power = config.getParameter("damageAmount",0), knockback = config.getParameter("knockbackAmount",0) }
end

function update(dt)
	world.spawnProjectile("pushbackaugment", mcontroller.position(), entity.id(), {0, 0}, true, self.blastPower)
	status.addEphemeralEffect("electricaura", 2)
end

function uninit()

end

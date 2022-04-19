function init()
	fTickRate = config.getParameter("tickRate", 60)
	fTickAmount = config.getParameter("tickAmount", 1)
	self.valBonus = config.getParameter("valBonus", 1)
	self.baseVal = config.getParameter("baseVal", 1)
	self.timer = config.getParameter("timer", 1)
	--species = world.entitySpecies(entity.id())
	self.randVal = self.baseVal * self.valBonus + math.random(1,4)
	script.setUpdateDelta(fTickRate)
end

function update(dt)
	if self.timer <= 0 then
		if world.entityType(entity.id()) == "player" then
			world.spawnItem("fumadnessresource",entity.position(),self.randVal)
		end
		self.timer = 2
	else
		self.timer = self.timer - dt
	end
end

function uninit()

end

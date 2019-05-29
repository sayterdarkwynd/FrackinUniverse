function init()
  self.baseValue = config.getParameter("baseValue")
  self.valBonus = config.getParameter("valBonus") - ((config.getParameter("mentalProtection") or 0) * 10)
  self.timer = 10
  script.setUpdateDelta(3)
end

function update(dt)
  self.timer = self.timer - dt
	if (self.timer <= 0) then
		self.timer = 10
		self.totalValue = self.baseValue + self.valBonus
		world.spawnItem("fumadnessresource",entity.position(),self.totalValue)
  	end
end

function uninit()

end
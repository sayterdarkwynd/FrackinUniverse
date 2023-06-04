function init()
	self.fireRateBonus = config.getParameter("fireRateBonus",1)
		effect.addStatModifierGroup({
		  {stat = "fireRateBonus", amount = self.fireRateBonus}
		})
end

function update(dt)

end

function uninit()
end

function init()
	bonusHandler=effect.addStatModifierGroup({{stat = "fireResistance", amount = 0.15},{stat = "wetImmunity", amount = 1},{stat = "maxBreath", amount = 1000}})
	--self.movementParameters = config.getParameter("movementParameters", {})--by itself this does nothing. you're supposed to add code for it in the update block.
end

--[[function update(dt)

end]]

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end

function init()
	self.baseValue=config.getParameter("armorboost") or 0
	self.lastTechMod=status.stat("defensetechBonus")
	--status.addPersistentEffect("fuarmorboosttech", {stat = "protection", amount = self.baseValue})
	status.addPersistentEffect("fuarmorboosttech", {stat = "protection", amount = self.baseValue * (1+self.lastTechMod)})
end

function update(dt)
	if self.lastTechMod ~= status.stat("defensetechBonus") then
		self.lastTechMod=status.stat("defensetechBonus")
		status.setPersistentEffects("fuarmorboosttech", {{stat = "protection", amount = (self.baseValue or 0)*(1+self.lastTechMod)}})
	end
end

function uninit()
	status.clearPersistentEffects("fuarmorboosttech")
end
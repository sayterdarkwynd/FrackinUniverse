function setBonusInit(setBonusName, setBonusStats)
	self.statGroup = nil
	self.armourPresent = nil
	self.setBonusName = setBonusName
	self.setBonusCheck = { setBonusName .. '_head', setBonusName .. '_chest', setBonusName .. '_legs' }
	self.setBonusStats = setBonusStats

sb.logInfo("init for %s\nchecking for %s", setBonusName, self.setBonusCheck)
end

function update()
	--sb.logInfo("head:%s, chest:%s, legs:%s", status.stat(self.setBonusCheck[1]), status.stat(self.setBonusCheck[2]), status.stat(self.setBonusCheck[3]))

	local newstate = status.stat(self.setBonusCheck[1]) == 1 and status.stat(self.setBonusCheck[2]) == 1 and status.stat(self.setBonusCheck[3]) == 1

	if self.armourPresent == newstate then return end
	self.armourPresent = newstate

	if self.armourPresent then
		if self.statGroup then effect.removeStatModifierGroup(self.statGroup) end -- shouldn't happen

		self.statGroup = effect.addStatModifierGroup(self.setBonusStats)
		 
		--effect.setParentDirectives("fade="..config.getParameter("color").."=0.5")

		sb.logInfo("Set bonus active: %s", self.setBonusName)
	else
		removeSetBonus()
	end
end

function removeSetBonus()
	if self.statGroup then
		effect.removeStatModifierGroup(self.statGroup)
		self.statGroup = nil

		--effect.setParentDirectives(nil)

		sb.logInfo("Set bonus removed: %s", self.setBonusName)
	end
end

function uninit()
	removeSetBonus()
end

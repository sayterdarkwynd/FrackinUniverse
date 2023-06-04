function init()
	if not world.entitySpecies(entity.id()) then return end

	self.species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())

	if self.species == "avian" then
		self.foodCost = 0.1
	elseif self.species == "avali" then
		if status.stat("gliding") == 1 then
			self.foodCost = 1.06
		else
			self.foodCost = 0.26
		end
	elseif self.species == "saturn" then
		if status.stat("gliding") == 1 then
			self.foodCost = 0.26
		else
			self.foodCost = 3.26
		end
	else
		if status.stat("gliding") == 1 then
			self.foodCost = 0.26
		else
			self.foodCost = 4.06
		end
	end
	bonusHandler=effect.addStatModifierGroup({ {stat = "foodDelta", amount = -self.foodCost } })
	status.removeEphemeralEffect("wellfed")
	self.didInit=true
end

function update(dt)
	if not self.didInit then init() end
	if not self.didInit then return end
	status.removeEphemeralEffect("wellfed")
end

function uninit()
	if bonusHandler then
		effect.removeStatModifierGroup(bonusHandler)
	end
end
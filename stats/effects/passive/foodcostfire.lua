function init()
	if not world.entitySpecies(entity.id()) then return end

	self.species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())

	if self.species == "kazdra" then
		self.foodCost = 4
	else
		self.foodCost = 6
	end

	bonusHandler=effect.addStatModifierGroup({
		{stat = "foodDelta", amount = -self.foodCost }
	})
	self.didInit=true
end

function update(dt)
	if not self.didInit then init() end
end

function uninit()
	if bonusHandler then
		effect.removeStatModifierGroup(bonusHandler)
	end
end
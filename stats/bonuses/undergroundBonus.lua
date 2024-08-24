require "/stats/effects/fu_statusUtil.lua"
require("/scripts/util.lua")

function init()
	self.species = world.entitySpecies(entity.id())
	if not self.species then return end

	self.raceConfig = root.assetJson("/species/greckan.raceeffect")

	underground = undergroundCheck()

	script.setUpdateDelta(10)
end

function update(dt)
	if not self.raceConfig then init() end

	underground = undergroundCheck()
	if underground then
		status.setPersistentEffects("undergroundBonus", self.raceConfig.undergroundBonus.stats)
		applyFilteredModifiers(self.raceConfig.undergroundBonus.stats)
	else
		status.clearPersistentEffects("undergroundBonus")
	end
end

function uninit()
	filterModifiers({},true)
	status.clearPersistentEffects("undergroundBonus")
end

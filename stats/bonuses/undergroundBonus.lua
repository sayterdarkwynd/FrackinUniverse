require("/scripts/util.lua")

function init()
    self.species = world.entitySpecies(entity.id())
    if not self.species then return end

    self.raceConfig = root.assetJson("/species/greckan.raceeffect")

    underground = undergroundCheck()

    script.setUpdateDelta(10)
end

function undergroundCheck()
    if not self.raceConfig.undergroundBonus then return false end
	return world.underground(mcontroller.position())
end

function update(dt)
    if not self.raceConfig then init() end

    underground = undergroundCheck()
    if underground then
        status.setPersistentEffects("undergroundBonus", self.raceConfig.undergroundBonus.stats)
        mcontroller.controlModifiers(filterModifiers(copy(self.raceConfig.undergroundBonus.stats)))
    else
        status.clearPersistentEffects("undergroundBonus")
    end
end

function uninit()
    status.clearPersistentEffects("undergroundBonus")
end

function filterModifiers(stuff)
	if (status.statPositive("spikeSphereActive") and 1.0) and stuff["speedModifier"] then stuff["speedModifier"]=1.0 end
	return stuff
end

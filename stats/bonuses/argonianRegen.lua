--didit = false

function init()
    --[[self.species = world.entitySpecies(entity.id())
    if not self.species then return else didit = true end

    self.raceJson = root.assetJson("/species/argonian.raceeffect")
    self.specialConfig = self.raceJson.specialConfig
]]
    script.setUpdateDelta(10)
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
    --if not didit then init() end

		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*0.0023810714*math.max(0,1+status.stat("healingBonus"))}})
    --self.healingRate = 1.00005 / 420 -- health per time - 0.005% health per 420ms, I think --420 seconds to reach 100.005%, or 419.97900104 seconds to restore 100% -khe
    --status.modifyResourcePercentage("health", self.healingRate * dt)
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
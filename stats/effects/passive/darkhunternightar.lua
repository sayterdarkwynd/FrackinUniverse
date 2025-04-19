require "/scripts/util.lua"
require "/stats/effects/fu_statusUtil.lua"
require "/items/active/tagCaching.lua"

function init()
	script.setUpdateDelta(10)
	if not world.entitySpecies(entity.id()) then return end
	self.frEnabled=status.statusProperty("fr_enabled")
	nightarDarkHunterEffects = effect.addStatModifierGroup({})
	nightarDarkHunterEffects2 = effect.addStatModifierGroup({})
	if not self.frEnabled then
		effect.expire()
		return
	end
	self.species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())
	self.activateDrainTimer = 0
	self.didInit=true
end

function update(dt)
	if not self.didInit then init() end
	if not self.didInit then return end
	tagCaching.update()

	local daytime = daytimeCheck()
	local underground = undergroundCheck()
	local lightLevel = getLight()

	if (self.species == "nightar") and (
		(status.resourcePercentage("health") >= 1.0) and (
				--used for checking sword setups
				tagCaching.mergedCache["broadsword"]
				or tagCaching.mergedCache["dagger"]
				or tagCaching.mergedCache["knife"]
				or tagCaching.mergedCache["shortsword"]
				or tagCaching.mergedCache["longsword"]
				or tagCaching.mergedCache["rapier"]
				or tagCaching.mergedCache["katana"]
			)
		)
	then
		effect.setStatModifierGroup(nightarDarkHunterEffects2, {
			{stat = "powerMultiplier", effectiveMultiplier = 1.01}
		})
	else
		effect.setStatModifierGroup(nightarDarkHunterEffects2, {
			{stat = "powerMultiplier", effectiveMultiplier = 1}
		})
	end

	if (lightLevel <= 50) then
	    local mult = 1-math.min(math.max((lightLevel-25)/20,0),1)
	    effect.setStatModifierGroup(nightarDarkHunterEffects, {
			{stat = "powerMultiplier", effectiveMultiplier = 1+mult*0.25},
			{stat = "physicalResistance", amount = mult*0.25}
	    })
	elseif daytime and not underground and lightLevel > 50 then
		local weaknessCheck=status.statPositive("fuReduceRacialDarkWeakness")
	    local mult = math.min(math.max((lightLevel-55)/30,0),1)
	    local healthPenalty = 1-mult*0.25
	    if (self.species == "nightar") then
		    if weaknessCheck then
		        healthPenalty = 1-mult*0.1
			    effect.setStatModifierGroup(nightarDarkHunterEffects, {
					{stat = "physicalResistance", amount = mult*-0.1},
					{stat = "powerMultiplier", effectiveMultiplier = 1-mult*0.2},
					{stat = "maxHealth", effectiveMultiplier = util.round((healthPenalty),1)},
					{stat = "maxEnergy", effectiveMultiplier = util.round((healthPenalty),1)}
			    })
		    else
			    effect.setStatModifierGroup(nightarDarkHunterEffects, {
					{stat = "physicalResistance", amount = mult*-0.33},
					{stat = "powerMultiplier", effectiveMultiplier = 1-mult*0.5},
					{stat = "maxHealth", effectiveMultiplier = util.round(healthPenalty,1)},
					{stat = "maxEnergy", effectiveMultiplier = util.round(healthPenalty,1)}
			    })
		    end
	    else --tenebrhae have different bonuses than nightar
			if weaknessCheck then
				effect.setStatModifierGroup(nightarDarkHunterEffects, {
					{stat = "physicalResistance", amount = mult*-0.01},
					{stat = "powerMultiplier", effectiveMultiplier = 1-mult*0.01}
				})
			else
				effect.setStatModifierGroup(nightarDarkHunterEffects, {
					{stat = "physicalResistance", amount = mult*-0.25},
					{stat = "powerMultiplier", effectiveMultiplier = 1-mult*0.4}
				})
			end
	    end

	else
	    effect.setStatModifierGroup(nightarDarkHunterEffects,{})
	end

end


function uninit()
	if nightarDarkHunterEffects then
		effect.removeStatModifierGroup(nightarDarkHunterEffects)
	end
	if nightarDarkHunterEffects2 then
		effect.removeStatModifierGroup(nightarDarkHunterEffects2)
	end
	if nightarDarkHunterEffects3 then
		effect.removeStatModifierGroup(nightarDarkHunterEffects3)
	end
end

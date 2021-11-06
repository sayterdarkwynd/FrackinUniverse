require "/scripts/util.lua"

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

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = math.min(world.lightLevel(position),1.0)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position())
end


function update(dt)
	if not self.didInit then init() end
	if not self.didInit then return end
	local daytime = daytimeCheck()
	local underground = undergroundCheck()
	local lightLevel = getLight()

	if (self.species == "nightar") then
		if status.resource("health") == status.stat("maxHealth") then
			--used for checking sword setups
		    local primaryItem = world.entityHandItem(entity.id(), "primary")
		    local altItem = world.entityHandItem(entity.id(), "alt")

			if (primaryItem and root.itemHasTag(primaryItem, "broadsword")) or (altItem and root.itemHasTag(altItem,  "broadsword")) or
		   (primaryItem and root.itemHasTag(primaryItem, "dagger")) or (altItem and root.itemHasTag(altItem,  "dagger")) or
		   (primaryItem and root.itemHasTag(primaryItem, "shortsword")) or (altItem and root.itemHasTag(altItem,  "shortsword")) or
		   (primaryItem and root.itemHasTag(primaryItem, "longsword")) or (altItem and root.itemHasTag(altItem,  "longsword")) or
		   (primaryItem and root.itemHasTag(primaryItem, "rapier")) or (altItem and root.itemHasTag(altItem,  "rapier")) or
		   (primaryItem and root.itemHasTag(primaryItem, "katana")) or (altItem and root.itemHasTag(altItem,  "katana")) then
				effect.setStatModifierGroup(nightarDarkHunterEffects2, {
					{stat = "powerMultiplier", baseMultiplier = 1.1}
				})
			end
		end
	end

	if (lightLevel <= 50) then
	    local mult = 1-math.min(math.max((lightLevel-25)/20,0),1)
	    effect.setStatModifierGroup(nightarDarkHunterEffects, {
			{stat = "powerMultiplier", effectiveMultiplier = 1+mult*0.25},
			{stat = "physicalResistance", amount = mult*0.25}
	    })
	elseif daytime and not underground and lightLevel > 50 then
	    local mult = math.min(math.max((lightLevel-55)/30,0),1)
	    local healthPenalty = 1-mult*0.25
	    if (self.species == "nightar") then
		    if status.stat("reducePenalty") >= 0 then
		        reducePenalty = status.stat("reducePenalty")
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
	    else  --tenebrhae have different bonuses than nightar
		    effect.setStatModifierGroup(nightarDarkHunterEffects, {
				{stat = "physicalResistance", amount = mult*-0.25},
				{stat = "powerMultiplier", effectiveMultiplier = 1-mult*0.4}
		    })
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
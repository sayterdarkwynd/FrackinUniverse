require "/scripts/status.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

local catInit = init
local catUpdate = update

local valueList={
	swimmingLeft={-0.675,-0.7},
	swimmingRight={0.675,-0.7},
	walkingLeft={-0.6,-1.3},
	walkingRight={0.6,-1.3}
}

function init()
	if catInit then
		catInit()
	end
	delayedInit=0
end

function update(dt)
	catMouthOffset(getSpecies())
	if catUpdate then
		catUpdate(dt)
	end
end

function getSpecies()
	if not self.species then self.species=world.entitySpecies(entity.id()) end
	return self.species
end

function catMouthOffset(species)
	if delayedInit and delayedInit < 3 then
		if species == "cat" then
			status.setStatusProperty("mouthPosition", valueList["walkingLeft"])
			status.setPersistentEffects("CatPersistantEffects",{{stat = "fallDamageMultiplier", effectiveMultiplier = 0.70}})
			delayedInit=nil
		elseif not species then
			delayedInit=delayedInit+1
		else
			delayedInit=nil
		end
	end
	
	if species == "cat" then
		local mouthPos=status.statusProperty("mouthPosition") or {0,0}
		
		if checkMouthPos(mouthPos) then
			local swimming=mcontroller.liquidMovement()
			local facing=mcontroller.facingDirection()
			local catMouthPos=valueList["walkingLeft"]
			if swimming then
				if facing<0 then
					catMouthPos=valueList["swimmingLeft"]
					mouthPos=catMouthPos
				else
					catMouthPos=valueList["swimmingRight"]
					mouthPos=catMouthPos
				end
			else
				if facing<0 then
					catMouthPos=valueList["walkingLeft"]
					mouthPos=catMouthPos
				else
					catMouthPos=valueList["walkingRight"]
					mouthPos=catMouthPos
				end
			end
			status.setStatusProperty("mouthPosition",catMouthPos)
		end
	end
	
end


function checkMouthPos(mouthPos)
	for entry,offset in pairs(valueList) do
		if vec2.eq(mouthPos,offset) then
			return true
		end
	end
	return false
end
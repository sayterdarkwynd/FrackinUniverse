require "/scripts/status.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

local catInit = init
local catUpdate = update

local valueList={
	swimmingLeft={-0.675,-0.7},
	swimmingRight={0.675,-0.7},
	walkingLeft={-0.6,-1.3},
	walkingRight={0.6,-1.3},
	lounging={0,0.75}
}

function init()
	if catInit then
		catInit()
	end
	delayedInit=0
	eType=world.entityType(entity.id())
end

function update(dt)
	catMouthOffset(dt,getSpecies())
	if catUpdate then
		catUpdate(dt)
	end
end

function getSpecies()
	if not self.species then self.species=world.entitySpecies(entity.id()) end
	return self.species
end

function catMouthOffset(dt,species)
	if eType=="player" then
		if loungeQuery then
			if loungeQuery:finished() then
				if loungeQuery:succeeded() then
					lounging=loungeQuery:result()
				end
				loungeQuery=nil
			end
		else
			if loungeQueryTimer and loungeQueryTimer >= 1.0 then
				loungeQueryTimer=0.0
				loungeQuery=world.sendEntityMessage(entity.id(),"player.isLounging")
			else
				loungeQueryTimer=(loungeQueryTimer or 0)+dt
			end
		end
	end
	if delayedInit and delayedInit < 3 then
		if species == "cat" then
			if not eType then eType=world.entityType(entity.id()) end
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
			local catMouthPos
			if lounging then
				catMouthPos=valueList["lounging"]
			elseif swimming then
				if facing<0 then
					catMouthPos=valueList["swimmingLeft"]
				else
					catMouthPos=valueList["swimmingRight"]
				end
			else
				if facing<0 then
					catMouthPos=valueList["walkingLeft"]
				else
					catMouthPos=valueList["walkingRight"]
				end
			end
			status.setStatusProperty("mouthPosition",catMouthPos)
		end
	end

end


function checkMouthPos(mouthPos)
	for _,offset in pairs(valueList) do
		if vec2.eq(mouthPos,offset) then
			return true
		end
	end
	return false
end

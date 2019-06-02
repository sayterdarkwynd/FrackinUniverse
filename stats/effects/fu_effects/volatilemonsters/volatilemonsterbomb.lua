require "/scripts/poly.lua"
require "/scripts/rect.lua"

function init()
	if status.isResource("timeToLive") then
		script.setUpdateDelta(1)
	else
		script.setUpdateDelta(0.0)
	end
	self.health=status.resourceMax("health") or self.health
end

function update(dt)
	--[[
	if mcontroller then
		local poly=mcontroller.collisionPoly()
		local bound=poly.boundBox(poly)
		local center=poly.center(poly)
		local size=rect.size(bound)
		size=vec2.mag(size)
		
		sb.logInfo("%s",boundBox)
		if world.entityQuery(center,size,{withoutEntityId=entity.id(),includedTypes={"creature"}}) then
			sb.logInfo("colliding!")
		end
	end]]

	effect.modifyDuration(dt)
	if not dying then
		if not status.resourcePositive("timeToLive") then
			die()
			boom()
		elseif not status.resourcePositive("health") then
			dying=true
			boom()
		end
	end
end

function die()
	dying=true
	status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = math.huge
		}
	)
end

function boom()
	sb.logInfo("inksplat!")
	
end
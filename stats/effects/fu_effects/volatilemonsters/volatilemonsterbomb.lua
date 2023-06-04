require "/scripts/poly.lua"
require "/scripts/rect.lua"



function init()
	if status.isResource("timeToLive") then
		script.setUpdateDelta(10)
	else
		script.setUpdateDelta(0.0)
		return
	end

	collisionPoly=mcontroller.collisionPoly()
	bounds=poly.boundBox(collisionPoly)
	center=poly.center(collisionPoly)
	size=rect.size(bounds)
	size=vec2.mag(size)

	self.health=status.resourceMax("health") or self.health
end

function update(dt)
	if not status.isResource("timeToLive") then return end

	if not dying then
		local queryList=world.entityQuery(vec2.add(center,entity.position()),size,{withoutEntityId=entity.id(),includedTypes={"creature"}})
		if #queryList > 0 then
			for _,id in ipairs(queryList) do
				if entity.isValidTarget(id) then
					die()
				end
			end
		end
	end

	effect.modifyDuration(dt)
	if not dying then
		if not status.resourcePositive("timeToLive") then
			die()
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
	boom()
end

function boom()
	sb.logInfo("inksplat!")

end
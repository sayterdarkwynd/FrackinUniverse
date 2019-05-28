function init()
	if entity.type()=="monster" then
		script.setUpdateRate(0.1)
	else
		script.setUpdateRate(0.0)
	end
end

function update(dt)
	effect.modifyDuration(dt)
	if not status.resourcePositive("timer") then
		--die()
	end
	if not status.resourcePositive("health") then
		boom()
	end
end

function die()
	status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = status.resource("health"),
			sourceEntityId = entity.id()
		}
	)
end

function boom()
	sb.logInfo("inksplat!")

end
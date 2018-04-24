require "/scripts/mementomori.lua"

if not _mm_wrapped then
	_applyDamageRequest = applyDamageRequest
	_init = init
	_update = update
	_teleportOut = teleportOut
	_mm_wrapped = true
end

function applyDamageRequest(damageRequest)
    local r = _applyDamageRequest(damageRequest)
    if next(r) ~= nil and r[1].hitType == "kill" then
		status.setStatusProperty("fuEnhancerActive", false)
		status.setStatusProperty(mementomori.deathPositionKey,{position=mcontroller.position(),worldId=worldId})
    end
    return r
end

function init()
	mm_timer=5.0
	_init()
end

function update(dt)
	if not mm_timer then
		mm_timer=0.0
	elseif mm_timer > 5.0 then
		promise=world.sendEntityMessage(entity.id(),"player.worldId")
		mm_timer=0.0
	else
		mm_timer=mm_timer+dt
	end
	if promise then
		if promise:finished() then
			if promise:succeeded() then
				worldId=promise:result()
			end
		end
	end
	_update(dt)
end

function teleportOut(...)
	mm_timer=0.0
	_teleportOut(...)
end
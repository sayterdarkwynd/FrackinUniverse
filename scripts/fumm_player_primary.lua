require "/scripts/fumementomori.lua"

local fummApplyDamageRequest = applyDamageRequest
local fummInit = init
local fummUpdate = update
local fummTeleportOut = teleportOut
local promise
local promise2
local mm_timer=5.0

function applyDamageRequest(damageRequest)
    local r = fummApplyDamageRequest(damageRequest)
    if (not playerIsAdmin) and next(r) ~= nil and r[1].hitType == "kill" and worldId then
		status.setStatusProperty("fuEnhancerActive", false)
		status.setStatusProperty(mementomori.deathPositionKey.."."..worldId,{position=mcontroller.position()})
		--sb.logInfo("mm_player-primary.lua:applyDamageRequest:recording death: %s",{data={dkey=mementomori.deathPositionKey.."."..worldId,position=mcontroller.position()}})
    end
    return r
end

function init(...)
	if fummInit then fummInit(...) end
end

function update(dt,...)
	if not mm_timer then
		mm_timer=0.0
	elseif mm_timer > 5.0 then
		promise=world.sendEntityMessage(entity.id(),"player.worldId")
		promise2=world.sendEntityMessage(entity.id(),"player.isAdmin")
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
	if promise2 then
		if promise2:finished() then
			if promise2:succeeded() then
				playerIsAdmin=promise2:result()
			end
		end
	end
	if fummUpdate then fummUpdate(dt,...) end
end

function teleportOut(...)
	mm_timer=0.0
	if fummTeleportOut then fummTeleportOut(...) end
end

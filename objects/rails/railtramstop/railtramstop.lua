require "/scripts/util.lua"
require "/scripts/vec2.lua"

local tramRecursionLimit=100

function init()
	message.setHandler("railRiderPresent", function()
			stopWaiting()
		end)

	storage.waiting = storage.waiting or false
	storage.active = storage.active or false

	self.resumeSpeed = config.getParameter("resumeSpeed")

	updateActive()
end

function nodePosition()
	return util.tileCenter(entity.position())
end

function updateActive()
	object.setMaterialSpaces({{{0, 0}, (storage.active and not storage.waiting) and "metamaterial:railsafe" or "metamaterial:railstop"}})
	if storage.waiting then
		animator.setAnimationState("stopState", "wait")
	elseif storage.active then
		animator.setAnimationState("stopState", "on")
	else
		animator.setAnimationState("stopState", "off")
	end
end

function onInputNodeChange()
	if object.getInputNodeLevel(0) then
		if storage.waiting then
			stopWaiting()
		else
			startWaiting()
		end
	end
	updateActive()
end

function die()
	propagateCancel()
	notifyStoppedEntities()
end

function tramInStation()
	local ppos = nodePosition()
	local inStation = world.entityQuery({ppos[1] - 2.5, ppos[2] - 2.5}, {ppos[1] + 2.5, ppos[2] + 2.5},
			{ includedTypes = { "mobile" }, boundMode = "metaboundbox",
				callScript = "isRailTramAt", callScriptArgs = {nodePosition()} })

	return #inStation > 0
end

function sendRidersTo(targetPosition)
	local tarVec = world.distance(targetPosition, nodePosition())
	local toDir = railDirectionFromVector(tarVec)
	-- sb.logInfo("%s sending riders from %s to %s (vec %s dir %s)", entity.id(), nodePosition(), targetPosition, tarVec, toDir)
	notifyStoppedEntities(toDir)
end

function notifyStoppedEntities(toDir)
	local ppos = nodePosition()
	local inStation = world.entityQuery({ppos[1] - 2.5, ppos[2] - 2.5}, {ppos[1] + 2.5, ppos[2] + 2.5}, { includedTypes = { "mobile" }, boundMode = "metaboundbox" })
	for _, id in pairs(inStation) do
		-- sb.logInfo("telling %s to resume", id)
		world.sendEntityMessage(id, "railResume", ppos, self.resumeSpeed, toDir)
	end
end

function startWaiting()
	if not storage.waiting and not tramInStation() then
		if storage.active then
			callConnected("propagateCancel")
		end
		-- sb.logInfo("%s started waiting", entity.id())
		storage.waiting = true
		storage.active = false
		updateActive()
		callConnected("propagateActivate", {nodePosition(),0})
	end
end

function stopWaiting()
	if storage.waiting then
		-- sb.logInfo("%s stopped waiting", entity.id())
		storage.active = false
		storage.waiting = false
		updateActive()
		callConnected("propagateCancel")
	end
end

function propagateActivate(args)--summonPosition)
	if not args then return end
	if not args[2] then args[2]=0 end
	if (args[2]<=tramRecursionLimit) and (not storage.active and not vec2.eq(args[1], nodePosition())) then
		storage.active = true
		storage.waiting = false
		updateActive()
		sendRidersTo(args[1])--summonPosition)
		args[2]=args[2]+1
		callConnected("propagateActivate",args)
	end
end

function propagateCancel(args)
	if not args then args={} end
	if not args[1] then args[1]=0 end
	if (args[1]<=tramRecursionLimit) and (storage.active or storage.waiting) then
		storage.active = false
		storage.waiting = false
		updateActive()
		args[1]=args[1]+1
		callConnected("propagateCancel",args)
	end
end

function callConnected(callFunction, callData)
	for entityId, _ in pairs(object.getInputNodeIds(1)) do
		world.callScriptedEntity(entityId, callFunction, callData)
	end
	for entityId, _ in pairs(object.getOutputNodeIds(0)) do
		world.callScriptedEntity(entityId, callFunction, callData)
	end
end

function railDirectionFromVector(vec)
	local angle = math.atan(vec[2], vec[1])
	local dir = math.floor(((4 * angle) / math.pi) + 0.5) % 8 + 1

	-- shift to diagonals
	if dir == 5 then
		dir = vec[2] > 0 and 4 or 6
	elseif dir == 1 then
		dir = vec[2] > 0 and 2 or 8
	elseif dir == 7 then
		dir = vec[1] > 0 and 8 or 6
	elseif dir == 3 then
		dir = vec[1] > 0 and 2 or 4
	end

	return dir
end

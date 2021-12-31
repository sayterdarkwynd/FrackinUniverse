require "/scripts/vec2.lua"

-- how many iterations should a for loop go through before the coroutine yields?
YIELDPOINT = 100000

-- what range of dungeonIds are we reserving for shield generators?
LOWID = 30877
HIGHID = 45877

function init(args)
	object.setInteractive(false)

	storage.applyProtected = config.getParameter("pilch_shieldgenerator_protected")
	storage.applyBreathable = config.getParameter("pilch_shieldgenerator_breathable")
	local gravityConfig = config.getParameter("pilch_shieldgenerator_gravity")
	storage.applyGravity = gravityConfig.applyGravity
	storage.gravityLevel = gravityConfig.gravityLevel

	if (storage.override) then
		storage.override = nil
	end
	if (storage.hideMode) then
		setHideMode(nil, nil, storage.hideMode)
	else
		storage.hideMode = -1
	end
	if (storage.spaces == nil) then
		storage.spaces = {}
		local pos = entity.position()
		for _, offset in ipairs(object.spaces()) do
			local backMaterial = world.material(vec2.add(pos, offset), "background")
			table.insert(storage.spaces, {offset, backMaterial})
		end
	end

	if (storage.defaultGravity == nil) then
		storage.defaultGravity = world.gravity(entity.position())
	end
	if (storage.targetRect == nil) then
		storage.leftEdge = -2
		storage.rightEdge =  2
		storage.bottomEdge = 0
		storage.topEdge = 4
		updateTargetRect()
	end
	if (storage.dungeonId == nil) then
		storage.dungeonId = claimDungeonId()
	end
	if (storage.applyProtected == nil) then
		setProtected(nil, nil, true)
	end
	if (storage.applyBreathable == nil) then
		setBreathable(nil, nil, true)
	end
	if (storage.applyGravity == nil) then
		setGravity(nil, nil, false, storage.defaultGravity)
	end
	if (storage.fieldActive == nil) then
		setActive(false)
	end

	setWired()
	incDirty()

	-- messaging
	message.setHandler("pilch_markerPositionUpdate", markerPositionUpdate)
	message.setHandler("activate", activate)
	message.setHandler("deactivate", deactivate)
	message.setHandler("setBreathable", setBreathable)
	message.setHandler("setProtected", setProtected)
	message.setHandler("setGravity", setGravity)
	message.setHandler("hide", setHideMode)
	message.setHandler("setDebugMode", setDebugMode)

	-- set up coroutine for area checking
	self.cor = coroutine.create(function() end)
	assert(coroutine.resume(self.cor))
end

-- when this object is broken, make sure we clean up after ourselves
function die()
	removeField()
	releaseDungeonId()
end

function setDebugMode(msgName, isLocal, debugMode)
	storage.debugMode=debugMode
	object.setConfigParameter("pilch_shieldgenerator_debug", storage.debugMode)
end

-- set hide mode (-1 = not hidden, 0 = look like blocks, 1 = invisible)
function setHideMode(msgName, isLocal, hideMode)
	storage.hideMode = hideMode
	if (storage.hideMode == 0) then
		object.setMaterialSpaces(storage.spaces)
	elseif (storage.hideMode == 1) then
		animator.setAnimationState("DisplayState", "invisible")
		object.setMaterialSpaces()
	else
		animator.setAnimationState("DisplayState", "active")
		object.setMaterialSpaces()
	end
	object.setConfigParameter("pilch_shieldgenerator_hidden", storage.hideMode)
end

-- ping connected objects to get marker positions
function requestMarkerPositions()
	storage.leftEdge = -2
	storage.rightEdge =  2
	storage.bottomEdge = 0
	storage.topEdge = 4
	updateTargetRect()
	for nodeID, _ in pairs(object.getOutputNodeIds(0)) do
		world.sendEntityMessage(nodeID, "pilch_requestMarkerPositions")
	end
end

-- handler for incoming marker ping responses
function markerPositionUpdate(msgName, isLocal, xPos, yPos)
	local pos = entity.position()
	local distance = world.distance({xPos, yPos}, pos)
	if (distance[1] < storage.leftEdge) then
		storage.leftEdge = distance[1]
	end
	if (distance[1] + 1 > storage.rightEdge) then
		storage.rightEdge = distance[1] + 1
	end
	if (distance[2] < storage.bottomEdge) then
		storage.bottomEdge = distance[2]
	end
	if (distance[2] + 1 > storage.topEdge) then
		storage.topEdge = distance[2] + 1
	end
	updateTargetRect()
end

-- convert our edge positions into a rect for ease of use
function updateTargetRect()
	local pos = entity.position()
	storage.targetRect = { pos[1] + storage.leftEdge, pos[2] + storage.bottomEdge, pos[1] + storage.rightEdge, pos[2] + storage.topEdge }
	if (storage.fieldActive) then
		removeField()
		startCheckAndApply()
	end
end

-- return the world property record
function propertyRecord()
	if (storage.dungeonId ~= -1) then
		local record = { position = entity.position() }
		if (storage.fieldActive) then
			record.rect = storage.fieldActive
		end
		return record
	end
	return nil
end

-- find and claim an unused dungeonId within our 15k range
function claimDungeonId()
	local firstId, lastId = LOWID, HIGHID
	local record = propertyRecord()
	for i = firstId, lastId do
		if (world.getProperty(tostring(i)) == nil) then
			world.setProperty(tostring(i), record)
			local stored = world.getProperty(tostring(i))
			if (stored) then
				if (stored.position[1] == record.position[1]) and (stored.position[2] == record.position[2]) then
					return i
				end
			end
		end
	end

	local pos = entity.position()
	local value = tostring(pos[1]) .. ", " .. tostring(pos[2])
	if storage.debugMode then
		sb.logWarn("Pilchenstein's Field Generator at " .. value .. " failed to find suitable dungeonId")
	end
	setStatus("Error: No Suitable DungeonID", "red")
	return -1
end

-- release our claimed dungeonId
function releaseDungeonId()
	if (storage.dungeonId ~= -1) then
		world.setProperty(tostring(storage.dungeonId), nil)
	end
end

-- remove the field effects and reset the area's dungeonId
function removeField()
	if (storage.fieldActive) then
		if (world.loadRegion(storage.fieldActive) == false) then
			if storage.debugMode then
				sb.logWarn("Pilchenstein's Field Generator failed to load field region before deactivation: " .. tostring(storage.fieldActive[1]) .. ", " .. tostring(storage.fieldActive[2]) .. " -> " .. tostring(storage.fieldActive[3]) .. ", " .. tostring(storage.fieldActive[4]))
			end
			setStatus("Error: Failed to load field region", "red")
			incDirty()
		else
			world.setDungeonId(storage.fieldActive, 65531)
			if (storage.dungeonId ~= -1) then
				world.setDungeonGravity(storage.dungeonId)
				world.setDungeonBreathable(storage.dungeonId)
				world.setTileProtection(storage.dungeonId, false)
			end
			storage.fieldActive = nil
			world.setProperty(tostring(storage.dungeonId), propertyRecord())
			setActive(false)
		end
	end
end

-- apply the field effects and set the area's dungeonId
function applyField()
	if (world.loadRegion(storage.targetRect) == false) then
		if storage.debugMode then
			sb.logWarn("Pilchenstein's Field Generator failed to load field region before activation: " .. tostring(storage.targetRect[1]) .. ", " .. tostring(storage.targetRect[2]) .. " -> " .. tostring(storage.targetRect[3]) .. ", " .. tostring(storage.targetRect[4]))
		end
		setStatus("Error: Failed to load field region", "red")
		incDirty()
	else
		world.setDungeonId(storage.targetRect, storage.dungeonId)
		world.setTileProtection(storage.dungeonId, storage.applyProtected)
		world.setDungeonBreathable(storage.dungeonId, storage.applyBreathable)
		if (storage.applyGravity) then
			world.setDungeonGravity(storage.dungeonId, storage.gravityLevel)
		else
			world.setDungeonGravity(storage.dungeonId, storage.defaultGravity)
		end
		storage.fieldActive = storage.targetRect
		world.setProperty(tostring(storage.dungeonId), propertyRecord())
		setActive(true)
	end
end

-- make sure the target area doesn't include any other generator fields
function checkArea()
	if (storage.dungeonId == -1) then
		setStatus("Error: No Suitable DungeonID", "red")
		incDirty()
		return
	end
	local overlaps, iterations = 0, 0
	local overlapList={}
	for y = storage.targetRect[2], storage.targetRect[4] - 1 do
		for x = storage.targetRect[1], storage.targetRect[3] - 1 do
			local dId = world.dungeonId({x, y})
			if (dId >= LOWID) and (dId <= HIGHID) then
				overlaps = overlaps + 1
				if storage.debugMode then
					table.insert("\n"..overlapList,tostring(dId) .. " @ " .. tostring(x) .. ", " .. tostring(y))
				end
			end
			iterations = iterations + 1
			if (iterations % YIELDPOINT == 0) then coroutine.yield() end
		end
	end
	if (storage.override) then
		storage.override = nil
	elseif (overlaps > 0) then
		local pos = entity.position()
		local value = tostring(pos[1]) .. ", " .. tostring(pos[2])
		if storage.debugMode then
			sb.logWarn("Pilchenstein's Field Generator at " .. value .. " overlapped with " .. tostring(overlaps) .. " tiles containing fields from other generators")
			sb.logWarn("Overlapping Tiles: %s",table.concat(overlapList))
		end
		setStatus("Error: Overlapping Fields", "red")
		incDirty()
		return
	end
	applyField()
end

-- begin the checking/applying process (using coroutines)
function startCheckAndApply(override)
	if (coroutine.status(self.cor) == "dead") then
		storage.override = override
		self.cor = coroutine.create(checkArea)
	end
	setStatus("")
end

-- received an "activate" message from the UI
function activate(msgName, isLocal, override)
	startCheckAndApply(override)
end

-- receieved a "deactivate" message from the UI
function deactivate()
	removeField()
end

-- received a message from the UI to set one of the properties
function setProtected(msgName, isLocal, protected)
	storage.applyProtected = protected
	object.setConfigParameter("pilch_shieldgenerator_protected", protected)
	incDirty()
end

function setBreathable(msgName, isLocal, breathable)
	storage.applyBreathable = breathable
	object.setConfigParameter("pilch_shieldgenerator_breathable", breathable)
	incDirty()
end

function setGravity(msgName, isLocal, gravity, level)
	storage.applyGravity = gravity
	storage.gravityLevel = level
	object.setConfigParameter("pilch_shieldgenerator_gravity", { applyGravity = gravity, gravityLevel = level })
	incDirty()
end

function setActive(isActive)
	object.setConfigParameter("pilch_shieldgenerator_active", isActive)
	if (isActive) then
		setStatus("Field Active", "green")
		object.setAllOutputNodes(true)
	else
		setStatus("Field Inactive", "red")
		object.setAllOutputNodes(false)
	end
	incDirty()
end

function setWired()
	if (object.isInputNodeConnected(0)) then
		object.setConfigParameter("pilch_shieldgenerator_wired", true)
	else
		object.setConfigParameter("pilch_shieldgenerator_wired", false)
	end
	incDirty()
end

function setStatus(message, colour)
	if (colour) then
		message = "^" .. colour .. ";" .. message
	end
	object.setConfigParameter("pilch_shieldgenerator_status", message)
end

function incDirty()
	self.dirtyCounter = self.dirtyCounter or 0
	self.dirtyCounter = self.dirtyCounter + 1
	object.setConfigParameter("pilch_shieldgenerator_dirty", self.dirtyCounter)
end

-- if an area check is in progress, update it
function update(dt)
	if (coroutine.status(self.cor) == "suspended") then
		assert(coroutine.resume(self.cor))
	end
end

-- ping for markers when wires are connected/disconnected
function onNodeConnectionChange(args)
	requestMarkerPositions()
	setWired()
end

-- apply/remove field based on wire input
function onInputNodeChange(args)
	if (args.level) then
		startCheckAndApply()
	else
		removeField()
	end
end

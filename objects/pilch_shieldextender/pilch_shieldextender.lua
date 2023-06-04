require "/scripts/vec2.lua"

function init(args)
	object.setInteractive(true)

	if (storage.hideMode) then
		setHideMode()
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

	-- check wiring state
	onInputNodeChange({ node = 0, level = object.getInputNodeLevel(0) })
	-- messaging
	message.setHandler("pilch_requestMarkerPositions", requestMarkerPositions)
	message.setHandler("pilch_markerPositionUpdate", markerPositionUpdate)
end

-- handler for incoming marker ping responses
function markerPositionUpdate(msgName, isLocal, xPos, yPos)
	for nodeID, _ in pairs(object.getInputNodeIds(0)) do
		world.sendEntityMessage(nodeID, "pilch_markerPositionUpdate", xPos, yPos)
	end
end

-- return position to connected objects and ping connected objects to get marker positions
function requestMarkerPositions()
	local pos = entity.position()

	for nodeID, _ in pairs(object.getInputNodeIds(0)) do
		world.sendEntityMessage(nodeID, "pilch_markerPositionUpdate", pos[1], pos[2])
	end

	for nodeID, _ in pairs(object.getOutputNodeIds(0)) do
		world.sendEntityMessage(nodeID, "pilch_requestMarkerPositions")
	end
end

function onInteraction(args)
	if (object.getInputNodeLevel(0) == false) then
		cycleHideMode()
	end
end

function cycleHideMode()
	storage.hideMode = storage.hideMode + 1
	if (storage.hideMode == 2) then
		storage.hideMode = -1
	end
	setHideMode()
end

-- set hide mode (-1 = not hidden, 0 = look like blocks, 1 = invisible)
function setHideMode()
	if (storage.hideMode == 0) then
		object.setMaterialSpaces(storage.spaces)
	else
		setAnimation()
		object.setMaterialSpaces()
	end
end

function setAnimation()
	if (storage.hideMode == 1) then
		animator.setAnimationState("powerState", "invisible")
	else
		if (object.getInputNodeLevel(0)) then
			animator.setAnimationState("powerState", "on")
		else
			animator.setAnimationState("powerState", "off")
		end
	end
end

function onNodeConnectionChange(args)
	requestMarkerPositions()
end

function onInputNodeChange(args)
	object.setOutputNodeLevel(0, args.level)
	setAnimation()
end

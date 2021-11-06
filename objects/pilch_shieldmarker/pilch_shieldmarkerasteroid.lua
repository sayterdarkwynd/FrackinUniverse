require "/scripts/vec2.lua"

function init(args)
	object.setInteractive(false)
	storage.hideMode=0

	setHideMode()

	-- check wiring state
	onInputNodeChange({ node = 0, level = object.getInputNodeLevel(0) })
	-- messaging
	message.setHandler("pilch_requestMarkerPositions", requestMarkerPositions)
end

-- return position to connected objects
function requestMarkerPositions(msgName, isLocal)
	local pos = entity.position()

	for nodeID, _ in pairs(object.getInputNodeIds(0)) do
		world.sendEntityMessage(nodeID, "pilch_markerPositionUpdate", pos[1], pos[2])
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

	if (storage.spaces == nil) then
		storage.spaces = {}
		local pos = entity.position()
		local offset, backMaterial
		for _, offset in ipairs(object.spaces()) do
			backMaterial = world.material(vec2.add(pos, offset), "background")
			table.insert(storage.spaces, {offset, backMaterial})
		end
	end

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
	setHideMode()
end

function onInputNodeChange(args)
	setAnimation()
end

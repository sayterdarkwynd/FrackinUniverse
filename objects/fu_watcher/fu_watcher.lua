function init()
	object.setInteractive(true)
	storage.state = storage.state or false
	if not storage.watchBox then
		local myLocation = entity.position()
		storage.watchBox = { myLocation[1]-20, myLocation[2]-20, myLocation[1]+20, myLocation[2]+20 }
	end
end

function update(dt)
	if object.isInputNodeConnected(0) then
		object.setInteractive(false)
		storage.state=object.getInputNodeLevel(0)
		if storage.state then
			if not world.regionActive(storage.watchBox) then
				world.loadRegion( storage.watchBox )
			end
		end
	else
		object.setInteractive(true)
	end
	if storage.state then
		world.loadRegion( storage.watchBox )
	end
	moveEyeball()
end

function onNodeConnectionChange()
	if object.isInputNodeConnected(0) then
		object.setInteractive(false)
			storage.state=object.getInputNodeLevel(0)
	else
		object.setInteractive(true)
	end
	moveEyeball()
end

function onInboundNodeChange()
	storage.state=object.getInputNodeLevel(0)
	moveEyeball()
end

function onInteraction(args)
	storage.state = not storage.state
	moveEyeball()
end
function moveEyeball()
	if storage.state then
		animator.setAnimationState("eyeState","opening")
	else
		animator.setAnimationState("eyeState","closing")
	end
end

function uninit()
	storage.state = false
end

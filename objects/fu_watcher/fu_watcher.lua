function init()
	object.setInteractive(true)
	storage.state = false
end

function update(dt)
	local myLocation = entity.position()
	local watchBox = { myLocation[1]-20, myLocation[2]-20, myLocation[1]+20, myLocation[2]+20 }
	-- world.debugPoly( watchBox, "red" ) -- didn't work, rectf is not usable as poly
	if storage.state then
		world.loadRegion( watchBox )
	end
end

function onInteraction(args)
	if not storage.state then
		openEye()
	else
		closeEye()
	end
end

function openEye()
	animator.setAnimationState("eyeState","opening")
	storage.state = true
end

function closeEye()
	animator.setAnimationState("eyeState","closing")
	storage.state = false
end

function uninit()
  
end
--update notes from bk3000 aka bk3k
--
--objects aren't mobile so why recalculate every tic of update?  Just a waste of CPU cycles doing that.
--I did it in init()  It probably only needs to recalculate between session changes
--since only storage.state persists between sessions.  That being the case, 
--my edit of line 10 will keep the setting between sessions (which I'd find more desirable by far).

function init()
	object.setInteractive(true)
	storage.state = storage.state or false
  if not storage.watchBox then
    local myLocation = entity.position()
    storage.watchBox = { myLocation[1]-20, myLocation[2]-20, myLocation[1]+20, myLocation[2]+20 }
  end
end

function update(dt)
	if storage.state then
		world.loadRegion( storage.watchBox )
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

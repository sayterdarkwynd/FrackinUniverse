local oldInit=init

function init()
	if oldInit then oldInit() end
	animator.playSound("trolol")
end

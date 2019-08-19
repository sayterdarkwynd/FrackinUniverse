function init()
  script.setUpdateDelta(3)
  rescuePosition = mcontroller.position()
end

function uninit()
	mcontroller.setPosition(rescuePosition)
end
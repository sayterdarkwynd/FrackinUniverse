function init()
end

function update(dt)
  mcontroller.controlParameters({
     airFriction = 0,
	 normalGroundFriction = 0,
	 ambulatingGroundfriction = 0,
	 frictionEnabled = false
  })
end

function uninit()
end

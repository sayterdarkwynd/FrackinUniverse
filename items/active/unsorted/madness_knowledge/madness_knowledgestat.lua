function init()
	fTickRate = config.getParameter("tickRate", 60)
	script.setUpdateDelta(fTickRate)
end

function update(dt)
  local currentVelocity = mcontroller.velocity()
  mcontroller.controlParameters({gravityEnabled = false})
  mcontroller.setVelocity({0, 0})
end

function uninit()

end

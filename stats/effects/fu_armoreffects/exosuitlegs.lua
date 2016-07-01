function init()
  script.setUpdateDelta(5)
end

function update(dt)
  mcontroller.controlModifiers({
    groundMovementModifier = 1.3,
	runModifier = 1.3,
	jumpModifier = 1.3
  })
end

function uninit()

end

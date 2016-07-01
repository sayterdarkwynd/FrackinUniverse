function init()
  script.setUpdateDelta(5)
end

function update(dt)
  mcontroller.controlModifiers({
    groundMovementModifier = 1.22,
	runModifier = 1.22,
	jumpModifier = 1.15
  })
end

function uninit()

end

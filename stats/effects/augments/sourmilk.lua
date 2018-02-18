function init()
	effect.addStatModifierGroup({
	{stat = "maxHealth", baseMultiplier = 0.95},
	{stat = "powerMultiplier", baseMultiplier = 0.95 }
	})
  script.setUpdateDelta(10)
end

function update(dt)
  mcontroller.controlModifiers({
      speedModifier = 1.05,
      airJumpModifier = 1.08,
      airForce = 60
    })
end

function uninit()
  
end
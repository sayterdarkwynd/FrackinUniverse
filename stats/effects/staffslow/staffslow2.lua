function init()
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.15}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.65,
      speedModifier = 0.75,
      airJumpModifier = 0.85
    })
end

function uninit()

end

function init()
  effect.setParentDirectives("fade=7733AA=0.25")
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.3}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.5,
      speedModifier = 0.5,
      airJumpModifier = 0.7
      //new
      facingSuppressed = true,
      movementSuppressed = true,
      ToolUsageSuppressed = true      
    })
end

function uninit()

end

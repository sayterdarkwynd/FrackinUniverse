function init()
  effect.setParentDirectives("fade=7733AA=0.25")
  effect.addStatModifierGroup({{stat = "jumpModifier", amount = -0.3}})
end

function update(dt)
  mcontroller.controlModifiers({
      ToolUsageSuppressed = true,   
      facingSuppressed = true,
      movementSuppressed = true,  
      groundMovementModifier = 0.65,
      speedModifier = 0.45,
      airJumpModifier = 0.60
    })
end

function uninit()

end

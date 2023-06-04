function init()
  effect.setParentDirectives("fade=ffea00=0.4")
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.22}
  })
  self.movementModifiers = config.getParameter("movementModifiers", {})
  self.energyCost = 2
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.6,
      speedModifier = 0.65,
      airJumpModifier = 0.80
    })
end

function uninit()

end
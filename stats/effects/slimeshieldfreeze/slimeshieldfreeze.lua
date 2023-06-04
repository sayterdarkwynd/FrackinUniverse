function init()


  effect.addStatModifierGroup({
    {stat = "protection", amount = config.getParameter("protection", 80)},
    {stat = "fireStatusImmunity", amount = 1},
    {stat = "iceStatusImmunity", amount = 1},
    {stat = "electricStatusImmunity", amount = 1},
    {stat = "poisonStatusImmunity", amount = 1},
    {stat = "powerMultiplier", effectiveMultiplier = 0},
	{stat = "energyRegenPercentageRate", amount = config.getParameter("regenBonusAmount", -20)}
  })

status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})


  mcontroller.clearControls()
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
end

function update(dt)
  mcontroller.setVelocity({0, 0})
  mcontroller.clearControls()
  mcontroller.controlModifiers({
      facingSuppressed = true,
      movementSuppressed = true
    })
end

function uninit()
status.clearPersistentEffects("movementAbility")

end


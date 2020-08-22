function init()
  effect.addStatModifierGroup({{stat = "fallDamageMultiplier", effectiveMultiplier = 0}})
end

function update(dt)
  mcontroller.controlParameters({
      bounceFactor = 1.95
    })
end

function uninit()

end

function init()
  effect.addStatModifierGroup({{stat = "fallDamageMultiplier", baseMultiplier = 0.001}})
end

function update(dt)
  mcontroller.controlParameters({
        bounceFactor = 1.55
    })
end

function uninit()

end
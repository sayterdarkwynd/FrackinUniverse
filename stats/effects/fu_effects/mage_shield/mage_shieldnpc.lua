function init()
  animator.setAnimationState("aura", "windup")
    effect.addStatModifierGroup({
      {stat = "physicalResistance", amount = 1 },
      {stat = "electricResistance", amount = 0.5 },
      {stat = "poisonResistance", amount = 1 },
      {stat = "iceResistance", amount = 0.7 },
      {stat = "fireResistance", amount = 0.7 },
      {stat = "radioactiveResistance", amount = 0.6 },
      {stat = "shadowResistance", amount = 0.7 },
      {stat = "cosmicResistance", amount = 0.7 }
      })
      script.setUpdateDelta(1)
end

function update(dt)

end

function uninit()
  animator.setAnimationState("aura", "off")
end
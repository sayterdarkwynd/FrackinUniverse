function init()
  animator.setAnimationState("aura", "on")
  effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = 0.25 },
    {stat = "electricResistance", amount = 0.25 },
    {stat = "protection", amount = 25},
    --reduce effects of Madness
    {stat = "mentalProtection", amount = 0.5}
  })
end

function update(dt)

end

function uninit()

end

require "/scripts/status.lua"

function init()
  effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = 1},
    {stat = "iceResistance", amount = 1},
    {stat = "fireResistance", amount = 1},
    {stat = "poisonResistance", amount = 1},
    {stat = "electricResitsance", amount = 1},
    {stat = "cosmicResistance", amount = 1},
    {stat = "radioactiveResistance", amount = 1},
    {stat = "shadowResistance", amount = 1},
    {stat = "protection", amount = 100.0}
  })
  animator.playSound("trolol")
  self.listener = damageListener("damageTaken", function()
    animator.setAnimationState("shield", "hit")
  end)
end

function update(dt)
  self.listener:update()
end

function uninit()
  
end
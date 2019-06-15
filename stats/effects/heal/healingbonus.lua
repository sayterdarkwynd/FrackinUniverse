function init()
  self.healingBonus = config.getParameter("healingBonus", 0)
  effect.addStatModifierGroup({{stat = "healingBonus", amount = self.healingBonus}})
end

function update(dt)

end

function uninit()
  
end

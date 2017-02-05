function init()
 --Power
  self.critChanceup = config.getParameter("critChanceMultiplier", 0)
  effect.addStatModifierGroup({{stat = "critBonus", baseMultiplier = self.critChanceup}})
end


function update(dt)

end

function uninit()
end

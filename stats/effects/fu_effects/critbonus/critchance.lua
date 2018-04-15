function init()
 --Power
  self.critChanceup = config.getParameter("critChanceMultiplier", 0)
  effect.addStatModifierGroup({{stat = "critChance", baseMultiplier = self.critChanceup}})
end


function update(dt)

end

function uninit()
end

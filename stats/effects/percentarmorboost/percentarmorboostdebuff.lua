function init()
  effect.setParentDirectives("fade=FFCC00=0.20")
  script.setUpdateDelta(5)
  _x = config.getParameter("defenseModifier", 0)
  baseValue = config.getParameter("defenseModifier",0)*(status.stat("protection"))
 effect.addStatModifierGroup({{stat = "protection", amount = baseValue }})
end

function update(dt)
  
end

function uninit()
  
end
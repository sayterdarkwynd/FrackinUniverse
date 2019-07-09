function init()
  _x = config.getParameter("defenseModifier", 0)
  baseValue = config.getParameter("defenseModifier",0)*(status.stat("protection"))
  effect.addStatModifierGroup({{stat = "protection", amount = baseValue }})
end
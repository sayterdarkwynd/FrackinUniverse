function init()
   effect.addStatModifierGroup({{stat = "protection", amount = config.getParameter("defenseAmount", 0)}})

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()

end
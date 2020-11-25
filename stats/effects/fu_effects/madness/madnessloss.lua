function init()
  script.setUpdateDelta(3)

  effect.addStatModifierGroup({
    {stat = "mentalProtection", amount = config.getParameter("mentalProtect")}
  })


end

function update(dt)

end

function uninit()

end
function init()
  effect.addStatModifierGroup({
    {stat = "protection", effectiveMultiplier = config.getParameter("protectionModifier", 0.01)}
  })
end

function update(dt)
end

function uninit()
end

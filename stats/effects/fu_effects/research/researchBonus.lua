function init()
  effect.addStatModifierGroup({
    { stat = "researchBonus", amount = config.getParameter("researchBonus") }
  })
end

function update(dt)
end


function uninit()
end

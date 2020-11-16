function init()
  effect.addStatModifierGroup({
    { stat = "researchBonus", amount = config.getParameter("researchBonus") },
    { stat = "protection", baseMultiplier =0.5 }
  })    
end

function update(dt)
end


function uninit()
end

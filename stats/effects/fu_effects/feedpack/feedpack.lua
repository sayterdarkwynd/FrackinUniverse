function init() 
effect.addStatModifierGroup({
  {stat = "foodDelta", amount = config.getParameter("regenAmount", 0)}
})
end

function update(dt)

end

function uninit()
  
end
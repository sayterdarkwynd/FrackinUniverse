function init() 

  self.species = world.entitySpecies(entity.id())
  
  if self.species == "kazdra" then
    self.foodCost = 4
  else
    self.foodCost = 6
  end
  
  effect.addStatModifierGroup({
    {stat = "foodDelta", amount = -self.foodCost }
  })
end

function update(dt)

end

function uninit()
  
end
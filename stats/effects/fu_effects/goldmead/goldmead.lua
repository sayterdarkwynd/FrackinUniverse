function init()
	fTickRate = config.getParameter("tickRate", 60)
	fTickAmount = config.getParameter("tickAmount", 1)
	species = world.entitySpecies(entity.id())
  script.setUpdateDelta(fTickRate)  
end

function update(dt)
  if (species == "kirhos") or (species == "fukirhos") or (species == "shadow") then
    self.speciesLuck = status.stat("fuCharisma") + math.random(25)
  else
    self.speciesLuck = 0
  end
  
  if species == "shadow" or self.speciesLuck > 2 then
    self.essenceOn = 1
  end
  if species == "floran" then
    self.plantOn = 1
  end  
  if species == "fenerox" then
    self.leatherOn = 1
  end  
  
  randval = math.random(10)
  if randval == 10 and self.essenceOn then
    self.itemName = "essence"
    self.baseMath = math.random(20) 
  elseif randval == 10 and self.plantOn then
    self.itemName = "livingroot"
    self.baseMath = 1   
  elseif randval == 10 and self.leatherOn then
    self.itemName = "leather"
    self.baseMath = 1     
  elseif randval >= 8 then
    self.itemName = "fuscienceresource"
    self.baseMath = math.random(30)
  elseif randval < 8 then
    self.itemName = "money"
    self.baseMath = math.random(50) + self.speciesLuck
  end  
  if not self.itemName then self.itemName = "money" end
  
  world.spawnItem(self.itemName,mcontroller.position(),self.baseMath)
  
end

function uninit()

end

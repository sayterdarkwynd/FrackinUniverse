function init()
	species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())
	fTickRate = config.getParameter("tickRate", 60)
	fTickAmount = config.getParameter("tickAmount", 1)
  script.setUpdateDelta(fTickRate)
end

function update(dt)
if not species then species=status.statusProperty("fr_race") or world.entitySpecies(entity.id()) end
  if (species == "kirhos") or (species == "fukirhos") or (species == "shadow") then
    speciesLuck = ((1-status.stat("fuCharisma"))*100) + math.random(25)
  else
    speciesLuck = 0
  end

  if species == "shadow" or speciesLuck > 2 then
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
    self.baseMath = math.random(50) + speciesLuck
  end
  if not self.itemName then self.itemName = "money" end

  world.spawnItem(self.itemName,mcontroller.position(),self.baseMath)

end

function uninit()

end

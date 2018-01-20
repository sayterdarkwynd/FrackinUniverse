function checkResearchBonus()
  self.researchBonus = status.stat("researchBonus") or 0
  self.randomChanceResearch = math.random(1000) - self.researchBonus
  if self.randomChanceResearch < 1 then
      world.spawnItem("fuscienceresource",mcontroller.position(),math.random(30))
  end
end

function checkResearchBonus_GUI()
  self.researchBonus = config.getParameter("researchBonus",0) + status.stat("researchBonus")
  self.randomChanceResearch = math.random(1000) - self.researchBonus
  if self.randomChanceResearch <= 5 then
      player.consumeCurrency("fuscienceresource", math.random(40))
  end
end
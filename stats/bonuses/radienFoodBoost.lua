function init()
  self.armorTimer = 0
  self.armorTotal = 1
end

function checkHealth()
  self.baseHealth = config.getParameter("baseHealth")
  self.baseEnergy =  config.getParameter("baseEnergy")
  self.healthMultPenalty = self.baseHealth * ( self.baseHealth *  -(1 - (self.foodValue)))
  self.energyMultBonus = self.baseEnergy * ( self.baseEnergy *  -(1 - (self.foodValue)))
  self.finalHealth = math.ceil(self.healthMultPenalty * self.baseMod) -2
  self.finalEnergy = math.ceil(self.healthMultPenalty * self.baseMod) -3
end

function setValues()
  self.radiationBoost = self.foodValue * 0.40
  self.poisonBoost = self.foodValue * 0.10
  self.powerMultBonus = self.foodValue * 0.15
  self.firePenaltyBonusMod = -0.25 + (self.powerMultBonus)
  self.icePenaltyBonusMod = -0.25 + (self.powerMultBonus)
  self.electricPenaltyBonusMod = -0.25 + (self.powerMultBonus)

  --failsafes so that at 10% food you are hard-locked to a particular amount to not get too weak
  if self.foodValue < 0.1 then
      self.firePenaltyBonusMod = -0.25
      self.poisonBoost = 0
      self.powerMultBonus = 0
      self.radiationBoost = 0.10
      self.firePenaltyBonusMod = -0.2
      self.icePenaltyBonusMod = -0.2
      self.electricPenaltyBonusMod = -0.2
  end  

  status.setPersistentEffects("radienPower", {
      {stat = "maxHealth", amount = self.finalHealth },
      {stat = "maxEnergy", amount = self.finalEnergy },
      --penalties
      {stat = "poisonResistance", amount = self.poisonBoost},
      {stat = "fireResistance", amount = self.firePenaltyBonusMod },
      --bonuses
      {stat = "radioactiveResistance", amount = self.radiationBoost },
      {stat = "iceResistance", amount = self.icePenaltyBonusMod },
      {stat = "electricResistance", amount = self.electricPenaltyBonusMod }
  })
end



function update(dt)
	if status.isResource("food") then
		self.foodValue = status.resourcePercentage("food")
	else
		self.foodValue=0.5
	end

  self.armorTimer = self.armorTimer + 1

  if self.armorTimer == 3000 then
    self.armorTimer = 0
    self.armorTotal = self.armorTotal + 1
    if self.armorTotal >= 25 then
      self.armorTotal = 25
    end

    status.setPersistentEffects("radienArmor", {
      {stat = "protection", amount = 1+ self.armorTotal }
    })
  end

  if self.foodValue >= 0.98 then
    self.dt = 1
    self.baseMod = 1
  else
    self.dt = 0
    self.baseMod = 1 * (10 + self.dt)
    self.dt = dt + (self.baseMod)
  end

  checkHealth()  -- set health adjustment stats
  setValues() -- set adjustments to stats

end

function uninit()
  status.clearPersistentEffects("radienPower")
  status.clearPersistentEffects("radienArmor")
  self.armorTotal = 1
  self.armorTimer = 0
end

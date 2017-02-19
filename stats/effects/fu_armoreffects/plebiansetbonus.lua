require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    setBonusInit("fu_plebianset", {
      {stat = "shieldStaminaRegen", baseMultiplier = 1.25},
      {stat = "shieldRegen", baseMultiplier = 1.25},
      {stat = "shieldHealth", baseMultiplier = 1.25},
      {stat = "perfectBlockLimitRegen", baseMultiplier = 1.25}
    })        
end
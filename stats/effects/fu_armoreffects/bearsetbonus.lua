require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
  setBonusInit("fu_bearset", {
    {stat = "iceResistance", amount = 0.15},
    {stat = "coldimmunity", amount = 1}
  }
end

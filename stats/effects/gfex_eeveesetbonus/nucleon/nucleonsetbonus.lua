function init()
   effect.addStatModifierGroup({
     {stat = "biomeradiationImmunity", amount = 1},
	   {stat = "radioactiveResistance", amount = 0.15},
     {stat = "sulphuricImmunity", amount = 1}
   })
  
  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end

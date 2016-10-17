function init()
  status.setPersistentEffects("fu_regen", {{stat = "healthRegen", amount = 0.01}})
end

function uninit()
  status.clearPersistentEffects("fu_regen") 
end

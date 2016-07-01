function init()
  status.setPersistentEffects("isn_airprotection", {{stat = "breathProtection", amount = 1}})
  status.setPersistentEffects("isn_radsprotection", {{stat = "biomeradiationImmunity", amount = 1}})
  status.setPersistentEffects("isn_coldprotection", {{stat = "biomecoldImmunity", amount = 1}})
  status.setPersistentEffects("isn_heatprotection", {{stat = "biomeheatImmunity", amount = 1}})
  status.setPersistentEffects("fu_heatprotection", {{stat = "sulphuricacidImmunity", amount = 1}})
  status.setPersistentEffects("fu_heatprotection", {{stat = "ffextremeheatImmunity", amount = 1}})
  status.setPersistentEffects("fu_coldprotection", {{stat = "ffextremecoldImmunity", amount = 1}})
  status.setPersistentEffects("fu_radsprotection", {{stat = "ffextremeradiationImmunity", amount = 1}})
  
end

function uninit()
  status.clearPersistentEffects("isn_airprotection")
  status.clearPersistentEffects("isn_radsprotection")
  status.clearPersistentEffects("isn_coldprotection")
  status.clearPersistentEffects("isn_heatprotection")
  status.clearPersistentEffects("fu_radsprotection")
  status.clearPersistentEffects("fu_coldprotection")
  status.clearPersistentEffects("fu_heatprotection")  
end

function init()
  script.setUpdateDelta(3)
  self.protection = config.getParameter("protection") or 1
end

function update(dt)

  status.setPersistentEffects("madnessEffectsMain", {
      {stat = "protection", amount = self.protection + 11 }
  })
end

function uninit()
  status.clearPersistentEffects("madnessEffectsMain")
end
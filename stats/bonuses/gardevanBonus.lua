function init()
  self.healthRatio = 1

  script.setUpdateDelta(10)
end

function update(dt)
    if status.statPositive("maxHealth") then
        self.healthRatio = status.resource("health") / status.stat("maxHealth")
    else
        self.healthRatio = 0
    end

    if self.healthRatio < 0.75 then
        local configBombDrop = { power = 0 }
        world.spawnProjectile("grassseeds2", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
    end
end

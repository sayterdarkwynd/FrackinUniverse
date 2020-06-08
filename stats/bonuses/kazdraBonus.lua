function init()
    script.setUpdateDelta(10)
    self.timer = 2
    self.healthRatio = 1
end

function update(dt)
    self.timer = self.timer - dt
    if status.statPositive("maxHealth") then
        self.healthRatio = status.resource("health") / status.stat("maxHealth")
    else
        self.healthRatio = 0
    end

    if self.timer <= 0 then
        if self.healthRatio < 0.50 then
            local configBombDrop = { power = 3 }
            world.spawnProjectile("firefinish", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
        end
        self.timer=2
    end
end

function init()
    script.setUpdateDelta(10)
    self.timer = 2
end

function update(dt)
    self.timer = self.timer - dt

    if self.timer <= 0 then
        if status.resourcePercentage("health") < 0.50 then
            world.spawnProjectile("firefinish", mcontroller.position(), entity.id(), {0, 0}, false, { power = 3 })
        end
        self.timer=2
    end
end

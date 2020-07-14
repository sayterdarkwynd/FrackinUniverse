function init()

  script.setUpdateDelta(10)
end

function update(dt)

    if status.resourcePercentage("health") < 0.75 then
        local configBombDrop = { power = 0 }
        world.spawnProjectile("grassseeds2", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
    end
end

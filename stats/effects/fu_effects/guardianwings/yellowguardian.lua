function init()
 script.setUpdateDelta(5)
end

function update(dt)
status.modifyResourcePercentage("health", 1/200 * dt*math.max(0,1+status.stat("healingBonus")))
end

function uninit()

end
function FRHelper:call(args, ...)
    local vel = mcontroller.velocity()
    local magnitude = math.sqrt(vel[1] * vel[1] + vel[2] * vel[2])
    self:applyStats({
        stats = { { stat = "powerMultiplier", effectiveMultiplier = 1 + (magnitude / 4 * 0.01) } }
    }, "fr_velocitybonus", ...)
end

-- Intended for use with shield bashing

-- Possible args:
--     args.healthRecover      -- How much health (%) to recover on bash
--     args.resource           -- Overrides the resource recovered/drained (healthRecover is still used)
--     args.particles          -- Overrides the particles used
--     args.sound              -- Overrides the sound used

function FRHelper:call(args, ...)
    status.modifyResource(args.resource or "health", args.healthRecover or 1.2 )
    animator.burstParticleEmitter(args.particles or "bonusBlock3")
    animator.playSound(args.sound or "bonusEffect")
end

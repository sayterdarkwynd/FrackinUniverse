require "/scripts/fr_weaponscripts/particlebase.lua"

-- Intended for use with shield bashing

-- Possible args:
-- all the standard stuff with stat bonuses
--     args.particles          -- Overrides the particles used
--     args.sound              -- Overrides the sound used

--[[

Special stuff structure:

    "resources" : {               -- List of resources to modify
        "health" : {              -- Resource
            "base" : 0.01,        -- Base amount (%) (defaults to 0)

            -- If there is no comboBase then combos and max are not considered
            "comboBase" : 0.01,   -- Combo base amount (%), multiplied by (combo*comboMult) and added to base
            "comboMult" : 2       -- Multiplier on combo base per combo (2x combo * 3x comboMult = 6x comboBase) (defaults to 1)
            "max" : 0.05          -- Maximum total possible (in this example, a 2x combo will max this) (no default maximum)
        }
    },
    "statCombos" : {             -- List of stats to be affected by combos (base stat is in stats table)
        "powerMultiplier" : {    -- Stat
            "comboBase" : 0.05,  -- Combo base amount, same formula as above
            "comboMult" : 1,     -- Combo multiplier, same formula as above
            "max" : 0.50         -- Maximum total possible (this maxes out at a 10x combo with 0 base)
        }
    }

]]

function FRHelper:call(args, main, ...)
    for resource,stuff in pairs(args.resources or {}) do
        if status.resource(resource) then
            local amount = stuff.base or 0
            if stuff.comboBase then
                amount = amount + stuff.comboBase * (stuff.comboMult or 1) * main.blockCountShield
                if stuff.max then
                    amount = math.min(amount, stuff.max)
                end
            end
            if resource == "shieldStamina" then
                status.setResource(resource, status.resource(resource) * (amount + 1))
            else
				if resource=="health" then
					amount=amount*math.max(0,1+status.stat("healingBonus"))
				end
                status.modifyResourcePercentage(resource, amount)
            end
        end
    end

    local newargs = {stats={}}
    for _,stuff in ipairs(args.stats or {}) do
        local newStat = {stat=stuff.stat, baseMultiplier=stuff.baseMultiplier or nil, amount=stuff.amount or nil, effectiveMultiplier=stuff.effectiveMultiplier or nil}
        if args.statCombos[stuff.stat] then
            local data = args.statCombos[stuff.stat]
            if newStat.amount then
                newStat.amount = newStat.amount + data.comboBase * (data.comboMult or 1) * main.blockCountShield
                if data.max then
                    newStat.amount = math.min(newStat.amount, data.max)
                end
            elseif newStat.baseMultiplier then
                newStat.baseMultiplier = newStat.baseMultiplier + data.comboBase * (data.comboMult or 1) * main.blockCountShield
                if data.max then
                    newStat.baseMultiplier = math.min(newStat.baseMultiplier, data.max)
                end
            else
                newStat.baseMultiplier = newStat.effectiveMultiplier + data.comboBase * (data.comboMult or 1) * main.blockCountShield
                if data.max then
                    newStat.effectiveMultiplier = math.min(newStat.effectiveMultiplier, data.max)
                end
            end
        end
        table.insert(newargs.stats, newStat)
    end

	fuParticleBaseLoadCache(self,{"/particles/cartoonstars/greencartoonstar.particle","/particles/cartoonstars/redcartoonstar.particle","/particles/sparkles/sparkle5.particle","/particles/charge.particle","/particles/healthcross.particle"})
	fuParticleBaseLoadLists(self)

	if self.fuParticleBaseParticleLists then
		fuParticleBaseParticleBurst(self.fuParticleBaseParticleLists,{args.particles,"bonusBlock3"})
	end
    --newargs = util.mergeTable(util.mergeTable({}, args), newargs)
    --animator.burstParticleEmitter(args.particles or "bonusBlock3")
    if animator.hasSound(args.sound or "bonusEffect") then animator.playSound(args.sound or "bonusEffect") end

    self:applyStats(newargs, args.name or "FR_perfectBlockBonus", main, ...)
end
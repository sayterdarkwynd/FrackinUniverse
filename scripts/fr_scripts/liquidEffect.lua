require("/scripts/vec2.lua")
require("/scripts/util.lua")

--[[
    This script is for applying effects while the race is in liquids.
    Structure:

    "liquidEffects" : [
        -- effect 1
        {
            "name" : "thingy"            -- name of the effect, useful for detection in other scripts; optional
            "liquids" : [ 1, 2, 3, 4 ]   -- liquids that trigger the effect; optional (no liquids means any liquid will work)
            "stats" : []                 -- put stat changes in here, just like normal
            "controlModifiers" : {}      -- just like normal
            "controlParameters" : {}     -- you should get the picture by now
            "status" : [ "glow" ]        -- put any status effects to be applied in here
        },
        -- effect 2
        {
            -- you can have as many effects as you want
        }
    ]

]]
liquideffect_errorLogged = false

function FRHelper:call(args, ...)
	-- Investigative debug code
	local pos = mcontroller.position()
	local mouth = status.statusProperty("mouthPosition")
	if mouth == nil then
		if not liquideffect_errorLogged then
			sb.logError("FR ERROR: MOUTH POSITION NOT FOUND - You got a mod conflict here, buddy. Somethin is messin up your NPCs."
						.."\nNPC TYPE: "..world.npcType(entity.id())
						.."\nSPECIES:  "..world.entitySpecies(entity.id()))
			liquideffect_errorLogged = true
		end
		return
	end
	-- End investigative debug code
    local mouthPosition = vec2.add(pos, mouth)
    for i,thing in ipairs(args or {}) do
        if thing.liquids then
            -- Liquid map translation, allows for easy file reading (put in "milk" instead of 7)
            for i,liquid in ipairs(thing.liquids) do
                if type(liquid) == "string" then
                    thing.liquids[i] = self.frconfig.liquidMaps[liquid]
                end
            end
        end
        if world.liquidAt(mouthPosition) and (not thing.liquids or contains(thing.liquids, mcontroller.liquidId())) then
            self:applyStats(thing, thing.name or "liquidEffect"..i, ...)
            for x,thing2 in ipairs(thing.status or {}) do
                status.addEphemeralEffect(thing2, math.huge)
            end
        else
            self:clearPersistent(thing.name or "liquidEffect"..i)
            for x,thing2 in ipairs(thing.status or {}) do
                status.removeEphemeralEffect(thing2)
            end
        end
    end
end

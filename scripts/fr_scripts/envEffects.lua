--[[
This is intended to be run from raceability.lua through a mapping in frackinraces.config
Structure:

"envEffects" : [
    {
        "name" : "bob"    -- Specify a name for the persistent effect. Useful for scripting or complex interactions.
        "biomes" : [ "someBiome", "anotherBiome", ... ], -- single biomes
        -- OR --
        "biomes" : "hot",                                -- biome group

        "stats" : [],              -- Stats
        "controlModifiers" : [],   -- Control modifiers
        "controlParameters" : [],  -- Control parameters
        "scripts" : []             -- Can be used to call other scripts.
    },
    {
        ...
    }
]
]]

function FRHelper:call(args, main)
    for i,thing in ipairs(args or {}) do
		local name = thing.name or "envEffect"..i
        if type(thing.biomes) == "string" then
            local groups = self.frconfig.biomeGroups[thing.biomes]
            if groups and contains(groups, world.type()) then
                self:applyStats(thing, name)
            else
				self:clearPersistent(name)
			end
        elseif thing.biomes and contains(thing.biomes, world.type()) then
            self:applyStats(thing, thing.name or "envEffect"..i)
        else
			self:clearPersistent(name)
		end
    end
end

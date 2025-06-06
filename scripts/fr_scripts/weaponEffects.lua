require "/items/active/tagCaching.lua"

--[[
This is intended to be run from raceability.lua through a mapping in frackinraces.config
Structure:

"weaponEffects" : [
    {
        "name" : "bob"    -- Specify a name for the persistent effect. Useful for scripting or complex interactions.
        "weapons" : [ "dagger", "broadsword", ... ],            -- single weapons
        -- OR --
        "combos" : [ [ "dagger", "dagger" ], [ "boomerang" ] ]  -- weapon combos (single-weapon combos are holding only 1 weapon)

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

function FRHelper:call(args, ...)
	--tagCaching.update()--do not put this here. this should run only ONCE per script update per script context. this is called in fr_raceeffects
    local primaryItem = world.entityHandItemDescriptor(entity.id(), "primary")
    local altItem = world.entityHandItemDescriptor(entity.id(), "alt")
    for i,weap in ipairs(args or {}) do
        local appliedbonus
        local name
        if weap.combos then -- Weapon combos
            name = weap.name or "FR_weaponComboEffect"..i
            for _,combo in ipairs(weap.combos) do
                if self:validCombo(primaryItem, altItem, combo) then
                    self:applyStats(weap, name, ...)
                    appliedbonus = true
                    break
                end
            end
        elseif weap.weapons then -- Single weapons
            name = weap.name or "FR_weaponEffect"..i
            for _,thing in ipairs(weap.weapons) do
				if tagCaching.primaryTagCache[thing] or tagCaching.altTagCache[thing] then
                    self:applyStats(weap, name, ...)
                    appliedbonus = true
                    break
                end
            end
        end
        if name and (not appliedbonus) then
            self:clearPersistent(name)
        end
    end
end

require "/scripts/status.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	effect.addStatModifierGroup({{stat = "pandorasboxglitchtopglitchedImmunity", amount = 1}})

	script.setUpdateDelta(0)
end

function update(dt)

end

require "/scripts/effectUtil.lua"

function init()
	script.setUpdateDelta(10)
end

function update(dt)
	effectUtil.effectAllInRange("glowred",60)
end

function uninit()
end

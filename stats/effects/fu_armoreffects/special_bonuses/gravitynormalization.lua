require "/scripts/unifiedGravMod.lua"

function init()
	unifiedGravMod.init()
	unifiedGravMod.initSoft()
end

function update(dt)
	unifiedGravMod.update(dt)
end

function uninit()
	unifiedGravMod.uninit()
end
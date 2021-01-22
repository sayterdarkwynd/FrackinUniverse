require "/scripts/effectUtil.lua"

function init()
   effect.setParentDirectives("border=1;000000ff;00000000")
end

function update(dt)
	if status.stat("chargingConshak") >= 490 then
		effect.setParentDirectives("border=2;8ff0ffff;00000000")
	elseif status.stat("chargingConshak") >= 420 then
		effect.setParentDirectives("border=1;5ff0ffff;00000000")
	elseif status.stat("chargingConshak") >= 350 then
		effect.setParentDirectives("border=1;2ac4ffee;00000000")
	elseif status.stat("chargingConshak") >= 220 then
		effect.setParentDirectives("border=1;2a75ffcc;00000000")
	elseif status.stat("chargingConshak") >= 100 then
		effect.setParentDirectives("border=1;3c2affaa;00000000")
	elseif status.stat("chargingConshak") >= 50 then
		effect.setParentDirectives("border=1;b22aff99;00000000")
	elseif status.stat("chargingConshak") >= 20 then
		effect.setParentDirectives("border=1;a300ff55;00000000")
	else
		effect.setParentDirectives("border=1;22002255;00000000")
	end
end

function uninit()
end
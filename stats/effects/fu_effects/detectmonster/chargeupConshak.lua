require "/scripts/effectUtil.lua"

function init()
   effect.setParentDirectives("border=1;000000ff;00000000")  
end

function update(dt)
	if status.stat("chargingConshak") >= 480 then
		effect.setParentDirectives("border=3;ff00ffff;00000000") 
	elseif status.stat("chargingConshak") >= 370 then
		effect.setParentDirectives("border=2;cc00ccee;00000000") 	
	elseif status.stat("chargingConshak") >= 270 then
		effect.setParentDirectives("border=1;aa00aacc;00000000") 
	elseif status.stat("chargingConshak") >= 170 then
		effect.setParentDirectives("border=1;770077aa;00000000") 		
	elseif status.stat("chargingConshak") >= 100 then
		effect.setParentDirectives("border=1;44004488;00000000") 
	elseif status.stat("chargingConshak") >= 40 then
		effect.setParentDirectives("border=1;11001155;00000000") 		
	else
		effect.setParentDirectives("border=1;00000055;00000000") 														
	end
end

function uninit()
end
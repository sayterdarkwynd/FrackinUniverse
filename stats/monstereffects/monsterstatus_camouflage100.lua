local fu_monsters_init = init
local fu_monsters_update = update
local fu_monsters_uninit = uninit

function init()
	if fu_monsters_init then
		fu_monsters_init()
	end
	status.addEphemeralEffect("camouflage100",math.huge)
end



function update(dt)
	if fu_monsters_update then
		fu_monsters_update(dt)
	end
end



function uninit()
	if fu_monsters_uninit then
		fu_monsters_uninit()
	end
end
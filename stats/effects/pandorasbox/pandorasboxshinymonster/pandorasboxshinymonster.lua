require "/scripts/messageutil.lua"

function init()

end


function update(dt)
	if not inited then
		promises:add(world.sendEntityMessage(entity.id(), "pandorasboxGetColorDirectives"), function(colorDirectives)
			if colorDirectives then
				effect.setParentDirectives(colorDirectives)
			end
			script.setUpdateDelta(0)
		end)
		inited = true
	end
	promises:update()
end

function uninit()

end

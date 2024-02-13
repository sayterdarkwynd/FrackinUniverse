function init()
	cadaverRoll = config.getParameter("cadaverRoll") --50% can produce a corpse
	local wasNil=(cadaverRoll==nil)
	if not cadaverRoll then cadaverRoll = math.random(1,2) end
	object.setConfigParameter("cadaverRoll",cadaverRoll)
	--object.setConfigParameter("retainObjectParametersInItem",true)--doesn't work here.
	object.setInteractive(wasNil or (cadaverRoll==1))
end

function onInteraction()
	if cadaverRoll == 1 then --if random chance is 1
		cadaverRoll = 2 -- set to 0 so we never repeat
		object.setConfigParameter("cadaverRoll",cadaverRoll)
		checkSarco() -- spawn the item
	end
	object.setInteractive(false)
end

function onNpcPlay(npcId)
	local interact = config.getParameter("npcToy.interactOnNpcPlayStart")
	if interact == nil or interact ~= false then
		onInteraction()
	end
end

function checkSarco()
	world.spawnItem("wrappedbodybirb", object.position(), 1)
	object.smash()
end

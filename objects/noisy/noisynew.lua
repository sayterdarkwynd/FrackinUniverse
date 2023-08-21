function init()
	cadaverRoll = config.getParameter("cadaverRoll") --50% can produce a corpse
	local wasNil=(cadaverRoll==nil)
	if not cadaverRoll then cadaverRoll = 0 end
	object.setConfigParameter("cadaverRoll",cadaverRoll)
	self.sounds = config.getParameter("sounds", {})
	animator.setSoundPool("noise", self.sounds)
	--object.setConfigParameter("retainObjectParametersInItem",true)--doesn't work here.
	object.setInteractive(wasNil or (cadaverRoll<4))
end

function onInteraction()
	if cadaverRoll < 3 then
		if #self.sounds > 0 then
			animator.playSound("noise")
			cadaverRoll = cadaverRoll + 1
		end
	elseif cadaverRoll == 3 then
		local crewtype = "crewmemberLoveliusSmythe"
		local seed = math.random(255)
		local parameters = {}
		local crewrace = "human"
		cadaverRoll = cadaverRoll + 1
		object.setConfigParameter("cadaverRoll",cadaverRoll)
		world.spawnNpc(object.position(), crewrace, crewtype, 1, seed, parameters)
		object.smash()
	end
end

function onNpcPlay(npcId)
	local interact = config.getParameter("npcToy.interactOnNpcPlayStart")
	if interact == nil or interact ~= false then
		onInteraction()
	end
end

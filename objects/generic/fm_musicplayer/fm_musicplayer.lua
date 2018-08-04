

function uninit() stopMusic() end
function die() stopMusic() end

function init()
	self.players = {}
	message.setHandler("changeMusic", changeMusic)
	message.setHandler("turnOff", turnOff)
	message.setHandler("toggleLabel", toggleLabel)
end

function update()
	if storage.musicName then
		for pid, _ in pairs(self.players) do
			if not playerInRange(pid) then
				self.players[pid] = nil
				world.sendEntityMessage(pid, "stopAltMusic", 2.0)
			end
		end
		
		local newPlayers = world.playerQuery(object.position(), config.getParameter("musicRadius", 30))
		for _, pid in ipairs(newPlayers) do
			if not self.players[pid] then
				self.players[pid] = true
			end
		end
		
		setLightState(storage.isPlaying)
		if not storage.hideLabel then
			object.say(storage.musicName or "")
		end
	end
end

function changeMusic(_,_, dir, name)
	storage.isPlaying = true
	storage.musicName = name
	storage.musicDir = dir
end

function turnOff()
	if storage.musicName and not storage.hideLabel then
		object.say("Shutting down...")
	end
	
	update()
	self.players = {}
	storage.isPlaying = nil
	storage.musicName = nil
	storage.musicDir = nil
end

function toggleLabel()
	if storage.hideLabel then
		storage.hideLabel = nil
	else
		storage.hideLabel = true
		if storage.musicName then
			object.say("Hiding label...")
		end
	end
end

function startMusic()
	for playerId, _ in pairs(self.players) do
		world.sendEntityMessage(playerId, "playAltMusic", {storage.musicDir}, 2.0)
	end
end

function stopMusic()
	for playerId, _ in pairs(self.players) do
		world.sendEntityMessage(playerId, "stopAltMusic", 2.0)
	end
end

function setLightState(newState)
	if newState then
		animator.setAnimationState("light", "on")
		object.setSoundEffectEnabled(true)
		startMusic()
		
		if animator.hasSound("on") then
			animator.playSound("on");
		end
	else
		animator.setAnimationState("light", "off")
		object.setSoundEffectEnabled(false)
		stopMusic()
		
		if animator.hasSound("off") then
			animator.playSound("off")
		end
	end
end

function playerInRange(id)
	if not world.entityExists(id) or world.magnitude(object.position(), world.entityPosition(id)) > config.getParameter("musicRadius", 30) then
		return false end
	return true
end


-- function wireCheck()
	-- if object.isInputNodeConnected(0) and object.getInputNodeLevel(0) then
		-- return true
	-- end
	-- return false
-- end
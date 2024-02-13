


function init()
	self.players = {}
	self.lastWireModified = 0

	message.setHandler("changeMusic", changeMusic)
	message.setHandler("turnOff", turnOff)
	message.setHandler("toggleLabel", toggleLabel)
	message.setHandler("setMusicRange", setMusicRange)

	self.musicboxlist={"fm_musicplayer","fm_musicplayerwall","apexbox","avianbox","elduukharbox","feneroxbox","floranbox","glitchbox","humanbox","hylotlbox","juuxbox","kirhosbox","mantizibox","nightarbox","novakidbox","peglacibox","radienbox","skathbox","slimebox","tenebrhaebox","thelusianbox","veluubox"}

	if storage.isPlaying then
		animator.setAnimationState("light", "on")
	end
end

function update()
	if storage.isPlaying then
		for pid, _ in pairs(self.players) do
			if not playerInRange(pid) then
				self.players[pid] = nil
				world.sendEntityMessage(pid, "stopAltMusic", 2.0)
			end
		end

		local newPlayers = world.playerQuery(object.position(), (storage.range or config.getParameter("musicRadius", 30)))
		for _, pid in ipairs(newPlayers) do
			if not self.players[pid] then
				self.players[pid] = true
			end
		end

		if not storage.hideLabel then
			object.say(storage.musicName or "")
		end

		for playerId, _ in pairs(self.players) do
			world.sendEntityMessage(playerId, "playAltMusic", {storage.musicDir}, 2.0)
		end
	else
		uninit()
	end
end

-- Called via update to turn off music, as well as when broken
function uninit()
	for playerId, _ in pairs(self.players) do
		world.sendEntityMessage(playerId, "stopAltMusic", 2.0)
	end
	self.players = {}
end

function changeMusic(_,_, dir, name, direction, time)
	if self.lastWireModified ~= time then
		self.lastWireModified = time or os.time()

		storage.isPlaying = true
		storage.musicName = name
		storage.musicDir = dir
		animator.setAnimationState("light", "on")

		object.setOutputNodeLevel(0, true)
		local output = object.getOutputNodeIds(0)
		if not direction or direction == "output" then
			for id, _ in pairs(output) do
				for _,musicboxid in pairs(self.musicboxlist) do
					if world.entityName(id) == musicboxid then
						world.sendEntityMessage(id, "changeMusic", dir, name, "output", self.lastWireModified)
					end
				end
			end
		end

		local input = object.getInputNodeIds(0)
		if not direction or direction == "input" then
			for id, _ in pairs(input) do
				for _,musicboxid in pairs(self.musicboxlist) do
					if world.entityName(id) == musicboxid then
						world.sendEntityMessage(id, "changeMusic", dir, name, "input", self.lastWireModified)
					end
				end
			end
		end
	end
end

function turnOff(_,_, direction, time)
	if self.lastWireModified ~= time then
		self.lastWireModified = time or os.time()

		if storage.musicName and not storage.hideLabel then
			object.say("Shutting down...")
		end

		storage.isPlaying = nil
		storage.musicName = nil
		storage.musicDir = nil
		animator.setAnimationState("light", "off")

		object.setOutputNodeLevel(0, false)
		local output = object.getOutputNodeIds(0)
		if not direction or direction == "output" then
			for id, _ in pairs(output) do
				for _,musicboxid in pairs(self.musicboxlist) do
					if world.entityName(id) == musicboxid then
						world.sendEntityMessage(id, "turnOff", "output", self.lastWireModified)
					end
				end
			end
		end

		local input = object.getInputNodeIds(0)
		if not direction or direction == "input" then
			for id, _ in pairs(input) do
				for _,musicboxid in pairs(self.musicboxlist) do
					if world.entityName(id) == musicboxid then
						world.sendEntityMessage(id, "turnOff", "input", self.lastWireModified)
					end
				end
			end
		end
	end
end

function toggleLabel(_,_, state, direction, time)
	if self.lastWireModified ~= time then
		self.lastWireModified = time or os.time()

		if state == nil then
			if storage.hideLabel then
				storage.hideLabel = nil
			else
				storage.hideLabel = true
				if storage.musicName then
					object.say("Hiding label...")
				end
			end
		else
			storage.hideLabel = state
			if state and storage.musicName then
				object.say("Hiding label...")
			end
		end

		local output = object.getOutputNodeIds(0)
		if not direction or direction == "output" then
			for id, _ in pairs(output) do
				if world.entityName(id) == "fm_musicplayer" or world.entityName(id) == "fm_musicplayerwall" then
					world.sendEntityMessage(id, "toggleLabel", storage.hideLabel, "output", self.lastWireModified)
				end
			end
		end

		local input = object.getInputNodeIds(0)
		if not direction or direction == "input" then
			for id, _ in pairs(input) do
				if world.entityName(id) == "fm_musicplayer" or world.entityName(id) == "fm_musicplayerwall" then
					world.sendEntityMessage(id, "toggleLabel", storage.hideLabel, "input", self.lastWireModified)
				end
			end
		end
	end
end

function setMusicRange(_,_, range)
	if config.getParameter("musicRadius", 30) == range then
		storage.range = nil
	else
		storage.range = range
	end
end

function playerInRange(id)
	if not world.entityExists(id) or world.magnitude(object.position(), world.entityPosition(id)) > (storage.range or config.getParameter("musicRadius", 30)) then
		return false end
	return true
end

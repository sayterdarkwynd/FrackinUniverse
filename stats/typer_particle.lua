cfg = { }
instances = { }
spawnCooldown = 0
runningTime = 0
tid = 1

-- 		Usage:
-- Attach as a script to a status effect (in the 'scripts' field), and configure through a custom 'effectConfig' field in the effects root.
-- Full config example:
--  "effectConfig" : {
--		// Basically a text particle definition.
--    "typerParticleConfig" : {
--      "particle" : {
--        "color" : [0, 0, 0, 205],
--        "size" : 1,
--        "fade" : 0.7,
--        "destructionTime" : 0.8,
--        "initialVelocity" : [0, 4],
--        "finalVelocity" : [0, 0],
--        "timeToLive" : 0,
--        "destructionAction" : "shrink"
--      },
--
--      "spawnInterval" : 0.5,
--      "writeInterval" : 0.1,
--      "printTextInOrder" : false,
--      "loopOrderedText" : true,
--      "spacing" : [1, 1.5],
--      "boundingBox" : [ 0, 0 ],
--      "texts" : [
--        "*honk*",
--        "*HONK*",
--        "h o n k",
--        "H O N K",
--        "Kevin says hi",
--        "banana",
--        "clown",
--        "*wilhelm scream*"
--      ],
--
--		// All of these are optional
--      "controllers" : {
--        "color" : [125, 50, 25, 0],
--        "colorLoop" : true,
--        "size" : 1,
--        "sizeMax" : 10,
--        "timeToLive" : 1,
--        "timeToLiveMax" : 5,
--        "boundingBox" : [3, 3],
--        "boundingBoxMax" : [50, 50],
--        "spacing" : [1, 1.5]
--      }
--    }
--  },

-- Contains all controller methods.
-- Irrelevant ones are culled on init, based on config
controllerChain = { 
	color = function(dt)
		if cfg.controllers.colorLoop then
			-- Giving a 255 headtsrat because the correct color calculation only works above 255
			realColor = realColor or {
				255 + cfg.particle.color[1],
				255 + cfg.particle.color[2],
				255 + cfg.particle.color[3],
				255 + cfg.particle.color[4]
			}
			
			realColor = {
				realColor[1] + cfg.controllers.color[1] * dt,
				realColor[2] + cfg.controllers.color[2] * dt,
				realColor[3] + cfg.controllers.color[3] * dt,
				realColor[4] + cfg.controllers.color[4] * dt
			}

			cfg.particle.color = {
				math.abs(255 - realColor[1] % 510),
				math.abs(255 - realColor[2] % 510),
				math.abs(255 - realColor[3] % 510),
				math.abs(255 - realColor[4] % 510)
			}
		else
			cfg.particle.color = {
				math.max(0, math.min(cfg.particle.color[1] + cfg.controllers.color[1] * dt, 255)),
				math.max(0, math.min(cfg.particle.color[2] + cfg.controllers.color[2] * dt, 255)),
				math.max(0, math.min(cfg.particle.color[3] + cfg.controllers.color[3] * dt, 255)),
				math.max(0, math.min(cfg.particle.color[4] + cfg.controllers.color[4] * dt, 255))
			}
		end
	end,

	size = function(dt)
		if not cfg.controllers.sizeMax or cfg.particle.size < cfg.controllers.sizeMax then
			cfg.particle.size = cfg.particle.size + cfg.controllers.size * dt
		end
	end,

	timeToLive = function(dt)
		if not cfg.controllers.lifeSpanMax or cfg.particle.timeToLive < cfg.controllers.lifeSpanMax then
			cfg.particle.timeToLive = cfg.particle.timeToLive + cfg.controllers.timeToLive * dt
		end
	end,

	boundingBox = function(dt)
		cfg.boundingBox = cfg.boundingBox or {0, 0}

		if cfg.controllers.boundingBoxMax then
			cfg.boundingBox = {
				math.min(cfg.boundingBox[1] + cfg.controllers.boundingBox[1] * dt, cfg.controllers.boundingBoxMax[1]),
				math.min(cfg.boundingBox[2] + cfg.controllers.boundingBox[2] * dt, cfg.controllers.boundingBoxMax[2])
			}
		else
			cfg.boundingBox = {
				cfg.boundingBox[1] + cfg.controllers.boundingBox[1] * dt,
				cfg.boundingBox[2] + cfg.controllers.boundingBox[2] * dt
			}
		end

		cfg.boundingBox = {
			math.max(0, cfg.boundingBox[1]),
			math.max(0, cfg.boundingBox[2])
		}
	end,

	spacing = function(dt)
		cfg.spacing = {
			cfg.spacing[1] + cfg.controllers.spacing[1] * dt,
			cfg.spacing[2] + cfg.controllers.spacing[2] * dt
		}
	end
}

function init()
	-- Commit lifen't on non-players
	if world.entityType(entity.id()) ~= "player" then
		effect.expire()
		return
	end

	-- Get config and set constant particle info
	cfg = config.getParameter("typerParticleConfig")
	cfg.particle.type = "text"
	cfg.particle.layer = "front"

	-- Remove unused controllers
	if cfg.controllers then
		for controller, _ in pairs(controllerChain) do
			if not cfg.controllers[controller] then
				controllerChain[controller] = nil
			end
		end

		-- If the color is looping, it doesn't matter visually in which direction its going (beyond the past loop anyways)
		-- But it does for the code so....
		if cfg.controllers.color and cfg.controllers.colorLoop then
			for i, color in ipairs(cfg.controllers.color) do
				cfg.controllers.color[i] = math.abs(color)
			end
		end
	else
		controllerChain = nil
	end

	-- Set the correct picking method to the generic placeholder
	-- Clear the other one
	if (cfg.printTextInOrder) then
		SelectText = SelectOrdered
		SelectRandom = nil
	else
		SelectText = SelectRandom
		SelectOrdered = nil
	end

	script.setUpdateDelta(1)
end

function update(dt)
	-- Keeps track of how long the effect is running
	runningTime = runningTime + dt

	local toRemove = {}
	for i, data in ipairs(instances) do
		if (runningTime - data.lastTime >= cfg.writeInterval) then
			cfg.particle.position = data.position
			cfg.particle.text = string.sub(data.text, data.index, data.index)
			world.sendEntityMessage(entity.id(), "fu_specialAnimator.spawnParticle", cfg.particle)

			data.position[1] = data.position[1] + cfg.spacing[1]
			data.lastTime = runningTime
			data.index = data.index + 1

			-- New line
			if (string.sub(data.text, data.index, data.index) == "\n") then
				data.position[1] = data.origin[1]
				data.position[2] = data.position[2] + cfg.spacing[2]
				data.index = data.index + 1
			end
			
			-- Mark for removal if the entire string was printed out
			if (data.index > #data.text) then
				table.insert(toRemove, i)
			end
		end
	end

	-- Remove marked instances
	for i = #toRemove, 1, -1 do
		table.remove(instances, toRemove[i])
	end

	if (spawnCooldown <= 0) then
		spawnCooldown = cfg.spawnInterval

		-- Get player position, and randomize particles position based on bounding box
		local pos = entity.position()
		if cfg.boundingBox then
			pos = {
				pos[1] + cfg.boundingBox[1] * (0.5 - math.random()),
				pos[2] + cfg.boundingBox[2] * (0.5 - math.random())
			}
		end

		table.insert(instances, {
			text = SelectText(),
			index = 1,
			lastTime = 0,
			origin = pos,
			position = {pos[1], pos[2]}
		})
	else
		spawnCooldown = spawnCooldown - dt
	end

	-- Run controller chain of command
	for _, command in pairs(controllerChain) do command(dt) end
end

-- Gets overriden by another selection method on init. Treat it like a state.
function SelectText() end

function SelectOrdered()
	local str = cfg.texts[tid]

	if (cfg.loopOrderedText) then
		tid = tid % #cfg.texts
	elseif (tid >= #cfg.texts) then
		cfg.spawnInterval = 999999999
	end

	tid = tid + 1
	return str
end

function SelectRandom()
	return cfg.texts[math.random(1, #cfg.texts)]
end
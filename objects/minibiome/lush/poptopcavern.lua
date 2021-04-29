require "/scripts/util.lua"
require "/scripts/messageutil.lua"

function init()
	self.warnOnce={}

	storage.uuid = storage.uuid or sb.makeUuid()
	storage.tricorder = storage.tricorder or {}
	object.setInteractive(true)

	message.setHandler("onTeleport",
		function(message, isLocal, data)
			if not storage.vanishTime then
				storage.vanishTime = world.time() + config.getParameter("vanishTime")
			end
		end
	)
end

function update(dt)
	promises:update()

	local messagePlayers = world.playerQuery(object.position(), config.getParameter("tricorderCheckRange"))
	if messagePlayers then
		for _, playerId in pairs (messagePlayers) do
			promises:add(
				--world.sendEntityMessage(playerId, "fu_key", "statustablet"),
				world.sendEntityMessage(playerId, "player.hasCompletedQuest", "create_matterassembler"),
				function(successful)
					if world.entityUniqueId(playerId) then
						if successful then
							storage.tricorder[world.entityUniqueId(playerId)] = true
						else
							storage.tricorder[world.entityUniqueId(playerId)] = false
						end
					else
						if not self.warnOnce[playerId] then
							sb.logWarn("Poptop Cavern Door: Player with ID %s has no unique ID.",playerId)
							self.warnOnce[playerId]=true
						end
					end
				end,
				function()
					sb.logWarn("Poptop Cavern Door:  Either the player query is detecting some non-players or the message can't be received.")
				end
			)
		end
	end
end

function onInteraction(args)
	if args.sourceId and world.entityUniqueId(args.sourceId) and storage.tricorder[world.entityUniqueId(args.sourceId)] == true then
		if config.getParameter("returnDoor") then
			return { "OpenTeleportDialog",
				{
					canBookmark = false,
					includePlayerBookmarks = false,
					destinations = {{
						name = "Departure Radar",
						planetName = "Beam back...hopefully!",
						icon = "return",
						warpAction = "Return"
					}}
				}
			}
		--elseif  status.stat("gaterepair") then--player already completed the dungeon once. afterwards, they get a shittier version with less loot
		--	return { "OpenTeleportDialog",
		--		{
		--			canBookmark = false,
		--			includePlayerBookmarks = false,
		--			destinations = {{
		--				name = "^green;Dark Cavern^reset; (^orange;2^reset;)",
		--				planetName = "Dark Cavern",
		--				icon = "default",
		--				warpAction = string.format(config.getParameter("destination2"), storage.uuid, world.threatLevel())
		--			}}
		--		}
		--	}				
		else
			return { "OpenTeleportDialog",
				{
					canBookmark = false,
					includePlayerBookmarks = false,
					destinations = {{
						name = "^cyan;Dark Cavern^reset; (^orange;1^reset;)",
						planetName = "^green;Detected^reset;: Energy Source",
						icon = "default",
						warpAction = string.format(config.getParameter("destination"), storage.uuid, world.threatLevel())
					}}
				}
			}
		end
	else
		return {config.getParameter("noTricorderInteractAction"), config.getParameter("noTricorderInteractData")}
	end
end

local didInit=false
local origInit = init
local origUninit = uninit
local oldUpdate=update

function init(...)
	if origInit then
		origInit(...)
	end
	didInit=true
	sb.logInfo("----- FU player init -----")
	
	message.setHandler("fu_key", function(_, _, requiredItem)
		if player.hasItem(requiredItem) then
			return true
		end
		local essentialSlots = {"beamaxe", "wiretool", "painttool", "inspectiontool"}
		for _,slot in pairs (essentialSlots) do
			local essentialItem = player.essentialItem(slot)
			if essentialItem and essentialItem.name == requiredItem then
				return true
			end
		end
		return false
	end)
	if not status.statusProperty("fu_creationDate") then status.setStatusProperty("fu_creationDate",os.time()) end
	
	message.setHandler("player.isAdmin",player.isAdmin)
	message.setHandler("player.uniqueId",player.uniqueId)
	message.setHandler("player.worldId",player.worldId)
	message.setHandler("player.availableTechs", player.availableTechs)
	message.setHandler("player.enabledTechs", player.enabledTechs)
	message.setHandler("player.shipUpgrades", player.shipUpgrades)
	message.setHandler("player.isAdmin", player.isAdmin)
	message.setHandler("player.isLounging", player.isLounging)
	message.setHandler("player.loungingIn", player.loungingIn)
	message.setHandler("player.equippedItem",function (_,_,...) return player.equippedItem(...) end)
	message.setHandler("player.hasItem",function (_,_,...) return player.hasItem(...) end)
	message.setHandler("player.hasCountOfItem",function (_,_,...) return player.hasCountOfItem(...) end)
	
	message.setHandler("fu_specialAnimator.playAudio",function (_,_,...) localAnimator.playAudio(...) end)
	message.setHandler("fu_specialAnimator.spawnParticle",function (_,_,...) localAnimator.spawnParticle(...) end)
	
	--unfortunately, the game calls clearDrawables and clearLightSources every update so these aren't usable.
	--message.setHandler("fu_specialAnimator.addDrawable",function (_,_,...) localAnimator.addDrawable(...) end)
	--message.setHandler("fu_specialAnimator.clearDrawables",function (_,_,...) localAnimator.clearDrawables(...) end)
	--message.setHandler("fu_specialAnimator.addLightSource",function (_,_,...) localAnimator.addLightSource(...) end)
	--message.setHandler("fu_specialAnimator.clearLightSources",function (_,_,...) localAnimator.clearLightSources(...) end)
	
	--[[
	local goods = {"foodgoods", "medicalgoods", "electronicgoods", "militarygoods"}
	for _, g in ipairs(goods) do
		local amount = player.hasCountOfItem({name = g})
		if amount > 0 then
			player.consumeItem({name = g, count = amount})
			player.addCurrency("fu"..g, amount)
			
			sb.logInfo("converted %s '%s' into '%s' currency", amount, g, "fu"..g)
		end
	end
	--]]
end

function update(...)
	if oldUpdate then oldUpdate(...) end
	if didInit then
		if world.entityType(entity.id()) == "player" then --can't send radio messages to nonexistent entities. this is the case when players are loading in.
			local idiotitem=root.itemConfig("idiotitem") -- FR detection.
			if idiotitem then
				world.sendEntityMessage(entity.id(),"queueRadioMessage","fu_frdetectedmessage") -- tell them they're a grounded idiot.
				if (not world.getProperty("ship.fuel")) then
					queueWarp=true
				end
			end
			didInit=false
		end
	elseif queueWarp then
		player.warp("ownship")
		queueWarp=false
	end
end

function uninit(...)
	local untieredLootboxes = player.hasCountOfItem({name = "fu_lootbox", parameters = {}}, true)
	if untieredLootboxes and untieredLootboxes > 0 then
		local threatLevel = math.floor(world.threatLevel() + 0.5)
		if threatLevel < 1 then 
		  threatLevel = 1
		end
		for i = 1, untieredLootboxes do
			player.consumeItem({name = "fu_lootbox", parameters = {}}, true, true)
			player.giveItem({name = "fu_lootbox", parameters = {level = threatLevel}})
		end
	end
	if origUninit then
		origUninit(...)
	end
	
	status.setPersistentEffects("flightpower",{})--this should be removed after a month.
end



--[[

void localAnimator.playAudio(String soundKey, [int loops], [float volume])
	Immediately plays the specified sound, optionally with the specified loop count and volume.

void localAnimator.spawnParticle(Json particleConfig)
	Immediately spawns a particle with the specified configuration.

void localAnimator.addDrawable(Drawable drawable, [String renderLayer])
	Adds the specified drawable to the animator's list of drawables to be rendered. If a render layer is specified, this drawable will be drawn on that layer instead of the parent entity's render layer. Drawables set in this way are retained between script ticks and must be cleared manually using localAnimator.clearDrawables().

void localAnimator.clearDrawables()
	Clears the list of drawables to be rendered.

void localAnimator.addLightSource(Json lightSource)
	Adds the specified light source to the animator's list of light sources to be rendered. Light sources set in this way are retained between script ticks and must be cleared manually using localAnimator.clearLightSources(). The configuration object for the light source accepts the following keys:
    Vec2F position
    Color color
    [bool pointLight]
    [float pointBeam]
    [float beamAngle]
    [float beamAmbience]

void localAnimator.clearLightSources()
	Clears the list of light sources to be rendered. If the owner is a player, sets that player's camera to be centered on the position of the specified entity, or recenters the camera on the player's position if no entity id is specified.

]]
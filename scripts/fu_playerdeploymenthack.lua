local _init=init

function init()
	if _init then
		_init()
	end
	message.setHandler("player.isAdmin",player.isAdmin)
	message.setHandler("player.uniqueId",player.uniqueId)
	message.setHandler("player.worldId",player.worldId)
	message.setHandler("player.availableTechs", player.availableTechs)
	message.setHandler("player.enabledTechs", player.enabledTechs)
	message.setHandler("player.shipUpgrades", player.shipUpgrades)
	message.setHandler("player.shipUpgrades", player.shipUpgrades)
	message.setHandler("player.equippedItem",function (_,_,...) return player.equippedItem(...) end)
	
	message.setHandler("fu_specialAnimator.playAudio",function (_,_,...) localAnimator.playAudio(...) end)
	message.setHandler("fu_specialAnimator.spawnParticle",function (_,_,...) localAnimator.spawnParticle(...) end)
	message.setHandler("fu_specialAnimator.addDrawable",function (_,_,...) localAnimator.addDrawable(...) end)
	message.setHandler("fu_specialAnimator.clearDrawables",function (_,_,...) localAnimator.clearDrawables(...) end)
	message.setHandler("fu_specialAnimator.addLightSource",function (_,_,...) localAnimator.addLightSource(...) end)
	message.setHandler("fu_specialAnimator.clearLightSources",function (_,_,...) localAnimator.clearLightSources(...) end)
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
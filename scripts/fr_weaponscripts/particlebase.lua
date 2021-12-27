--[[
local fuParticleBaseParticleFileCache
local fuParticleBaseParticleFileList={"/particles/cartoonstars/greencartoonstar.particle","/particles/cartoonstars/redcartoonstar.particle","/particles/sparkles/sparkle5.particle","/particles/charge.particle","/particles/healthcross.particle"}
--these should be defined in the script calling on this codebase
]]

function fuParticleBaseParticleBurst(self,particleEmitterList)
	local lists=self.fuParticleBaseParticleLists
	if lists then
		for _,particleEmitterId in pairs(particleEmitterList) do
			--check if animation data has the particle emitter. if so, pew.
			if lists.particleEmitterList[particleEmitterId] then
				animator.burstParticleEmitter(particleEmitterId)
				break
			--if the particle emitter is missing, check base file and generate a pseudo emitter via localanimator in fu_player_init.
			elseif fuParticleBaseParticleFileCache and lists.particleEmitterBaseList[particleEmitterId] and lists.particleEmitterBaseList[particleEmitterId].particles then
				for _,p in pairs(lists.particleEmitterBaseList[particleEmitterId].particles) do
					if ((type(p)=="table") and p.particle) and fuParticleBaseParticleFileCache[p.particle] then
						local fartbox
						--path={id=data}
						for _,data in pairs(fuParticleBaseParticleFileCache[p.particle]) do
							fartbox=copy(data)
							break
						end
						if fartbox then
							fartbox.position=entity.position()
							world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",fartbox)
						end
					end
				end
				break
			end
		end
	end
end

function fuParticleBaseLoadParticleData()
	local lists={}
	lists.particleEmitterList={}
	lists.particleEmitterBaseList={}

	local baseShieldAnimationData=root.assetJson("/items/active/shields/shield.animation")
	if baseShieldAnimationData and baseShieldAnimationData.particleEmitters then
		for emitter,emitterData in pairs(baseShieldAnimationData.particleEmitters) do
			lists.particleEmitterBaseList[emitter]=emitterData
		end
	end

	local animationData=config.getParameter("animation")
	if type(animationData)=="string" and animationData:sub(1,1)=="/" then
		animationData=root.assetJson(animationData)
	elseif type(animationData)=="string" then
		if world.entityType(activeItem.ownerEntityId()) then
			local buffer=world.entityHandItem(activeItem.ownerEntityId(),activeItem.hand())
			buffer=root.itemConfig(buffer).directory..animationData
			animationData=root.assetJson(buffer)
		else
			return
		end
	else
		animationData=nil
	end
	if animationData and animationData.particleEmitters then
		for emitter,_ in pairs(animationData.particleEmitters) do
			lists.particleEmitterList[emitter]=true
		end
	end

	local animationCustom=config.getParameter("animationCustom")
	if animationCustom and animationCustom.particleEmitters then
		for emitter,_ in pairs(animationCustom.particleEmitters) do
			lists.particleEmitterList[emitter]=true
		end
	end

	return lists
end

function fuParticleBaseLoadCache(self,filelist)
	if not self.fuParticleBaseParticleFileCache then
		self.fuParticleBaseParticleFileCache={}
	end
	for _,filepath in pairs(filelist) do
		if not self.fuParticleBaseParticleFileCache[filepath] then
			local buffer=root.assetJson(filepath)
			if buffer.kind then
				local fart={}
				fart[buffer.kind]=buffer.definition
				self.fuParticleBaseParticleFileCache[filepath]=fart
			end
		end
	end
end

function fuParticleBaseLoadLists(self)
	if not self.fuParticleBaseParticleLists then
		self.fuParticleBaseParticleLists=fuParticleBaseLoadParticleData()
	end
end
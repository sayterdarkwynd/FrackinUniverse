fuPersistentEffectRecorder={}

fuPersistentEffectRecorder.init=function()
	--deserializes if storage is available, otherwise
	if storage then
		if not storage.fuPersistentEffectRecorder then
			storage.fuPersistentEffectRecorder={data={}}
		end
		if storage.armorSetData then
			storage.fuPersistentEffectRecorder.data=storage.armorSetData
			storage.armorSetData=nil
		end
		fuPersistentEffectRecorder.data=storage.fuPersistentEffectRecorder.data
	else
		fuPersistentEffectRecorder.data=status.statusProperty("fuPersistentEffectRecorder") or {}
	end
	message.setHandler("recordFUPersistentEffect",function(_,_,setName) fuPersistentEffectRecorder.record(setName) end)
end

fuPersistentEffectRecorder.update=function(dt)
	if fuPersistentEffectRecorder.timer and fuPersistentEffectRecorder.timer >= 1.0 then
		fuPersistentEffectRecorder.timer=0.0
		local t=os.time()
		for set,bd in pairs(fuPersistentEffectRecorder.data) do
			if math.abs(t-bd)>1.0 then
				status.clearPersistentEffects(set)
				fuPersistentEffectRecorder.data[set]=nil
			end
		end
	else
		fuPersistentEffectRecorder.timer=(fuPersistentEffectRecorder.timer or -1.0)+dt
	end
end

fuPersistentEffectRecorder.uninit=function()
	if not storage then
		status.setStatusProperty("fuPersistentEffectRecorder",fuPersistentEffectRecorder.data)
	end
end

fuPersistentEffectRecorder.record=function(effectId)
	--sb.logInfo("recording effect on ID %s: %s",entity.id(),effectId)
	fuPersistentEffectRecorder.data[effectId]=os.time()
end
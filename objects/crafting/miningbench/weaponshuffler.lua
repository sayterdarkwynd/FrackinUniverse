require "/scripts/util.lua"

function init()
	message.setHandler("doShuffle",doShuffle)
	doAnims()
end

function update(dt)
	if storage.output or storage.input then
		storage.craftTimer=math.max(0,(storage.craftTimer or 3.0)-dt)
		if storage.craftTimer<=0 then
			if storage.output then
				local throw=world.containerPutItemsAt(entity.id(),storage.output,0)
				if throw then throw=world.containerPutItemsAt(entity.id(),throw,1) end
				if throw then world.spawnItem(throw,entity.position()) end
			else
				local throw=world.containerPutItemsAt(entity.id(),storage.input,0)
				if throw then throw=world.containerPutItemsAt(entity.id(),throw,1) end
				if throw then world.spawnItem(throw,entity.position()) end
			end
			storage.output=nil
			storage.input=nil
			storage.input2=nil
			doAnims()
		end
	end
end

function doShuffle()
	local item1=world.containerItemAt(entity.id(),0)
	local item2=world.containerItemAt(entity.id(),1)
	if (not item1) or (not item2) then return end
	if (item2.name~="upgrademodule") and (item1.name~="upgrademodule") then return end
	local inputModule
	local rngWeapon
	item1.count=1
	item2.count=1
	if item1.name~="upgrademodule" then
		if not item1.parameters.seed then
			return
		else
			rngWeapon=item1
			inputModule=item2
		end
	else
		if not item2.parameters.seed then
			return
		else
			rngWeapon=item2
			inputModule=item1
		end
	end
	world.containerConsume(entity.id(),item1)
	world.containerConsume(entity.id(),item2)
	storage.input2 = inputModule
	storage.input = rngWeapon
	if not storage.input then return end

	if storage.input.parameters.seed then
		local randoItem=root.createItem(storage.input.name,storage.input.parameters.level or l,math.abs(sb.staticRandomI32(storage.input.parameters.seed or os.time())))
		storage.output=randoItem
	end
	storage.craftTimer=3.0
	doAnims()
end

function uninit()
	if storage.input then
		world.spawnItem(storage.input,entity.position())
		storage.input=nil
	end
	if storage.input2 then
		world.spawnItem(storage.input2,entity.position())
		storage.input2=nil
	end
end

function doAnims()
	if storage.craftTimer and storage.craftTimer>0 then
		animator.setAnimationState("centrifuge","working")
	else
		animator.setAnimationState("centrifuge","idle")
	end
end
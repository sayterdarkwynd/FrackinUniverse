local recipes = {}

function init()
	storage.timer = storage.timer or 1
	self.mintick = 1
	self.inputStart=config.getParameter("inputSlotsStart") or 0
	self.inputEnd=math.max(self.inputStart,config.getParameter("inputSlotsEnd") or 2)
	self.outputStart=config.getParameter("outputSlotsStart") or 3
	self.outputEnd=config.getParameter("outputSlotsEnd") or -1
	if (self.outputEnd<self.outputStart) then
		self.outputEnd = world.containerSize(entity.id())
	end
	storage.crafting = storage.crafting or false
	storage.output = storage.output or {}
	storage.inputs = storage.inputs or {}
	animator.setAnimationState("samplingarrayanim", storage.crafting and "working" or "idle")
	recipes=config.getParameter("recipes") or {}
end

function getInputContents()
	local id = entity.id()

	local contents = {}
	for i=self.inputStart,self.inputEnd do
		local stack = world.containerItemAt(id, i)
		if stack ~=nil then
			if contents[stack.name] ~= nil then
				contents[stack.name] = contents[stack.name] + stack.count
			else
				contents[stack.name] = stack.count
			end
		end
	end

	return contents
end

function map(l,f)
	local res = {}
	for k,v in pairs(l) do
		res[k] = f(v)
	end
	return res
end

function filter(l,f)
	return map(l, function(e) return f(e) and e or nil end)
end

function getValidRecipes(query)

	local function subset(t1,t2)
		if next(t2) == nil then
			return false
		end
		if t1 == t2 then
			return true
		end
			for k,_ in pairs(t1) do
				if not t2[k] or t1[k] > t2[k] then
					return false
				end
			end
		return true
	end

	return filter(recipes, function(l) return subset(l.inputs, query) end)

end

function getOutSlotsFor(something)
	local empty = {} -- empty slots in the outputs
	local slots = {} -- slots with a stack of "something"
	if self.outputEnd == nil then
		self.outputEnd = world.containerSize(entity.id())
	end
	for i = self.outputStart,self.outputEnd do -- iterate all output slots
		local stack = world.containerItemAt(entity.id(), i) -- get the stack on i
		if stack ~= nil then -- not empty
			if stack.name == something then -- its "something"
				-- possible drop slot
				slots[#slots+1]=i
			end
		else -- empty
			empty[#empty+1]=i
		end
	end

	for _,e in pairs(empty) do -- add empty slots to the end
		slots[#slots+1]=e
	end
	return slots
end

function throwItemIn(item,isOutput)
	if isOutput then
		local possibleSlots=getOutSlotsFor(item.name)
		for _,slot in pairs(possibleSlots) do
			if item then
				item=world.containerPutItemsAt(entity.id(), item, slot)
			else
				break
			end
		end
	else
		item=world.containerStackItems(entity.id(), item)
	end
	if item ~= nil then
		world.spawnItem(item.name, entity.position(), item.count)
	end
end

function giveItems(items,isOutput)
	if #items>0 then
		for i,item in pairs(items) do
			throwItemIn(item,isOutput)
		end
	end
end

function refund()
	giveItems(storage.inputs)
	storage.inputs={}
end

function die(smash)
	refund()
end

function update(dt)
	storage.timer = storage.timer - dt
	if storage.timer <= 0 then
		if storage.crafting then
			giveItems(storage.output,true)
			storage.crafting = false
			storage.output = {}
			storage.inputs = {}
			storage.timer = self.mintick --reset timer to a safe minimum
			animator.setAnimationState("samplingarrayanim", storage.crafting and "working" or "idle")
			animator.playSound("active")
		end

		if not storage.crafting and storage.timer <= 0 then --make sure we didn't just finish crafting
			if not startCrafting(getValidRecipes(getInputContents())) then storage.timer = self.mintick end --set timeout if there were no recipes
		end
	end
end

function startCrafting(result)
	if next(result) == nil then return false
	else _,result = next(result)
		for k,v in pairs(result.inputs) do
			if not world.containerConsume(entity.id(), {item = k , count = v}) then
				--honestly this should never fire, but...just in case.
				refund()
				return false
			else
				storage.inputs[#storage.inputs+1]={item = k , count = v}
			end
		end

		storage.crafting = true
		storage.timer = result.time
		for name,quantity in pairs(result.outputs) do
			storage.output[#storage.output+1]={name=name,count=quantity}
		end
		animator.setAnimationState("samplingarrayanim", storage.crafting and "working" or "idle")
		return true
	end
end

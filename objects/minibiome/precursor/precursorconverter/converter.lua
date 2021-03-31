require "/scripts/kheAA/transferUtil.lua"

local recipes = {}

function init()
	recipes = config.getParameter("recipeTable")
	storage.timer = 1
	self.mintick = 1
	storage.crafting = storage.crafting or false
	storage.output = storage.output or {}
	storage.inputs = storage.inputs or {}
end

function getInputContents()
	local id = entity.id()

	local contents = {}
	for i=0,1 do
			local stack = world.containerItemAt(entity.id(),i)
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

		for i = 2, 10 do -- iterate all output slots
			local stack = world.containerItemAt(entity.id(), i) -- get the stack on i
			if stack ~= nil then -- not empty
				if stack.name == something then -- its "something"
						table.insert(slots,i) -- possible drop slot
				end
			else -- empty
					table.insert(empty, i)
			end
		end

		for _,e in pairs(empty) do -- add empty slots to the end
			table.insert(slots,e)
		end
		return slots
end


function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	storage.timer = storage.timer - dt

	if storage.timer <= 0 then
		if storage.crafting then
			for k,v in pairs(storage.output) do
				local leftover = {name = k, count = v}
				local slots = getOutSlotsFor(k)
				for _,i in pairs(slots) do
					leftover = world.containerPutItemsAt(entity.id(), leftover, i)
					if leftover == nil then
						break
					end
				end

				if leftover ~= nil then
					world.spawnItem(leftover.name, entity.position(), leftover.count)
				end
			end
			storage.crafting = false
			storage.output = nil
			storage.inputs = nil
			storage.timer = self.mintick --reset timer to a safe minimum
		end

		if not storage.crafting and storage.timer <= 0 then --make sure we didn't just finish crafting
			if not startCrafting(getValidRecipes(getInputContents())) then storage.timer = self.mintick end --set timeout if there were no recipes
		end
	end
	animator.setAnimationState("samplingarrayanim", storage.crafting and "working" or "idle")
end



function startCrafting(result)
	if next(result) == nil then return false
	else _,result = next(result)

		for k,v in pairs(result.inputs) do
			local buffer = {item = k , count = v}
			if world.containerConsume(entity.id(), buffer) then
				storage.inputs = {item = k , count = v}
			else
				return false
			end
		end

		storage.crafting = true
		storage.timer = result.time
		storage.output = result.outputs
		--animator.setAnimationState("samplingarrayanim", "working")

		return true
	end
end

function die()
	--safety for fringe cases
	if storage.inputs then
		world.spawnItem(storage.inputs,entity.position())
	end
	storage.inputs=nil
end
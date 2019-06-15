require "/scripts/kheAA/transferUtil.lua"

local recipes =
{

--liquids
{inputs = { solidfuel=100 }, outputs = { precursorgrease=1 }, time = 10.0},
{inputs = { liquidfuel=200 }, outputs = { precursorgrease=1 }, time = 10.0},
{inputs = { toxicwaste=100 }, outputs = { precursorgrease=1 }, time = 10.0},
{inputs = { irradiumbar=5 }, outputs = { precursorfluid=1 }, time = 40.0},
{inputs = { liquidirradium=25 }, outputs = { precursorfluid=1 }, time = 30.0},
{inputs = { supermatter=20 }, outputs = { precursorgel=2 }, time = 15.0},
{inputs = { neptuniumrod=30 }, outputs = { precursorfluid=1 }, time = 70.0},
{inputs = { thoriumrod=27 }, outputs = { precursorfluid=1 }, time = 60.0},
{inputs = { uraniumrod=25 }, outputs = { precursorfluid=1 }, time = 40.0},
{inputs = { plutoniumrod=22 }, outputs = { precursorfluid=1 }, time = 50.0},
{inputs = { enricheduranium=10 }, outputs = { precursorfluid=2 }, time = 30.0},
{inputs = { enrichedplutonium=8}, outputs = { precursorfluid=2 }, time = 30.0},
{inputs = { solariumstar=15 }, outputs = { precursorfluid=2 }, time = 30.0},
{inputs = { ultronium=1 }, outputs = { precursorfluid=5 }, time = 12.0},
{inputs = { precursorfluid=50 }, outputs = { essence=1 }, time = 20.0},
{inputs = { crunchychick=1 }, outputs = { essence=5 }, time = 10.0},
{inputs = { crunchychickdeluxe=1 }, outputs = { essence=50 }, time = 10.0},
{inputs = { crunchychickevil=1 }, outputs = { essence=100 }, time = 10.0}
-- should have precursor resources crafted here, too
}

function init()
    self.timer = 1
    self.mintick = 1
    self.crafting = false
    self.output = {}
	transferUtil.init()
end

function getInputContents()
        local id = entity.id()

        local contents = {}
        for i=0,2 do
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

    for i = 3, 11 do -- iterate all output slots
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
	if not deltaTime or (deltaTime > 1) then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
    self.timer = self.timer - dt
    if self.timer <= 0 then
        if self.crafting then
            for k,v in pairs(self.output) do
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
            self.crafting = false
            self.output = {}
            self.timer = self.mintick --reset timer to a safe minimum
            animator.setAnimationState("samplingarrayanim", "idle")
        end

        if not self.crafting and self.timer <= 0 then --make sure we didn't just finish crafting
            if not startCrafting(getValidRecipes(getInputContents())) then self.timer = self.mintick end --set timeout if there were no recipes
        end
    end
end



function startCrafting(result)
    if next(result) == nil then return false
    else _,result = next(result)

        for k,v in pairs(result.inputs) do
            if not world.containerConsume(entity.id(), {item = k , count = v}) then return false end
        end

        self.crafting = true
        self.timer = result.time
        self.output = result.outputs
        animator.setAnimationState("samplingarrayanim", "working")

        return true
    end
end

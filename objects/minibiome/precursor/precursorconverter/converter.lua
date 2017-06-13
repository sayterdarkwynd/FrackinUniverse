local recipes =
{

--liquids
{inputs = { solidfuel=50 }, outputs = { precursorfluid=1 }, time = 1.0},
{inputs = { liquidfuel=50 }, outputs = { precursorfluid=1 }, time = 1.0},
{inputs = { supermatter=50 }, outputs = { precursorfluid=2 }, time = 2.0},
{inputs = { uraniumrod=1 }, outputs = { precursorfluid=2 }, time = 2.0},
{inputs = { plutoniumrod=1 }, outputs = { precursorfluid=3 }, time = 3.0},
{inputs = { neptuniumrod=1 }, outputs = { precursorfluid=4 }, time = 4.0},
{inputs = { thoriumrod=1 }, outputs = { precursorfluid=5 }, time = 5.0},
{inputs = { solariumstar=6 }, outputs = { precursorfluid=6 }, time = 6.0},
{inputs = { ultronium=1 }, outputs = { precursorfluid=50 }, time = 6.0},
{inputs = { precursorfluid=50 }, outputs = { essence=400 }, time = 7.0},
{inputs = { techcard=1 }, outputs = { essence=4 }, time = 1.0},
{inputs = { upgrademodule=1 }, outputs = { essence=4 }, time = 1.0},
{inputs = { manipulatormodule=1 }, outputs = { essence=3 }, time = 1.0}
-- should have precursor resources crafted here, too
}

function init()
    self.timer = 1
    self.mintick = 1
    self.crafting = false
    self.output = {}
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

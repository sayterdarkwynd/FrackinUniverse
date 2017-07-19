local recipes =
{

--liquids
{inputs = { cthulureward=1,elderrelic7=1,elderrelic11=1 }, outputs = { elderripper=1 }, time = 15.0},
{inputs = { cthulureward=1, elderrelic5=1, elderrelic11=1 }, outputs = { eldercarbine=1 }, time = 15.0},
{inputs = { cthulureward=1, elderrelic12=1, elderrelic11=1 }, outputs = { elderpistol=1 }, time = 15.0 },
{inputs = { cthulureward=1, elderrelic6=1, elderrelic8=1 }, outputs = { elderrepeater=1 }, time = 15.0 },
{inputs = { eldertome=1,elderrelic7=1,elderrelic3=3 }, outputs = { elderspear=1 }, time = 15.0},
{inputs = { eldertome=1, elderrelic2=1, elderrelic3=5 }, outputs = { elderblade=1 }, time = 15.0},
{inputs = { elderrelic3=6, elderrelic5=2, elderrelic7=1 }, outputs = { elderbroadsword=1 }, time = 15.0 },
{inputs = { cthulureward=1, eldertome=1, elderrelic3=5 }, outputs = { elderbow=1 }, time = 15.0},
{inputs = { nocxiumbar=5, elderrelic2=1, elderrelic7=1 }, outputs = { elderwhip=1 }, time = 15.0 },
{inputs = { eldertome=1, elderrelic7=2, cthulureward=1 }, outputs = { cultiststaff1=1 }, time = 15.0 },
{inputs = { eldertome=1, elderrelic6=2, elderrelic9=1 }, outputs = { cultiststaff2=1 }, time = 15.0 },
{inputs = { eldertome=1, elderrelic12=2, elderrelic14=1 }, outputs = { cultiststaff3=1 }, time = 15.0 },
{inputs = { nocxiumbar=5, elderrelic6=1, elderrelic3=4 }, outputs = { elderaxe=1 }, time = 15.0 },
{inputs = { cthulureward=1, elderrelic8=1, elderrelic12=1 }, outputs = { eldergrappler=1 }, time = 15.0},
{inputs = { nocxiumbar=5, eldertome=1, elderrelic12=5 }, outputs = { eldershield=1 }, time = 15.0 },
{inputs = { nocxiumbar=6, elderrelic12=1, elderrelic6=1 }, outputs = { elderarmorhead=1 }, time = 15.0 },
{inputs = { nocxiumbar=7, elderrelic2=1, elderrelic14=1 }, outputs = { elderarmorchest=1 }, time = 15.0},
{inputs = { nocxiumbar=5, elderrelic1=1, elderrelic5=1 }, outputs = { elderarmorpants=1 }, time = 15.0 },
{inputs = { nocxiumbar=6, elderrelic6=1, elderrelic11=1 }, outputs = { cultarmorhead=1 }, time = 15.0 },
{inputs = { nocxiumbar=7, elderrelic7=1, elderrelic12=1 }, outputs = { cultarmorchest=1 }, time = 15.0 },
{inputs = { nocxiumbar=5, elderrelic8=1, elderrelic14=1 }, outputs = { cultarmorpants=1 }, time = 15.0 }
{inputs = { cthulureward=1, elderrelic3=2, elderrelic14=1 }, outputs = { eldermace=1 }, time = 15.0 }
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

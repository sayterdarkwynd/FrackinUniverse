local recipes =
{

--liquids
{inputs = { bottle=1,normalcomb=1 }, outputs = { honeyjar=1 }, time = 1.0},
{inputs = { bottle=1,arcticcomb=1 }, outputs = { snowhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,aridcomb=1 }, outputs = { stronghoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,coppercomb=1 }, outputs = { honeyjar=1 }, time = 1.0},
{inputs = { bottle=1,durasteelcomb=1 }, outputs = {shellhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,exceptionalcomb=1 }, outputs = { honeyjar=1,liquidwastewater=1 }, time = 1.0},
{inputs = { bottle=1,flowercomb=1 }, outputs = { floralhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,forestcomb=1 }, outputs = { greenhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,godlycomb=1 }, outputs = { mythicalhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,goldcomb=1 }, outputs = { speedhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,ironcomb=1 }, outputs = { shellhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,junglecomb=1 }, outputs = { greenhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,minercomb=1 }, outputs = { honeyjar=1 }, time = 1.0},
{inputs = { bottle=1,mooncomb=1 }, outputs = { honeyjar=1 }, time = 1.0},
{inputs = { bottle=1,morbidcomb=1 }, outputs = { redhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,mythicalcomb=1 }, outputs = { mythicalhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,nocturnalcomb=1 }, outputs = { nocturnalhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,plutoniumcomb=1 }, outputs = { plutoniumhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,preciouscomb=1 }, outputs = { honeyjar=1 }, time = 1.0},
{inputs = { bottle=1,radioactivecomb=1 }, outputs = { radioactivehoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,redcomb=1 }, outputs = { redhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,silvercomb=1 }, outputs = { shellhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,suncomb=1 }, outputs = { hothoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,solariumcomb=1 }, outputs = { solariumhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,titaniumcomb=1 }, outputs = { shellhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,tungstencomb=1 }, outputs = { shellhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,volcaniccomb=1 }, outputs = { hothoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,aegisaltcomb=1 }, outputs = { shellhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,feroziumcomb=1 }, outputs = { shellhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,violiumcomb=1 }, outputs = { shellhoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,liquidwater=1 }, outputs = { liquidwastewater=1 }, time = 1.0},
{inputs = { bottle=1,magmacomb=1 }, outputs = { hothoneyjar=1 }, time = 1.0},
{inputs = { bottle=1,eldercomb=1 }, outputs = { elderhoneyjar=1,liquidelderfluid=1 }, time = 1.0}
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
            animator.playSound("active")
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

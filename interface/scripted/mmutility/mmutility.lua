require "/scripts/util.lua"

function init()
    self.tools = {
        wiretoolSlot = "wiretool",
        painttoolSlot = "painttool",
        inspectiontoolSlot = "inspectiontool"
    }

    -- Used for upgrade checking on status changes (range specifically)
    self.upgrades = root.assetJson("/interface/scripted/mmupgrade/mmupgradegui.config").upgrades
    if not self.upgrades then
        self.upgrades = root.assetJson("/interface/scripted/mmupgrade/mmupgradegui.original.config").upgrades
    end

    -- FR compatibility (uses racial manipulator as base manipulator)
    _,self.racial = pcall(function (f) return root.assetJson("/frackinraces.config").manipulators end)

    self.currentMM = player.essentialItem("beamaxe")
    self.maxSize = getMaxSize(self.currentMM)

    resetSlots()
    resetSpinners()
    setSpinnersEnabled()
end

function update(dt)
    resetSlots()
end

function swapMM(name)
    local swapItem = player.swapSlotItem()

    -- Ignore invalid swaps
    if not swapItem and self.currentMM.name == getBaseManip() then return end
    if swapItem and root.itemType(swapItem.name) ~= "beamminingtool" then return end

    -- Reset stats for picked up item (or for the base MM getting stored for later)
    self.currentMM.parameters.blockRadius = self.maxSize
    self.currentMM.parameters.altBlockRadius = 1
    if self.currentMM.parameters.upgrades and contains(self.currentMM.parameters.upgrades, "liquidcollection") then
        self.currentMM.parameters.canCollectLiquid = true
    end

    local currentlyBase = self.currentMM.name == getBaseManip()

    -- If taking out, set swap to original MM. If swapping two items, set the original MM data
    if not swapItem then
        swapItem = self.currentMM.parameters.originalMM or root.createItem(getBaseManip())
    else
        swapItem.parameters.originalMM = currentlyBase and self.currentMM or self.currentMM.parameters.originalMM
    end

    paintSizeCap(getMaxSize(swapItem)+1)

    -- Set the bonus radius to that of the new MM
    status.setStatusProperty("bonusBeamGunRadius", (root.itemConfig(mm).config.rangeBonus or 0)+getStatBonus(mm, "bonusBeamGunRadius"))

    -- Transfer wiremode and paintmode upgrades (as they should be permanent)
    -- Also handles granting of the liquidcollection upgrade if it is enabled by default on the new MM
    upgradeTransfer(self.currentMM, swapItem)

    -- Cleanup
    self.currentMM.parameters.originalMM = nil
    player.setSwapSlotItem(not currentlyBase and self.currentMM or nil)
    self.currentMM = swapItem
    updateMM()
end

function swapTool(name)
    local tool = self.tools[name]
    local toolItem = player.essentialItem(tool)
    local swapItem = player.swapSlotItem()
    local mmupgrade = {
        wiretool = "wiremode",
        painttool = "paintmode"
    }
    if (not toolItem) then sb.logError("mmutility.lua: Could not swap tool. tool=%s,toolItem=%s,swapItem=%s. You may need to use console commands to fix your tool slot.",tool,toolItem,swapItem) return end
	if (not swapItem and toolItem.name == origTool(tool)) then return end

    if tool == "inspectiontool" and toolItem.name == "inspectionmode" then return end
    if tool ~= "inspectiontool" and not (self.currentMM.parameters.upgrades and contains(self.currentMM.parameters.upgrades, mmupgrade[tool])) then return end

    if not swapItem then
        swapItem = toolItem.parameters.originalMM or root.createItem(origTool(tool))
    elseif toolItem.name == origTool(tool) then
        swapItem.parameters.originalMM = toolItem
    else
        swapItem.parameters.originalMM = toolItem.parameters.originalMM
    end
    toolItem.parameters.originalMM = nil
    player.setSwapSlotItem(toolItem.name ~= origTool(tool) and toolItem or nil)
    player.giveEssentialItem(tool, swapItem)
    widget.setItemSlotItem(name, swapItem)
    paintSizeCap(self.maxSize+1)

    resetSpinners()
    setSpinnersEnabled()
end

function paintSizeCap(size)
    local paint = player.essentialItem("painttool")
    local replace = false
    if not paint or root.itemType(paint.name) ~= "paintingbeamtool" then return end
    if getStat(paint, "blockRadius") > size then
        paint.parameters.blockRadius = size
        replace = true
    end
    if getStat(paint, "altBlockRadius") > size then
        paint.parameters.altBlockRadius = size
        replace = true
    end
    if replace then
        player.giveEssentialItem("painttool", paint)
    end
end

-- Returns the item ID of the player's base tool in the given slot
function origTool(slot)
    if slot == "wiretool" or slot == "painttool" then
        return slot
    elseif slot == "inspectiontool" then
        return "scanmode"
    elseif slot == "beamaxe" then
        return getBaseManip()
    end
end

-- Returns the item ID of the player's base MM
function getBaseManip()
    if self.racial and self.racial[player.species()] then
        return self.racial[player.species()].item or "beamaxe"
    end
    return "beamaxe"
end

function resetSlots()
    local mm = player.essentialItem("beamaxe")

    widget.setItemSlotItem("beamaxeSlot", mm)
    widget.setItemSlotItem("wiretoolSlot", player.essentialItem("wiretool"))
    widget.setItemSlotItem("painttoolSlot", player.essentialItem("painttool"))
    widget.setItemSlotItem("inspectiontoolSlot", player.essentialItem("inspectiontool"))

    -- Update the UI if the upgrades have changed
    if mm.parameters.upgrades then
        if not self.currentMM.parameters.upgrades or #mm.parameters.upgrades ~= #self.currentMM.parameters.upgrades then
            self.currentMM = mm
            self.maxSize = getMaxSize(self.currentMM)
            resetSpinners()
            setSpinnersEnabled()
        end
    end
    self.currentMM = mm
end

function resetSpinners()
    widget.setText("sizeSpinnerLB", self.currentMM.parameters.blockRadius or root.itemConfig(self.currentMM).config.blockRadius)
    widget.setText("altSizeSpinnerLB", self.currentMM.parameters.altBlockRadius or root.itemConfig(self.currentMM).config.altBlockRadius)

    local hasUpgrade = contains(self.currentMM.parameters.upgrades or {}, "liquidcollection")
    widget.setFontColor("collectLiquidsLabel", hasUpgrade and "green" or "darkgray")
    widget.setButtonEnabled("collectLiquidsCheckbox", hasUpgrade)
    widget.setChecked("collectLiquidsCheckbox", getStat(self.currentMM, "canCollectLiquid"))

    local paint = player.essentialItem("painttool")
    if paint and paint.name == "painttool" then
        widget.setText("paintSizeSpinnerLB", getStat(paint, "blockRadius"))
        widget.setText("altPaintSizeSpinnerLB", getStat(paint, "altBlockRadius"))
    else
        widget.setText("paintSizeSpinnerLB", "0")
        widget.setText("altPaintSizeSpinnerLB", "0")
    end
end

function setSpinnersEnabled()
    widget.setButtonEnabled("sizeSpinner.up", getStat(self.currentMM, "blockRadius") < self.maxSize)
    widget.setButtonEnabled("altSizeSpinner.up", getStat(self.currentMM, "altBlockRadius") < self.maxSize)
    widget.setButtonEnabled("sizeSpinner.down", getStat(self.currentMM, "blockRadius") > 1)
    widget.setButtonEnabled("altSizeSpinner.down", getStat(self.currentMM, "altBlockRadius") > 1)

    --widget.setChecked("collectBlocksCheckbox", getStat(mm, "harvestLevel") == 99)

    local paint = player.essentialItem("painttool")
    if not paint or paint.name ~= "painttool" then
        widget.setFontColor("paintSizeLabel", "darkgray")
        widget.setFontColor("paintSizeSpinnerLB", "darkgray")
        widget.setFontColor("altPaintSizeLabel", "darkgray")
        widget.setFontColor("altPaintSizeSpinnerLB", "darkgray")
        widget.setButtonEnabled("paintSizeSpinner.up", false)
        widget.setButtonEnabled("paintSizeSpinner.down", false)
        widget.setButtonEnabled("altPaintSizeSpinner.up", false)
        widget.setButtonEnabled("altPaintSizeSpinner.down", false)
    else
        widget.setFontColor("paintSizeLabel", "green")
        widget.setFontColor("paintSizeSpinnerLB", "green")
        widget.setFontColor("altPaintSizeLabel", "green")
        widget.setFontColor("altPaintSizeSpinnerLB", "green")
        widget.setButtonEnabled("paintSizeSpinner.up", getStat(paint, "blockRadius") < self.maxSize + 1)
        widget.setButtonEnabled("paintSizeSpinner.down", getStat(paint, "blockRadius") > 1)
        widget.setButtonEnabled("altPaintSizeSpinner.up", getStat(paint, "altBlockRadius") < self.maxSize + 1)
        widget.setButtonEnabled("altPaintSizeSpinner.down", getStat(paint, "altBlockRadius") > 1)
    end

    widget.setVisible("wiretoolLocked", not contains(self.currentMM.parameters.upgrades or {}, "wiremode"))
    widget.setVisible("painttoolLocked", not contains(self.currentMM.parameters.upgrades or {}, "paintmode"))
    widget.setVisible("inspectiontoolLocked", (player.essentialItem("inspectiontool") or {}).name == "inspectionmode")
end

function upgradeTransfer(mm1, mm2)
    mm2.parameters.upgrades = mm2.parameters.upgrades or {}
    if contains(mm1.parameters.upgrades or {}, "wiremode")
        and not contains(mm2.parameters.upgrades, "wiremode") then
        table.insert(mm2.parameters.upgrades, "wiremode")
    end
    if contains(mm1.parameters.upgrades or {}, "paintmode")
        and not contains(mm2.parameters.upgrades, "paintmode") then
        table.insert(mm2.parameters.upgrades, "paintmode")
    end
    if root.itemConfig(mm2).config.canCollectLiquid and not contains(mm2.parameters.upgrades or {}, "liquidcollection") then
        table.insert(mm2.parameters.upgrades, "liquidcollection")
    end
    if #mm2.parameters.upgrades == 0 then mm2.parameters.upgrades = nil end
end

-- Returns the current maximum size of this MM
function getMaxSize(mm)
    local mmSize = root.itemConfig(mm).config.blockRadius
    local baseSize = root.itemConfig("beamaxe").config.blockRadius

    -- New formula, not name-sensitive and only loops once!
    if mm.parameters.upgrades then
        local i = #getStat(mm, "upgrades")
        while i >= 1 do
            local up = self.upgrades[mm.parameters.upgrades[i]]
            if up.setItemParameters and up.setItemParameters.blockRadius then
                return mmSize - baseSize + up.setItemParameters.blockRadius
            end
            i = i - 1
        end
    end

    return mmSize
end

-- Returns the real stat of the item
function getStat(item, stat)
    if item.parameters[stat] ~= nil then
        return item.parameters[stat]
    else
        return root.itemConfig(item).config[stat]
    end
end

-- Returns the most recent status property upgrade on the MM
function getStatBonus(mm, bonus)
    if mm and mm.parameters.upgrades then
        local i = #getStat(mm, "upgrades")
        while i >= 1 do
            local up = self.upgrades[mm.parameters.upgrades[i]]
            if up.setStatusProperties and up.setStatusProperties[bonus] then
                return up.setStatusProperties[bonus]
            end
            i = i - 1
        end
    end
    return 0
end

-- Updates the UI and replaces the MM
function updateMM()
    player.giveEssentialItem("beamaxe", self.currentMM)
    self.maxSize = getMaxSize(self.currentMM)
    resetSpinners()
    setSpinnersEnabled()
end

sizeSpinner = {}
function sizeSpinner.up()
    if getStat(self.currentMM, "blockRadius") < self.maxSize then
        self.currentMM.parameters.blockRadius = getStat(self.currentMM, "blockRadius") + 1
        updateMM()
    end
end
function sizeSpinner.down()
    if getStat(self.currentMM, "blockRadius") > 1 then
        self.currentMM.parameters.blockRadius = getStat(self.currentMM, "blockRadius") - 1
        updateMM()
    end
end

altSizeSpinner = {}
function altSizeSpinner.up()
    if getStat(self.currentMM, "altBlockRadius") < self.maxSize then
        self.currentMM.parameters.altBlockRadius = getStat(self.currentMM, "altBlockRadius") + 1
        updateMM()
    end
end
function altSizeSpinner.down()
    if getStat(self.currentMM, "altBlockRadius") > 1 then
        self.currentMM.parameters.altBlockRadius = getStat(self.currentMM, "altBlockRadius") - 1
        updateMM()
    end
end

paintSizeSpinner = {}
function paintSizeSpinner.up()
    local paint = player.essentialItem("painttool")
    if not paint or root.itemType(paint.name) ~= "paintingbeamtool" then return end
    if getStat(paint, "blockRadius") < self.maxSize + 1 then
        paint.parameters.blockRadius = getStat(paint, "blockRadius") + 1
        player.giveEssentialItem("painttool", paint)
        resetSpinners()
        setSpinnersEnabled()
    end
end
function paintSizeSpinner.down()
    local paint = player.essentialItem("painttool")
    if not paint or root.itemType(paint.name) ~= "paintingbeamtool" then return end
    if getStat(paint, "blockRadius") > 1 then
        paint.parameters.blockRadius = getStat(paint, "blockRadius") - 1
        player.giveEssentialItem("painttool", paint)
        resetSpinners()
        setSpinnersEnabled()
    end
end

altPaintSizeSpinner = {}
function altPaintSizeSpinner.up()
    local paint = player.essentialItem("painttool")
    if not paint or root.itemType(paint.name) ~= "paintingbeamtool" then return end
    if getStat(paint, "altBlockRadius") < self.maxSize + 1 then
        paint.parameters.altBlockRadius = getStat(paint, "altBlockRadius") + 1
        player.giveEssentialItem("painttool", paint)
        resetSpinners()
        setSpinnersEnabled()
    end
end
function altPaintSizeSpinner.down()
    local paint = player.essentialItem("painttool")
    if not paint or root.itemType(paint.name) ~= "paintingbeamtool" then return end
    if getStat(paint, "altBlockRadius") > 1 then
        paint.parameters.altBlockRadius = getStat(paint, "altBlockRadius") - 1
        player.giveEssentialItem("painttool", paint)
        resetSpinners()
        setSpinnersEnabled()
    end
end

function liquidsCheckbox(name)
    local checked = widget.getChecked(name)
    if self.currentMM.parameters.upgrades and contains(self.currentMM.parameters.upgrades, "liquidcollection") then
        self.currentMM.parameters.canCollectLiquid = checked
        updateMM()
    end
end

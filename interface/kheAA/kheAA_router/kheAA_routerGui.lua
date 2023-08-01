local inputList = "inputSlotScrollArea.inputSlotList";
local outputList = "outputSlotScrollArea.outputSlotList";
local filterFunctionsLabelDefault = "Functions: ^yellow;Use these to help divide outputs for automation.^reset;"
local helpMode=false

local buttonNames={
	evenSplit="roundRobinMode",
	slotSplit="roundRobinSlotMode",
	leaveOne="leaveOneItemMode",
	onlyStack="onlyStackMode"
}

buttons = {
	invertButtons = {
		item1ButtonInvert = 1,
		item2ButtonInvert = 2,
		item3ButtonInvert = 3,
		item4ButtonInvert = 4,
		item5ButtonInvert = 5
	}
}

function init()
	inputSlots = {};
	outputSlots = {};
	if filterInverted == nil then
		filterInverted={}
		filterInverted[1]=true
		for i=2,5 do
			filterInverted[i]=false;
		end
	end
	if filterType == nil then
		filterType={};
		filterType[1]=true
		for i=2,5 do
			filterType[i]=-1;
		end
	end
	if invertSlots==nil then invertSlots={false,false} end
	initialized = nil;
end

function initialize(conf)
	inputSlots={}
	for k,v in pairs(conf[1] or {}) do
		inputSlots[k]={v,"-1"}
	end
	for k,v in pairs(conf[2] or {}) do
		outputSlots[k]={v,"-1"}
	end
	filterInverted=conf[3]
	filterType=conf[4]
	invertSlots=conf[5]
	--round robin slots and only stack are mutually exclusive because spaghetti mess
	if conf[7] and conf[9] then conf[9]=false end
	widget.setChecked(buttonNames.evenSplit, conf[6])
	widget.setChecked(buttonNames.slotSplit, conf[7])
	widget.setChecked(buttonNames.leaveOne, conf[8])
	widget.setChecked(buttonNames.onlyStack, conf[9])
	redrawListSlots(inputList, inputSlots);
	redrawListSlots(outputList, outputSlots);
	redrawItemFilters()
	redrawInvertButtons()
	redrawInvertSlotButtons()
end

function update()
	if initialized==nil then
		myBox=pane.containerEntityId()
		position=world.entityPosition(myBox);
		promise = world.sendEntityMessage(myBox, "sendConfig")
		initialized=false
		return
	end
	if not initialized then
		if promise:finished() and promise:succeeded() then
			initialize(promise:result())
			initialized = true;
			widget.setText("filterFunctionsLabel",filterFunctionsLabelDefault)
			widget.setText("filterFunctionsLabel2","")
		elseif promise:finished() and not promise:succeeded() then
			promise = world.sendEntityMessage(myBox, "sendConfig")
		end
		return;
	end
end

function addInputSlot()
	if helpMode then
		widget.setText("filterFunctionsLabel2","Left '^green;+^reset;': adds an item from the input slot filter list.")
		widget.setText("filterFunctionsLabel","This is the list for the source.")
		return
	end
	addListSlot("inputSlotCount", inputList, inputSlots, "setInputSlots")
end

function addOutputSlot()
	if helpMode then
		widget.setText("filterFunctionsLabel2","Right '^green;+^reset;': adds an item from the output slot filter list.")
		widget.setText("filterFunctionsLabel","This is the list for the destination.")
		return
	end
	addListSlot("outputSlotCount", outputList, outputSlots, "setOutputSlots")
end

function addListSlot(label, list, slots, notify)
	local text = widget.getText(label)
	if text ~= "" then
		local slot = tonumber(text);
		widget.setText(label, slot + 1);
		for _,v in pairs(slots) do
			if v[1] == slot then
				return;
			end
		end
		local item = widget.addListItem(list);
		widget.setText(list .. "." .. item .. ".slotNr", slot .. "");
		table.insert(slots, {slot, item})
		syncListSlots(slots, notify)
	end
end

function subInputSlot()
	if helpMode then
		widget.setText("filterFunctionsLabel2","Left '^red;-^reset;': Removes an item from the intput slot filter list.")
		widget.setText("filterFunctionsLabel","")
		return
	end
	subFromListSlots(inputList, inputSlots, "setInputSlots");
end

function subOutputSlot()
	if helpMode then
		widget.setText("filterFunctionsLabel2","Right '^red;-^reset;': Removes an item from the output slot filter list.")
		widget.setText("filterFunctionsLabel","")
		return
	end
  subFromListSlots(outputList, outputSlots, "setOutputSlots");
end

function subFromListSlots(list, slots, notify)
	local item = widget.getListSelected(list)
	if item then
		for k,v in pairs(slots) do
			if v[2] == item then
				table.remove(slots, k)
				syncListSlots(slots, notify);
				redrawListSlots(list, slots);
				remaining = #slots;
				if remaining == 0 then
				elseif k >= remaining then
					widget.setListSelected(list, slots[remaining][2]);
				else
					widget.setListSelected(list, slots[k][2]);
				end
				return;
			end
		end
	end
end

function redrawListSlots(list, slots)
	widget.clearListItems(list)
	for _,v in pairs(slots) do
		local item = widget.addListItem(list);
		widget.setText(list .. "." .. item .. ".slotNr", v[1] .. "");
		v[2] = item;
	end
end

function syncListSlots(slots, notify)
	local temp={}
	for _,v in pairs(slots) do
		table.insert(temp,v[1])
	end
	world.sendEntityMessage(myBox, notify, temp);
end

function redrawItemFilters()
	for i=1,5 do
		widget.setSelectedOption("item"..i.."Filter",filterType[i])
	end
end

function invSlots()
	if helpMode then
		widget.setText("filterFunctionsLabel2","'I' buttons: Inverts slot filter selection for a given side.")
		widget.setText("filterFunctionsLabel","")
		return
	end
	if not initialized then return end
	invertSlots[1]=widget.getChecked("invInputSlot")
	invertSlots[2]=widget.getChecked("invOutputSlot")
	world.sendEntityMessage(myBox, "setInvertSlots", invertSlots);
end

function redrawInvertButtons()
	for name,i in pairs(buttons.invertButtons) do
		widget.setChecked(name,filterInverted[i])
	end
end

function redrawInvertSlotButtons()
	widget.setChecked("invInputSlot",invertSlots[1])
	widget.setChecked("invOutputSlot",invertSlots[2])
end

function help()
	helpMode=not helpMode
	if helpMode then
		widget.setText("filterFunctionsLabel","^green;Click a button for information^reset;")
		widget.setButtonImages("help",{base = "/interface/inspect.png?scanlines=5555AACC;0.4;5555FFCC;0.4?scalenearest=0.75",hover = "/interface/inspecthover.png?scanlines=5555AACC;0.4;5555FFCC;0.4?scalenearest=0.75",pressed = "/interface/inspecthover.png?scanlines=5555AACC;0.4;5555FFCC;0.4?scalenearest=0.75"})
	else
		widget.setButtonImages("help",{base = "/interface/inspect.png?scalenearest=0.75",hover = "/interface/inspecthover.png?scalenearest=0.75",pressed = "/interface/inspecthover.png?scalenearest=0.75"})
		widget.setText("filterFunctionsLabel","")
		widget.setText("filterFunctionsLabel2","")
		init()
	end
end

function itemFilters()
	if helpMode then
		widget.setText("filterFunctionsLabel2","Item Filters: select whether an item is: Matched Exactly,")
		widget.setText("filterFunctionsLabel","Matched by Type (item category), matched by Category (groups of!)")
		return
	end
	if not initialized then return end
	for i=1,5 do
		filterType[i]=widget.getSelectedOption("item"..i.."Filter")
	end
	world.sendEntityMessage(myBox, "setFilters", filterType);
end

function invertButtons(name)
	if helpMode then
		widget.setText("filterFunctionsLabel2","Invert Logic: Slot is treated as an exception for pattern matching.")
		widget.setText("filterFunctionsLabel","")
		return
	end
	if not initialized then return end
	filterInverted[buttons.invertButtons[name]] = widget.getChecked(name)
	world.sendEntityMessage(myBox, "setInverts", filterInverted);
end

function roundRobinToggle(name)
	if helpMode then
		widget.setText("filterFunctionsLabel2","Even Split: splits stacks of an item evenly between containers.")
		widget.setText("filterFunctionsLabel","^orange;Only matches a single item^reset;")
		return
	end
	local buttonState = widget.getChecked(buttonNames.evenSplit)
	world.sendEntityMessage(myBox, "setRR", buttonState)
end

function roundRobinSlotToggle(name)
	if helpMode then
		widget.setText("filterFunctionsLabel2","Slot Split: Splits a stack between slots in a container.")
		widget.setText("filterFunctionsLabel","^orange;Mutually exclusive with Stack Only^reset;")
		return
	end
	local buttonState = widget.getChecked(buttonNames.slotSplit)
	--only stack and slot split are mutually exclusive.
	if buttonState then
		widget.setChecked(buttonNames.onlyStack,false)
	end
	world.sendEntityMessage(myBox, "setRRS", buttonState)
end

function leaveOneItemToggle(name)
	if helpMode then
		widget.setText("filterFunctionsLabel2","Leave One: Self-explanatory.")
		widget.setText("filterFunctionsLabel","^orange;Do you really need help with this?^reset;")
		return
	end
	local buttonState = widget.getChecked(buttonNames.leaveOne)
	world.sendEntityMessage(myBox, "setLO", buttonState)
end

function onlyStackToggle(name)
	if helpMode then
		widget.setText("filterFunctionsLabel2","Only Stack: Only attempts to add to already present stacks.")
		widget.setText("filterFunctionsLabel","^orange;Only matches a single item^reset;. ^orange;Mutually exclusive with Slot Split^reset;.")
		return
	end

	local buttonState = widget.getChecked(buttonNames.onlyStack)
	--only stack and slot split are mutually exclusive.
	if buttonState then
		widget.setChecked(buttonNames.slotSplit,false)
	end
	world.sendEntityMessage(myBox, "setOS", buttonState)
end

function dbg(args)
	sb.logInfo(sb.printJson(args))
end

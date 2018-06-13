--input<Left/Mid/Right>

function init()
	box={}
	maxTime=120
end

function update()
	if initialized==nil then
		myBox=pane.sourceEntity()
		position=world.entityPosition(myBox);
		promise = world.sendEntityMessage(myBox, "sendConfig")
		initialized=false
		return
	end
	if not initialized then
		if promise:finished() and promise:succeeded() then
			initialize(promise:result())
			initialized = true;
		elseif promise:finished() and not promise:succeeded() then
			promise = world.sendEntityMessage(myBox, "sendConfig")
		end
		return;
	end
end

function initialize(conf)
	--sb.logInfo("conf: %s",conf)
	for k,v in pairs(conf) do
		box[k]=v
	end
	fillBoxes()
end




function saveTimerValues()
	if initialized then
		world.sendEntityMessage(myBox,"setTimerValues",box)
	end
end

function loadTimerValues()
	if initialized then
		promise = world.sendEntityMessage(myBox, "sendConfig")
		initialized=false
	end
end

function resetTimerValues()
	if initialized then
		promise = world.sendEntityMessage(myBox,"resetTimerValues")
		initialized=false
	end
end

function setTimerValues()
	if initialized then
		local textLeft = widget.getText("inputLeft")
		local textMid = widget.getText("inputMid")
		local textRight = widget.getText("inputRight")
		local doFix=false
		
		if textLeft ~= "" then
			textLeft=tonumber(textLeft)
			if textLeft==0 then
				textLeft=1
				doFix=true
			elseif textLeft>maxTime then
				textLeft=maxTime
				doFix=true
			end
		end
		
		if textMid ~= "" then
			textMid=tonumber(textMid)
			if textMid==0 then
				textMid=1
				doFix=true
			elseif textMid>maxTime then
				textMid=maxTime
				doFix=true
			end
		end
		
		if textRight ~= "" then
			textRight=tonumber(textRight)
			if textRight==0 then
				textRight=1
				doFix=true
			elseif textRight>maxTime then
				textRight=maxTime
				doFix=true
			end
		end
		
		box.leftValue=textLeft
		box.midValue=textMid
		box.rightValue=textRight
		
		if doFix then
			fillBoxes()
		end
	end
end

function fillBoxes()
	widget.setText("inputLeft",tostring(box.leftValue))
	widget.setText("inputMid",tostring(box.midValue))
	widget.setText("inputRight",tostring(box.rightValue))
	--sb.logInfo("fillboxes: %s",box)
end
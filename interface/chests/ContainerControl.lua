-- Appended by Xan the Dragon
-- Main controller script for the "Read All" button added by /chest/cdx/chest<slots>.config

require("/scripts/xcore_customcodex/LearnCodexRoutine.lua") -- Defines LearnCodex(string name)

function CodexButtonClicked()
	--player.interact("ScriptPane", "/interface/scripted/xcustomcodex/xcodexui.config", player.id())
	local numLearned = 0
	local numAlreadyKnew = 0
	local numErrored = 0

	local items = widget.itemGridItems("itemGrid")
	for _, item in pairs(items) do--for index, item in pairs(items) do
		local itemName = item.name
		-- Simple test: Does it end in -codex? We can easily scrap items that aren't codexes this way.
		if #itemName > 6 and itemName:sub(-6) == "-codex" then

			-- Reiteration: 0 = Learned it, 1 = Didn't learn it (but it was because we already knew it), 2 = Something errored out and we had to abort the process.
			local learnStatus = LearnCodex(itemName)
			if learnStatus == 0 then
				numLearned = numLearned + 1
			elseif learnStatus == 1 then
				numAlreadyKnew = numAlreadyKnew + 1
			elseif learnStatus == 2 then
				numErrored = numErrored + 1
			end
		end
	end
	widget.playSound("/sfx/interface/item_equip.ogg") -- Give the player some feedback that they learned the entries.

	-- Now let's give them feedback.
	local statusText = ""

	if numLearned ~= 0 then
		-- We learned at least one. Append this information.
		statusText = statusText .. "^cornflowerblue;Read " .. tostring(numLearned) .. "^reset;"
	end
	if numAlreadyKnew ~= 0 then
		-- We already knew at least one. But...
		if numLearned ~= 0 then
			-- If we ALSO learned at least one, add a separator bar, then the necessary text.
			statusText = statusText .. " ^gray;/^reset; " .. "^cornflowerblue;Knew " .. tostring(numAlreadyKnew) .. "^reset;"
		else
			-- But here we have a bit of a strange condition.
			-- If the user has read at least one of these entries, then "Read X | Knew Y" makes sense linguistically.
			-- Alternatively, just "Knew Y" doesn't, so I will use the extra space I have from NOT putting the "Read X" to make this more descriptive
			-- It will say "Already Knew Y" if it can now.

			statusText = statusText .. "^cornflowerblue;Already Knew " .. tostring(numAlreadyKnew) .. "^reset;"
		end
	end
	if numErrored ~= 0 then
		-- Similar case with the number of errored codex entries. If something has added text before this, add the separator bar.
		if numLearned ~= 0 or numAlreadyKnew ~= 0 then
			statusText = statusText .. " ^gray;/^reset; "
		end

		-- Direct people to the log.
		statusText = statusText .. "^red;" .. tostring(numErrored) .. " failed (see log)"
	end

	-- Reflect on this information.
	widget.setText("statusMessage", statusText)
end

-- gg ez
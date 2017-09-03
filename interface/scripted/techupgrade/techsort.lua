function populateTechList(slot)
  widget.clearListItems(self.techList)

  -- Show enabled techs at the top of the list
  local techs = player.enabledTechs()
  local disabled = util.filter(util.keys(self.techs), function(a) return not contains(techs, a) end)
  util.appendLists(techs, disabled)

  local sort = root.assetJson("/interface/scripted/techupgrade/techsort.config").sort

  -- Add all of the sorted stuff
  local things = util.filter(sort, function(a) return contains(techs, a) end)
  local stuff = {}
  for i,thing in ipairs(sort) do
      if contains(things, thing) then
          if stuff[i] then
              table.insert(stuff, i, thing)
          else
              stuff[i] = thing
          end
      end
  end

  -- Add all of the unsorted stuff
  local things = util.filter(techs, function(a) return not contains(things, a) end)
  for _,thing in pairs(things) do
      table.insert(stuff, thing)
  end

  for _,techName in pairs(stuff) do
    local config = self.techs[techName]
    if root.techType(techName) == slot then
      local listItem = widget.addListItem(self.techList)
      widget.setText(string.format("%s.%s.techName", self.techList, listItem), config.shortDescription)
      widget.setData(string.format("%s.%s", self.techList, listItem), techName)

      if contains(player.enabledTechs(), techName) then
        widget.setImage(string.format("%s.%s.techIcon", self.techList, listItem), config.icon)
      else
        widget.setImage(string.format("%s.%s.techIcon", self.techList, listItem), self.techLockedIcon)
      end

      if player.equippedTech(slot) == techName then
        widget.setListSelected(self.techList, listItem)
      end
    end
  end
end

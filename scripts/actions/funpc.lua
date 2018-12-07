function hasStaffPrimary(args, board)
  if self.primary == nil then return false end
  return root.itemHasTag(self.primary.name, "staff") or root.itemHasTag(self.primary.name, "wand")
end

function hasStaffSheathed(args, board)
  if self.sheathedPrimary == nil then return false end
  return root.itemHasTag(self.primary.name, "staff") or root.itemHasTag(self.primary.name, "wand")
end

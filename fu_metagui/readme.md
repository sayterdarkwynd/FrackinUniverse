# metaGUI - a primer
##### As of StardustLib Alpha v0.51
- [Your first UI](#your-first-ui)
- [Widget reference](#widget-reference)
  - [Layout](#layout)
  - [Panel](#panel)
  - [Scroll Area](#scroll-area)
  - [Tab Field](#tab-field)
  - [Spacer](#spacer)
  - [Label](#label)
  - [Image](#image)
  - [Canvas](#canvas)
  - [Button](#button)
  - [Icon Button](#icon-button)
  - [Check Box](#check-box)
  - [Text Box](#text-box)
  - [List Item](#list-item)
  - [Item Slot](#item-slot)
  - [Item Grid](#item-grid)
- [Utility functions](#utility-functions)
- [Misc. notes](#misc-notes)

## Your first UI
A pane using metaGUI is a JSON document (as with vanilla panes), typically with the extension `.ui`, though this is not required.

#### Document structure
```js
{ // Basic attributes:
  "style" : "window", // This can be: window (default, has a titlebar), panel (just a simple frame)
  "size" : [320, 200], // This is the *internal* size of your UI layout, excluding window decorations.
  "title" : "metaGUI example pane", // The displayed title in "window" mode. Does nothing otherwise.
  "icon" : "icon.png", // Path can be relative or absolute. Recommended to be 18x18 pixels or smaller.
  "accentColor" : "3f3fff", // An accent color can be specified as a hexcode, or default to the theme's.
  "scripts" : ["script.lua"], // Paths can be relative or absolute.
  
  // Extra attributes:
  "openWithInventory" : true, // Same as in a vanilla pane: opens the inventory when the window opens,
  // closes the inventory when the window closes (and vice versa), and opens the window beside it.
  "anchor" : ["bottomRight", [-16, -24]], // Anchors the window a side, corner, or the center of the
  // screen. Positions are left to right and top to bottom; the above anchor has the edges of the window
  // 16 pixels away from the right, and 24 pixels from the bottom.
  "uniqueBy" : "path", // Closes any previous window with the same document path when a new one is opened.
  // Most useful for UI not bound to an entity, such as with activeitems or Quickbar entries.
  "uniqueMode" : "toggle", // When set, will toggle the window when a new instance tries to open instead
  // of immediately opening in place of the previous one.
  
  "children" : [ // Finally, the layout syntax. Notice how this is an *array*, unlike vanilla panes;
    // widget names are optional, as metaGUI is largely heirarchy- and layout-based.
    { "mode" : "horizontal" }, // If the "type" field is omitted, the first object is used as parameters
    // for the layout itself. Here, we set the root layout to horizontal (default for root is vertical).
    [ // Arrays (with at least one item) are treated as sub-layouts; if the parent layout is in vertical
      // mode, sub-layouts default to horizontal (and vice versa), otherwise they default to manual.
      { "type" : "label", "text" : "Here is a simple label. Formatting works as usual." },
      { "type" : "image", "file" : "picture.png" } // Widgets can use relative paths as well.
    ], [ // Our second implicit sub-layout, on the right-hand side.
      { "size" : 80 }, // This time we use our parameter object to give our sidebar a fixed width.
      { "type" : "button", "caption" : "Top button.", "id" : "btnTop" }, // Widgets with an "id" parameter
      // have a reference to their table placed in the scripts' global scope with the same value as key.
      { "type" : "button", "caption" : "Another button.", "color" : "accent" }, // Buttons and other
      // widgets can specify a highlight color, either as a hexcode or the window's accent color.
      "spacer", // An expanding spacer can be placed implicitly with the string "spacer", or a fixed-size
      // one with an integer value. (A negative-size spacer can even be used to reduce default spacing.)
      { "type" : "button", "caption" : "And this one is on the bottom!"}
    ]
  ]
}
```
#### Scripting notes
- Your scripts are loaded in during the pane's init call, so you're free to do your init outside of an `init()` function.
- Scripts' `init()`, `update()` and `uninit()` functions are handled individually and can't overwrite each other.
- `util.lua`, `vec2.lua` and `rect.lua` are preloaded, so no need to `require` them yourself.
- You can use system-handled coroutines ("events") as follows:
```lua
metagui.startEvent(function()
  for i=1,60 do coroutine.yield() end -- wait 1sec
  util.wait(1.0) -- also wait 1sec
  -- query and wait for result
  local blah = util.await(world.sendEntityMessage(pane.sourceEntity(), "blah")):result()
  -- etc.
end)
```
- Certain widget functions are actually events, such as `button:onClick()` and `textBox:onEnter()`
- Context menus are available:
```lua
metagui.contextMenu {
  {"Item name", function() --[[item action]] end},
  "separator",
  {"Second item", someFunction}
}
```

#### Registering your panes
While not mandatory (as you can address panes by path), it's generally a good idea to add your panes to the registry,
especially if you use the same pane for more than one object, or intend other mods to be able to open them without
needing to keep track of the path. Registering your pane allows you to keep track of all your various UIs in one place,
and to reorganize your files if desired without needing to go back and change the path in all your objects.
```js
[ // in file: /metagui/registry.json.patch
  { "op" : "add", "path" : "/panes/modname", "value" : {
    "pane1" : "/path/to/pane1.ui", // addressed as "modname:pane1"
    "pane2" : "/path/to/pane2.ui",
    // ...
  } }
]
```

#### Opening your panes
In an object definition or interact call:
```js
"interactAction" : "ScriptPane",
"interactData" : { "gui" : { }, "scripts" : ["/metagui.lua"], "ui" : "modname:pane" }
```
```lua
player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, ui = "modname:pane" }) -- item/pane
return {"ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, ui = "modname:pane" }} -- object.onInteract
```
In a Quickbar entry:
```js
"action" : [ "ui", "modname:pane" ]
```
*But what if it's a container?* Simple:
```js
"uiConfig" : "/metagui/container.config", "ui" : "modname:pane"
```

## Widget reference
##### General attributes
```js
"type" : "button", // As you'd expect, the type of widget. Case sensitive; generally in camelCase.
"id" : "btnApply", // Key of the widget's global reference; if omitted, none is created.
"position" : [32, 8], // Explicit position; ignored in automatic layouts. Top to bottom, left to right.
"size" : [16, 16], // Explicit size.
"expandMode" : [1, 0], // Only available for some widget types; how eager the widget is to expand on each
// axis. 0 is fixed size; otherwise widget will expand if none in the layout have higher priority.
"visible" : false, // When false, widget is hidden and excluded from layout calculations.
"toolTip" : "I'm a tool tip!", // Self explanatory. Can be multiple lines.
"data" : { "something" : "whatever" }, // Arbitrary JSON data. Mostly useful for script-built panes.
```
##### General methods
```lua
widget:center() -- Returns the widget's center position.
widget:queueRedraw()
widget:queueGeometryUpdate()

widget:relativeMousePosition()

widget:setVisible(bool)

widget:addChild(parameters) -- Only recommended to use on layout, panel, or scrollArea.
widget:clearChildren()
widget:delete()

widget:findParent(type) -- Find most immediate parent of a specific type.

widget:subscribeEvent(name, function) -- Subscribe to a named event on behalf of a widget.
widget:pushEvent(name, ...) -- Push event to widget with given parameters.
-- Checks self first, then each child. If own event gives a "truthy" value, immediately returns it;
-- if a child event gives one, it only short-circuits if it's nonboolean.
widget:broadcast(name, ...) -- Push event to widget's parent (and likely siblings).
widget:wideBroadcast(level, name, ...) -- Same as broadcast, but from specified number of levels up.
-- Subscribed events propagate to children if not caught (subscription exists and returns true).

-- (more in core.lua, if you want to create your own widget types)
```

### Layout
##### Attributes
```js
"mode" : "horizontal", // How the layout arranges its children. Defaults to manual if explicitly declared.
// "horizontal", "vertical" ("h", "v"): Automatically arranges children in a row or column.
// "stack" : Children are stacked on top of each other and expanded to fit layout space.
// "manual": Children are explicitly placed; layout expands to fit.
"spacing" : 2, // Spacing between child elements in automatic layout modes, in pixels. Defaults to 2px.
"align" : 0.5, // Proportion of alignment for fixed-size children on opposite axis in automatic modes.
// 0 is aligned with left or top edge; 1 with bottom or right. Defaults to 0.5 (centered).
```

### Panel
Essentially a layout with a background.
##### Attributes
```js
"style" : "concave", // "convex" (default), "concave", "flat"
```

### Scroll Area
Another layout-proxy, this time with drag-scrolling; left or right click for touch-style "fling" scrolling, middle click for "thumb" (absolute) mode.
As of Beta v0.1.2, full scroll wheel support is included.
##### Attributes
```js
"scrollDirections" : [0, 1], // Whether the contents can be scrolled on each axis. Defaults to vertical.
"scrollBars" : true, // Whether to show scroll bars after scrolling. Defaults to true.
"thumbScrolling" : true, // Whether "thumb" (absolute) scrolling is enabled. Defaults to true.
```
##### Methods
```lua
scrollArea:scrollBy(vec, suppressAnimation) -- Attempts to scroll contents by [vec] pixels. Shows scroll
-- bars if suppressAnimation is false or omitted.
scrollArea:scrollTo(pos, suppressAnimation, raw) -- Attempts to center viewport on [pos]. Shows scroll bars if
-- suppressAnimation is false or omitted. If raw is specified, sets raw position instead of centering.
```

### Tab Field
desc
##### Attributes
```js
"layout" : "vertical", // Which direction the tabs run. "horizontal" is a bar across the top, "vertical" is a
// sidebar down the left side.
"tabWidth" : 80, // If using vertical layout, how wide the tabs are. (Horizontal tabs fit to contents.)
"noFocusFirstTab" : false, // If true, prevents the first tab created from being automatically selected. Useful
// for cases where tab contents are loaded on first viewing, such as the settings panel.
"tabs" : [ // An array of tabs, formatted as follows:
  "id" : "whatever", // Optional. Tab's unique identifier; if not specified, will be populated with a UUID.
  "title" : "Example Tab", // The tab's displayed title.
  "icon" : "blob.png", // The tab's icon; 16x16 or smaller.
  "visible" : true, // Whether the tab widget itself is visible. Same rules as on widgets.
  "color" : "ff00ff", // The accent color of the tab.
  "contents" : [ ], // The contents of the tab's connected page.
]
"bottomBar" : [ ], // Contents of an optional bar below the contents. Mostly useful for vertical tab layout.
```
##### Methods
```lua
tabField:newTab(parameters) -- Creates a new tab. Parameters are as in the "tabs" attribute. Returns a tab object.
tab:select() -- Switches to tab.
tab:setTitle(title, icon) -- Changes the tab's title and (optionally) icon.
tab:setColor(color) -- Changes the tab's accent color.
tab:setVisible(bool)
```
##### Events
```lua
tabField:onTabChanged(tab, previous) -- Called on changing tabs.
```

### Spacer
*(no additional attributes or methods)*

### Label
A simple text display.
##### Attributes
```js
"text" : "Hello ^accent;world^reset;!", // The text to display. Supports formatting codes.
"fontSize" : 8, // Defaults to 8.
"color" : "3f3fff", // The unformatted text color, either "accent" or a hexcode.
"align" : "center", // Horizontal alignment (left, center, right). Defaults to "left".
"inline" : false, // If true, makes label fixed-size.
"expand" : false, // If true, gives (horizontal) expansion priority.
```
##### Methods
```lua
label:setText(string)
```

### Image
A simple image display. Centers image within widget area if given explicit size.
##### Attributes
```js
"file" : "image.png", // The image to display. Can be absolute or relative.
"scale" : 2, // Scale proportion for the image. Defaults to 1.
"noAutoCrop" : true, // When true, preserve empty space in image margins; otherwise, behavior
// matches vanilla image widgets.
```
##### Methods
```lua
image:setFile(path)
image:setScale(value)
```

### Canvas
A raw canvas. Override `draw()` and optionally the various mouse functions to use.

### Button
A simple push button. Can be given an accent color.
##### Attributes
```js
"caption" : "Button text", // Text to draw on the button.
"captionOffset" : [0, 0], // Pixel offset for caption.
"color" : "accent", // Accent color. Rendering dependent on theme.
```
##### Methods
```lua
button:setText(string) -- Sets the button's caption.
```
##### Events
```lua
button:onClick() -- Called when button released after pressing (left click).
```

### Icon Button
A button that renders as a given icon.
##### Attributes
```js
"image" : "icon.png:", // The idle image to use. If suffixed with a colon, file is treated as a sprite
// sheet with the frames "idle", "hover" and "press". Relative or absolute paths accepted.
"hoverImage" : "hover.png",
"pressImage" : "press.png",
```
##### Methods
```lua
iconButton:setImage(idle, hover, press) -- Sets the button's icon drawables.
```

### Check Box
A check box. Uses the same `onClick` event as the button types.
##### Attributes
```js
"checked" : true, // Pre-checked if specified.
"radioGroup" : "mode", // If specified, widget becomes a radio button grouped with others of its group.
"value" : 23, // Any data type. Used by radio buttons.
```
##### Methods
```lua
checkBox:setChecked(b)
local bool = checkBox.checked
checkBox:getGroupChecked() -- If widget is a radio button, returns the checked widget of its group.
checkBox:getGroupValue() -- Same as above, except returns the widget's value attribute.
```

### Text Box
A text entry field.
##### Attributes
```js
"caption" : "Search...", // Text to display when unfocused and no text is entered.
"inline" : true, // Alias for an expandMode of [0, 0].
"expand" : true, // Alias for an expandMode of [2, 0].
```
##### Methods
```lua
textBox:focus() -- Grabs keyboard focus.
textBox:blur() -- Releases focus.
textBox:setText(string) -- Sets contents.

textBox:setCursorPosition(int) -- Sets the position of the text cursor, in characters.
textBox:moveCursor(int) -- Moves the cursor by a given number of characters.
textBox:setScrollPosition(int) -- Sets how far the text field is scrolled, if contents overflow.
```
##### Events
```lua
textBox:onTextChanged() -- Called on any change to the entered text.
textBox:onEnter() -- Called when unfocused by hitting enter.
textBox:onEscape() -- Called when unfocused by hitting escape.
```

### List Item
A list item; essentially a layout, selectable by mouse click. Deselects siblings when selected.  
Also available under type `menuItem` with behavior modified accordingly.
##### Attributes
```js
"buttonLike" : true, // Flag for theme use; by default, indicates that the item should make a sound when
// clicked, e.g. a context menu item. Implicit for menuItems.
"noAutoSelect" : true, // When true, list item will not be automatically set as selected when clicked.
// Implicit for menuItems.
"selectionGroup" : "submenu1", // Selecting a menu item will only automatically deselect siblings with
// the same selection group (nil included).
```
##### Methods
```lua
listItem:select()
listItem:deselect()
```
##### Events
```lua
listItem:onSelected()
listItem:onClick(button)
```

### Item Slot
An item slot. Functions the way you'd expect.
##### Attributes
```js
"autoInteract" : true, // Whether the item slot handles interactions automatically. True, false, or a
// mode string. Can also be specified as "auto". Current supported modes:
// default (true): Acts like a container's item slots.
// container: Acts as a proxy to a container slot belonging to the source entity.
"containerSlot" : 1, // If specified, the container slot index to proxy. Implies "container" mode.
"glyph" : "icon.png", // Glyph to display on slot background. Defaults to none.
"colorGlyph" : true, // Specifies if the glyph is in color. Can also be specified as the glyph path.
"color" : "accent", // Entirely theme-dependent; the slot's accent color, if the theme supports it.
"item" : { "name" : "perfectlygenericitem", "count" : 1, "parameters" : { } } // Sets a starting item.
```
##### Methods
```lua
itemSlot:item() -- Returns the current item.
itemSlot:setItem(descriptor)
itemSlot:acceptsItem(item) -- Override to filter items accepted by autoInteract.
```
##### Events
```lua
itemSlot:onItemModified() -- Called when contents modified by user interaction.
```

### Item Grid
A grid of item slots.
##### Attributes
```js
"slots" : 5, // Starting number of slots.
"columns" : 5, // Number of slots per row. If not specified, fills given space.
"spacing" : 2, // Spacing between slots. Integer or vector. Defaults to 2.

"autoInteract" : true, // Passed to child slots.
"containerSlot" : 1, // Starting slot for container proxying. Implies "container" mode.
```
##### Methods
```lua
itemGrid:addSlot(item)
itemGrid:removeSlot(index)
itemGrid:setNumSlots(num)

itemGrid:item(index)
itemGrid:setItem(index, item)

itemGrid:onSlotMouseEvent(button, down) -- Mouse event for children, if no autoInteract  mode specified.
```

## Utility functions
```lua
metagui.path(path) -- Asset path relative to the current pane.
metagui.asset(path) -- Asset path relative to the theme. If .png, searches for fallback if not found.

metagui.setTitle(string) -- Sets the window title.
metagui.setIcon(path) -- Sets the window icon.
metagui.queueFrameRedraw() -- Marks the window decorations for redraw.

metagui.startEvent(function, ...) -- Starts an event with the specified parameters.
metagui.broadcast(name, ...) -- Broadcasts a named event to the entire window with specified parameters.
metagui.registerUninit(function) -- Registers a function to be called on window exit.

metagui.contextMenu(list) -- Opens a context menu with a list of elements: {name, function}
-- A separator can be placed by inserting the string "separator".

metagui.createWidget(def, parent) -- Attempts to create a metaGUI widget from the given definition table.
-- Returns the widget table, or nil if one could not be created.
metagui.createImplicitLayout(list, parent, defaults) -- Creates a layout from an array of definitions.
-- Uses the first-element parameter object if present, then a defaults table if provided.

metagui.mkwidget(parent, def) -- Makes a new vanilla (backing) widget and returns the full path.

metagui.paneToWidgetPosition(widget, pos) -- Turns a pane-relative position into a widget-relative one.
metagui.screenToWidgetPosition(widget, pos) -- Turns a screen position into a widget-relative one.

metagui.keyToChar(keycode, accel) -- Returns the character a given keycode should print, or nil if none.

metagui.itemsCanStack(item1, item2) -- Check if two item descriptors can stack together.
metagui.itemMaxStack(item) -- Returns the maximum stack size of an item descriptor.
metagui.itemStacksToCursor(item) -- Returns how many of an item can fit on the cursor, if any.

metagui.checkShift() -- Only available in events; checks if player is holding shift.
metagui.fastCheckShift() -- Attempts to determine if player is holding shift through tech hooks only.

metagui.checkSync(resync, id) -- Checks if sync succeeded with source entity (or entity id if specified).
-- If resync specified, clears sync flag and pings entity.
metagui.waitSync(resync, id) -- Same as above, but waits until sync flag set. Only available in events.
```

## Misc. notes
(none at this time)

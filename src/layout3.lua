local Layout = {}


-- Tunable constants (px)
local PADDING = 16
local RIGHT_W = 240 -- abilities sidebar width
local BOTTOM_H = 200 -- bottom bar height
local WEAP_W = 240 -- weapons panel width inside bottom bar


function Layout.compute(w, h)
-- Place Abilities panel in the **bottom half** of the right corner (above the bottom bar)
local usable_h = h - BOTTOM_H
local sidebarRight = {
x = w - RIGHT_W - PADDING,
y = math.floor(usable_h / 2) + PADDING,
w = RIGHT_W,
h = math.floor(usable_h / 2) - 2 * PADDING
}
local bottomBar = {x = 0, y = h - BOTTOM_H, w = w, h = BOTTOM_H}


local weaponsPanel = {
x = PADDING,
y = bottomBar.y + PADDING,
w = WEAP_W - PADDING, -- inner width for a nice gap to cards
h = bottomBar.h - 2 * PADDING
}


local cardsArea = {
x = weaponsPanel.x + weaponsPanel.w + PADDING,
y = bottomBar.y + PADDING,
w = w - (weaponsPanel.x + weaponsPanel.w + 2 * PADDING),
h = bottomBar.h - 2 * PADDING
}


local gridArea = {
x = 0,
y = 0,
w = w,
h = h - BOTTOM_H
}


return {
padding = PADDING,
right = sidebarRight,
bottom = bottomBar,
weapons = weaponsPanel,
cards = cardsArea,
grid = gridArea
}
end


return Layout
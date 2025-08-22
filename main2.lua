# LOVE2D UI Shell — Hex Grid + Panels

This is a minimal, working starter for your Balatro × D\&D × PoE-style UI in LÖVE.

It draws:

* A **top‑down hex grid** as the playfield (background)
* A **bottom bar** with **weapons** panel (left) and **cards** row
* A **right sidebar** with **abilities** slots

Copy these files into your project structure exactly as shown, then run the folder with LÖVE.

---

## Folder structure

```
mygame/
├─ main.lua
├─ conf.lua
└─ src/
   ├─ layout.lua
   ├─ hexgrid.lua
   ├─ game/
   │  ├─ entities.lua
   │  └─ hexmap.lua
   ├─ ui/
   │  ├─ theme.lua
   │  ├─ panel.lua
   │  ├─ hand.lua
   │  ├─ abilities.lua
   │  └─ weapons.lua
   └─ core/
      └─ camera.lua  -- stubbed (pan/zoom later)
```

---

## `conf.lua`

```lua
function love.conf(t)
  t.identity = "mygame"
  t.window.title  = "Rogue Cards — UI Shell"
  t.window.width  = 1280
  t.window.height = 720
  t.window.resizable = true
  t.window.vsync = 1
end
```

---

## `src/layout.lua`

```lua
local Layout = {}

-- Tunable constants (px)
local PADDING   = 16
local RIGHT_W   = 240    -- abilities sidebar width
local BOTTOM_H  = 200    -- bottom bar height
local WEAP_W    = 240    -- weapons panel width inside bottom bar

function Layout.compute(w, h)
  -- Abilities panel spans bottom half of full height (overlays bottom bar) and reaches window bottom
local sidebarRight = {
  x = w - RIGHT_W - PADDING,
  y = math.floor(h / 2),
  w = RIGHT_W,
  h = h - math.floor(h / 2)
}
  -- Bottom bar stops before the Abilities sidebar
local bottomBar    = {x = 0, y = h - BOTTOM_H, w = sidebarRight.x, h = BOTTOM_H}

  local weaponsPanel = {
    x = PADDING,
    y = bottomBar.y + PADDING,
    w = WEAP_W - PADDING, -- inner width for a nice gap to cards
    h = bottomBar.h - 2 * PADDING
  }

  local cardsArea = {
    x = weaponsPanel.x + weaponsPanel.w + PADDING,
    y = bottomBar.y + PADDING,
    w = bottomBar.w - (weaponsPanel.x + weaponsPanel.w + 2 * PADDING),
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
    right   = sidebarRight,
    bottom  = bottomBar,
    weapons = weaponsPanel,
    cards   = cardsArea,
    grid    = gridArea
  }
end

return Layout
```

---

## `src/hexgrid.lua`

```lua
local HexGrid = {}

-- Pointy-top hex math (axial coords)
HexGrid.size = 28

local sqrt3 = math.sqrt(3)

-- axial -> pixel (center)
local function axial_to_pixel(q, r, size)
  local x = size * sqrt3 * (q + r/2)
  local y = size * 1.5 * r
  return x, y
end

-- polygon points for a hex centered at (cx, cy)
local function hex_corners(cx, cy, size)
  local pts = {}
  for i = 0, 5 do
    local angle = math.rad(60 * i - 30) -- pointy top
    pts[#pts+1] = cx + size * math.cos(angle)
    pts[#pts+1] = cy + size * math.sin(angle)
  end
  return pts
end

-- Where we place the grid relative to the area
function HexGrid.origin(area)
  local ox = area.x + area.w * 0.5
  local oy = area.y + area.h * 0.45 -- slight upward bias
  return ox, oy
end

-- rounding helpers for screen->hex picking
local function cube_round(x, y, z)
  local rx = math.floor(x + 0.5)
  local ry = math.floor(y + 0.5)
  local rz = math.floor(z + 0.5)

  local x_diff = math.abs(rx - x)
  local y_diff = math.abs(ry - y)
  local z_diff = math.abs(rz - z)

  if x_diff > y_diff and x_diff > z_diff then
    rx = -ry - rz
  elseif y_diff > z_diff then
    ry = -rx - rz
  else
    rz = -rx - ry
  end
  return rx, ry, rz
end

local function axial_round(q, r)
  local x, z = q, r
  local y = -x - z
  local rx, ry, rz = cube_round(x, y, z)
  return rx, rz
end

-- screen (x,y) -> nearest axial (q,r)
function HexGrid.pixel_to_axial(x, y, area)
  local s = HexGrid.size
  local ox, oy = HexGrid.origin(area)
  local px = x - ox
  local py = y - oy
  local q = (sqrt3/3 * px - 1/3 * py) / s
  local r = (2/3 * py) / s
  return axial_round(q, r)
end

-- axial (q,r) -> screen (x,y)
function HexGrid.axial_to_screen(q, r, area)
  local s = HexGrid.size
  local ox, oy = HexGrid.origin(area)
  local x, y = axial_to_pixel(q, r, s)
  return ox + x, oy + y
end

-- convenience: hex polygon points at axial
function HexGrid.hex_points(q, r, area, inset)
  local s = HexGrid.size - (inset or 1)
  local cx, cy = HexGrid.axial_to_screen(q, r, area)
  return hex_corners(cx, cy, s)
end

-- Draw a rectangular patch of axial coords covering the given area
function HexGrid.draw(area)
  local s = HexGrid.size
  local col_w = sqrt3 * s
  local row_h = 1.5 * s

  local cols = math.floor(area.w / col_w) + 2
  local rows = math.floor(area.h / row_h) + 2

  local ox, oy = HexGrid.origin(area)

  love.graphics.push()
  love.graphics.translate(ox, oy)

  love.graphics.setLineWidth(1)
  for r = -math.floor(rows/2), math.floor(rows/2) do
    for q = -math.floor(cols/2), math.floor(cols/2) do
      local x, y = axial_to_pixel(q, r, s)
      love.graphics.setColor(0.25, 0.28, 0.32, 0.35)
      love.graphics.polygon("fill", hex_corners(x, y, s-1))
      love.graphics.setColor(0.75, 0.8, 0.86, 0.25)
      love.graphics.polygon("line", hex_corners(x, y, s-1))
    end
  end

  love.graphics.pop()
end

return HexGrid
```

---

## `main.lua`

```lua
local Layout   = require("src.layout")
local HexGrid  = require("src.hexgrid")
local Entities = require("src.game.entities")
local HexMap   = require("src.game.hexmap")
local UITheme  = require("src.ui.theme")
local UIHand   = require("src.ui.hand")
local UIAbilities = require("src.ui.abilities")
local UIWeapons   = require("src.ui.weapons")

local layout -- computed each frame in case of resize
local fontSmall, fontMedium

-- Fake data for UI placeholders
local cards = {}
local abilities = {
  { name = "Cleave" },
  { name = "Dash" },
  { name = "Taunt" },
  { name = "Fireball" },
  { name = "Heal" }
}
local weapons = {
  { name = "Longsword",  slot = "Main Hand" },
  { name = "Kite Shield", slot = "Off Hand" }
}

-- Selection state for UI
local selected = { card = nil, ability = nil, weapon = nil }

-- Entity ids
local playerId

local hovered -- {q,r} under mouse when on grid

local function init_cards(n)
  cards = {}
  for i = 1, n do
    cards[i] = { title = "Card " .. i, subtitle = (i % 2 == 0) and "Rare" or "Common" }
  end
end

local function pointInRect(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function love.load()
  love.graphics.setBackgroundColor(UITheme.bg)
  fontSmall  = love.graphics.newFont(12)
  fontMedium = love.graphics.newFont(16)
  init_cards(8)

  -- Entities
  Entities.reset()
  playerId = Entities.spawn{ type = "player", q = 0, r = 0, name = "Hero" }
  Entities.spawn{ type = "enemy", q =  2, r = 0 }
  Entities.spawn{ type = "enemy", q = -1, r = 1 }
end

function love.resize(w, h)
  -- no body needed; layout recomputed in draw
end

local function draw_hex_highlight(q, r, area)
  love.graphics.setColor(0.9, 0.95, 1.0, 0.15)
  love.graphics.polygon("fill", HexGrid.hex_points(q, r, area))
  love.graphics.setColor(0.9, 0.95, 1.0, 0.7)
  love.graphics.setLineWidth(2)
  love.graphics.polygon("line", HexGrid.hex_points(q, r, area))
end

local function draw_entity(e, area)
  local cx, cy = HexGrid.axial_to_screen(e.q, e.r, area)
  love.graphics.setLineWidth(2)
  if e.type == "player" then
    love.graphics.setColor(UITheme.player)
  else
    love.graphics.setColor(UITheme.enemy)
  end
  love.graphics.circle("fill", cx, cy, HexGrid.size * 0.45)
end

function love.update(dt)
  -- placeholder: no game logic yet
end

function love.draw()
  local w, h = love.graphics.getDimensions()
  layout = Layout.compute(w, h)

  -- 1) Playfield (hex grid background)
  HexGrid.draw(layout.grid)

  -- 1.5) Hover highlight on grid
  local mx, my = love.mouse.getPosition()
  hovered = nil
  if pointInRect(mx, my, layout.grid) then
    local q, r = HexGrid.pixel_to_axial(mx, my, layout.grid)
    hovered = { q = q, r = r }
    draw_hex_highlight(q, r, layout.grid)
  end

  -- 2) Entities (draw enemies first, then player on top)
  for id, e in pairs(Entities.all()) do
    if e and e.type == "enemy" then draw_entity(e, layout.grid) end
  end
  local p = Entities.get(playerId)
  if p then draw_entity(p, layout.grid) end

  -- 3) UI overlays
  UIWeapons.draw(layout.weapons, weapons, selected.weapon, fontSmall, fontMedium)
  UIHand.draw(layout.cards, cards, selected.card, fontSmall, fontMedium)
  UIAbilities.draw(layout.right, abilities, selected.ability, fontSmall, fontMedium)

  -- watermark
  love.graphics.setFont(fontSmall)
  love.graphics.setColor(0.8, 0.85, 0.95, 0.6)
  love.graphics.print("LOVE2D UI Shell — Hex Grid + Panels", 10, 6)
end

function love.mousepressed(x, y, button)
  -- UI takes precedence over grid
  local hit
  hit = UIWeapons.hit(x, y); if hit then selected.weapon = hit; return end
  hit = UIHand.hit(x, y);     if hit then selected.card   = (selected.card == hit) and nil or hit; return end
  hit = UIAbilities.hit(x, y);if hit then selected.ability= (selected.ability == hit) and nil or hit; return end

  -- Grid interactions
  if pointInRect(x, y, layout.grid) then
    local q, r = HexGrid.pixel_to_axial(x, y, layout.grid)
    if not HexMap.in_bounds(q, r) then return end

    if button == 1 then
      if not Entities.occupied(q, r) then Entities.move(playerId, q, r) end
    elseif button == 2 then
      if not Entities.occupied(q, r) then Entities.spawn{ type = "enemy", q = q, r = r } end
    elseif button == 3 then
      Entities.remove_at(q, r)
    end
  end
end

function love.keypressed(key)
  if key == "escape" then love.event.quit() end
  if key == "r" then init_cards(love.math.random(5, 10)) end
end
```

---

## Run it

* Put the files in place, then drag the **mygame** folder onto `love.exe`, or open a terminal in the folder and run:

```
love .
```

### Controls

* **Esc**: quit
* **R**: randomize the number of cards (test the layout)

---

## Next suggestions

* Replace placeholder cards/abilities/weapons with your data structures.
* Add hover/click interactions (e.g., highlight, tooltip, selection).
* Add a simple camera for the grid (pan with right mouse, zoom with wheel).
* Swap the background grid to a proper map later (Tiled + STI or your own generator).

---

## `src/game/entities.lua`

````lua
local Entities = { list = {}, by_cell = {} }

local function key(q, r) return tostring(q) .. "|" .. tostring(r) end

function Entities.reset()
  Entities.list = {}
  Entities.by_cell = {}
end

function Entities.spawn(t)
  local e = {
    type = t.type or "enemy",
    q = t.q, r = t.r,
    name = t.name,
  }
  e.id = #Entities.list + 1
  Entities.list[e.id] = e
  Entities.by_cell[key(e.q, e.r)] = e.id
  return e.id
end

function Entities.get(id)
  return Entities.list[id]
end

function Entities.at(q, r)
  local id = Entities.by_cell[key(q, r)]
  if id then return Entities.list[id], id end
end

function Entities.occupied(q, r)
  return Entities.by_cell[key(q, r)] ~= nil
end

function Entities.move(id, q, r)
  local e = Entities.list[id]
  if not e then return false end
  if Entities.occupied(q, r) then return false end
  Entities.by_cell[key(e.q, e.r)] = nil
  e.q, e.r = q, r
  Entities.by_cell[key(q, r)] = id
  return true
end

function Entities.remove_at(q, r)
  local id = Entities.by_cell[key(q, r)]
  if not id then return false end
  Entities.by_cell[key(q, r)] = nil
  Entities.list[id] = nil
  return true
end

function Entities.all()
  return Entities.list
end

return Entities
```lua
local Entities = { list = {}, by_cell = {} }

local function key(q, r) return tostring(q) .. "|" .. tostring(r) end

function Entities.reset()
  Entities.list = {}
  Entities.by_cell = {}
end

function Entities.spawn(t)
  local e = {
    type = t.type or "enemy",
    q = t.q, r = t.r,
    name = t.name,
  }
  e.id = #Entities.list + 1
  Entities.list[e.id] = e
  Entities.by_cell[key(e.q, e.r)] = e.id
  return e.id
end

function Entities.get(id)
  return Entities.list[id]
end

function Entities.at(q, r)
  local id = Entities.by_cell[key(q, r)]
  if id then return Entities.list[id], id end
end

function Entities.occupied(q, r)
  return Entities.by_cell[key(q, r)] ~= nil
end

function Entities.move(id, q, r)
  local e = Entities.list[id]
  if not e then return false end
  if Entities.occupied(q, r) then return false end
  Entities.by_cell[key(e.q, e.r)] = nil
  e.q, e.r = q, r
  Entities.by_cell[key(q, r)] = id
  return true
end

function Entities.remove_at(q, r)
  local id = Entities.by_cell[key(q, r)]
  if not id then return false end
  Entities.by_cell[key(q, r)] = nil
  Entities.list[id] = nil
  return true
end

function Entities.all()
  return Entities.list
end

return Entities
````

---

## `src/game/hexmap.lua`

````lua
local HexMap = {}

-- For now, allow infinite bounds; constrain later with a radius or rectangle
function HexMap.in_bounds(q, r)
  return true
end

function HexMap.neighbors(q, r)
  local dirs = {{1,0},{1,-1},{0,-1},{-1,0},{-1,1},{0,1}}
  local out = {}
  for i = 1, #dirs do
    local d = dirs[i]
    out[#out+1] = { q + d[1], r + d[2] }
  end
  return out
end

return HexMap
```lua
local HexMap = {}

-- For now, we allow infinite bounds; constrain later if desired
function HexMap.in_bounds(q, r)
  return true
end

function HexMap.neighbors(q, r)
  local dirs = {{1,0},{1,-1},{0,-1},{-1,0},{-1,1},{0,1}}
  local out = {}
  for i = 1, #dirs do
    local d = dirs[i]
    out[#out+1] = { q + d[1], r + d[2] }
  end
  return out
end

return HexMap
````

---

## `src/ui/theme.lua`

```lua
local Theme = {}
Theme.bg      = {0.10, 0.11, 0.12}
Theme.panelBg = {0.08, 0.09, 0.10, 0.85}
Theme.panelLn = {0.35, 0.4, 0.48, 0.8}
Theme.fg      = {0.95, 0.98, 1.0, 1}
Theme.fgSoft  = {0.85, 0.9,  1.0, 0.9}
Theme.player  = {0.2,  0.65, 1.0, 0.9}
Theme.enemy   = {1.0,  0.25, 0.25,0.9}
Theme.selFill = {0.22, 0.17, 0.28,0.9}
Theme.normFill= {0.16, 0.17, 0.2, 0.9}
Theme.selLine = {0.5,  0.55, 0.65,0.8}
Theme.r       = 10
return Theme
```

---

## `src/ui/panel.lua`

```lua
local Theme = require("src.ui.theme")
local Panel = {}

function Panel.draw(rect, title, font)
  love.graphics.setColor(Theme.panelBg)
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, Theme.r, Theme.r)
  love.graphics.setColor(Theme.panelLn)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, Theme.r, Theme.r)
  if title then
    love.graphics.setFont(font)
    love.graphics.setColor(Theme.fg)
    love.graphics.print(title, rect.x + 10, rect.y + 8)
  end
end

return Panel
```

---

## `src/ui/hand.lua`

```lua
local Theme = require("src.ui.theme")
local Panel = require("src.ui.panel")

local M = { rects = {} }

local function pointInRect(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function M.draw(rect, cards, selectedIndex, fontSmall, fontMedium)
  Panel.draw(rect, "Hand", fontMedium)
  M.rects = {}

  local pad = 12
  local gap = 10
  local count = #cards
  local card_w = math.max(120, (rect.w - pad*2 - gap*(count-1)) / count)
  local card_h = rect.h - pad*2 - 26
  local mx, my = love.mouse.getPosition()

  for i = 1, count do
    local x = rect.x + pad + (i-1) * (card_w + gap)
    local y = rect.y + pad + 26
    local r = { x = x, y = y, w = card_w, h = card_h }
    local hover = pointInRect(mx, my, r)
    local isSel = (selectedIndex == i)

    love.graphics.setColor( (hover and 0.22 or (isSel and 0.20 or 0.18)), 0.2, (hover and 0.26 or (isSel and 0.25 or 0.23)), 0.95)
    love.graphics.rectangle("fill", x, y, card_w, card_h, Theme.r, Theme.r)
    love.graphics.setColor(0.55, 0.6, 0.7, 0.9)
    love.graphics.setLineWidth(isSel and 3 or 2)
    love.graphics.rectangle("line", x, y, card_w, card_h, Theme.r, Theme.r)

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(Theme.fg)
    love.graphics.printf(cards[i].title, x + 10, y + 10, card_w - 20, "left")
    love.graphics.setColor(0.8, 0.85, 0.95, 0.9)
    love.graphics.printf(cards[i].subtitle, x + 10, y + 28, card_w - 20, "left")

    M.rects[i] = r
  end
end

function M.hit(x, y)
  for i, r in ipairs(M.rects) do if pointInRect(x,y,r) then return i end end
end

return M
```

---

## `src/ui/abilities.lua`

```lua
local Theme = require("src.ui.theme")
local Panel = require("src.ui.panel")

local M = { rects = {} }

local function pointInRect(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function M.draw(rect, abilities, selectedIndex, fontSmall, fontMedium)
  Panel.draw(rect, "Abilities", fontMedium)
  M.rects = {}

  local pad = 12
  local title_h = 26
  local gap = 10

  local x = rect.x + pad
  local y = rect.y + pad + title_h
  local w = rect.w - 2*pad
  local h = rect.h - 2*pad - title_h

  local max_visible = 5
  local visible = math.min(max_visible, #abilities)
  local slot_h = math.floor((h - gap * (visible - 1)) / visible)
  if slot_h > 60 then slot_h = 60 end

  for i = 1, visible do
    local ability = abilities[i]
    local ry = y + (i-1) * (slot_h + gap)
    local r = { x = x, y = ry, w = w, h = slot_h }
    local isSel = (selectedIndex == i)

    love.graphics.setColor(isSel and Theme.selFill or Theme.normFill)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, Theme.r, Theme.r)
    love.graphics.setColor(Theme.selLine)
    love.graphics.setLineWidth(isSel and 3 or 2)
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h, Theme.r, Theme.r)

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(Theme.fg)
    love.graphics.print(ability.name or tostring(ability), r.x + 12, r.y + math.max(8, slot_h/2 - 8))

    M.rects[i] = r
  end
end

function M.hit(x, y)
  for i, r in ipairs(M.rects) do if pointInRect(x,y,r) then return i end end
end

return M
```

---

## `src/ui/weapons.lua`

```lua
local Theme = require("src.ui.theme")
local Panel = require("src.ui.panel")

local M = { rects = {} }

local function pointInRect(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function M.draw(rect, weapons, selectedIndex, fontSmall, fontMedium)
  Panel.draw(rect, "Weapons", fontMedium)
  M.rects = {}

  local pad = 12
  local title_h = 26
  local inner_x = rect.x + pad
  local inner_y = rect.y + pad + title_h
  local inner_w = rect.w - 2*pad
  local inner_h = rect.h - 2*pad - title_h

  local slots = 2
  local gap = pad
  local slot_h = (inner_h - gap * (slots - 1)) / slots

  for i = 1, slots do
    local y = inner_y + (i - 1) * (slot_h + gap)
    local r = { x = inner_x, y = y, w = inner_w, h = slot_h }
    local isSel = (selectedIndex == i)

    love.graphics.setColor(isSel and Theme.selFill or Theme.normFill)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 8, 8)
    love.graphics.setColor(Theme.selLine)
    love.graphics.setLineWidth(isSel and 3 or 2)
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h, 8, 8)

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(Theme.fg)
    love.graphics.print(weapons[i].slot .. ": " .. weapons[i].name, r.x + 10, r.y + 10)

    M.rects[i] = r
  end
end

function M.hit(x, y)
  for i, r in ipairs(M.rects) do if pointInRect(x,y,r) then return i end end
end

return M
```

---

## `src/core/camera.lua`

```lua
-- Stub camera; swap in real pan/zoom later
local Cam = { x = 0, y = 0, zoom = 1 }
function Cam.apply() end
function Cam.screen_to_world(x,y) return x, y end
function Cam.world_to_screen(x,y) return x, y end
return Cam
```

local Layout  = require("src.layout")
local HexGrid = require("src.hexgrid")

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

-- Grid entities (axial coordinates)
local player = { q = 0, r = 0 }
local enemies = {
  { q =  2, r = 0 },
  { q = -1, r = 1 },
}

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

local function enemy_at(q, r)
  for i, e in ipairs(enemies) do
    if e.q == q and e.r == r then return i end
  end
end

local function occupied(q, r)
  if player.q == q and player.r == r then return "player" end
  local idx = enemy_at(q, r)
  if idx then return "enemy", idx end
end

function love.load()
  love.graphics.setBackgroundColor(0.10, 0.11, 0.12)
  fontSmall  = love.graphics.newFont(12)
  fontMedium = love.graphics.newFont(16)
  init_cards(5)
end

function love.resize(w, h)
  -- no body needed; layout recomputed in draw
end

local function draw_panel(rect, title)
  love.graphics.setColor(0.08, 0.09, 0.10, 0.85)
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 10, 10)
  love.graphics.setColor(0.35, 0.4, 0.48, 0.8)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 10, 10)
  if title then
    love.graphics.setFont(fontMedium)
    love.graphics.setColor(0.9, 0.95, 1.0, 0.9)
    love.graphics.print(title, rect.x + 10, rect.y + 8)
  end
end

local function draw_weapons(rect)
  draw_panel(rect, "Weapons")
  local pad = 12
  local title_h = 26 -- leave room for the panel title text

  -- Inner content area (inside padding + below title)
  local inner_x = rect.x + pad
  local inner_y = rect.y + pad + title_h
  local inner_w = rect.w - 2 * pad
  local inner_h = rect.h - 2 * pad - title_h

  local slots = 2
  local gap = pad
  local slot_h = (inner_h - gap * (slots - 1)) / slots -- even split with one gap

  for i = 1, slots do
    local y = inner_y + (i - 1) * (slot_h + gap)
    local r = { x = inner_x, y = y, w = inner_w, h = slot_h }

    local isSel = (selected.weapon == i)
    love.graphics.setColor(isSel and 0.22 or 0.16, 0.17, isSel and 0.28 or 0.2, 0.9)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 8, 8)
    love.graphics.setColor(0.5, 0.55, 0.65, 0.8)
    love.graphics.setLineWidth(isSel and 3 or 2)
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h, 8, 8)

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.9, 0.95, 1.0, 0.9)
    love.graphics.print(weapons[i].slot .. ": " .. weapons[i].name, r.x + 10, r.y + 10)

    -- store rect for clicks
    weapons[i].rect = r
  end
end

local function draw_cards(rect)
  draw_panel(rect, "Hand")
  local pad = 12
  local gap = 10
  local count = #cards
  local card_w = math.max(120, (rect.w - pad*2 - gap*(count-1)) / count)
  local card_h = rect.h - pad*2 - 26 -- leave room for title
  local mx, my = love.mouse.getPosition()

  for i = 1, count do
    local x = rect.x + pad + (i-1) * (card_w + gap)
    local y = rect.y + pad + 26
    local r = { x = x, y = y, w = card_w, h = card_h }
    local hover = pointInRect(mx, my, r)
    local isSel = (selected.card == i)

    love.graphics.setColor( (hover and 0.22 or (isSel and 0.20 or 0.18)), 0.2, (hover and 0.26 or (isSel and 0.25 or 0.23)), 0.95)
    love.graphics.rectangle("fill", x, y, card_w, card_h, 10, 10)
    love.graphics.setColor(0.55, 0.6, 0.7, 0.9)
    love.graphics.setLineWidth(isSel and 3 or 2)
    love.graphics.rectangle("line", x, y, card_w, card_h, 10, 10)

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.95, 0.98, 1, 1)
    love.graphics.printf(cards[i].title, x + 10, y + 10, card_w - 20, "left")
    love.graphics.setColor(0.8, 0.85, 0.95, 0.9)
    love.graphics.printf(cards[i].subtitle, x + 10, y + 28, card_w - 20, "left")

    cards[i].rect = r -- store for clicks
  end
end

local function draw_abilities(rect)
  draw_panel(rect, "Abilities")
  local pad = 12
  local title_h = 26
  local gap = 10

  -- Inner content area
  local x = rect.x + pad
  local y = rect.y + pad + title_h
  local w = rect.w - 2*pad
  local h = rect.h - 2*pad - title_h

  -- Fit up to 5 abilities without cutting off
  local max_visible = 5
  local visible = math.min(max_visible, #abilities)
  local slot_h = math.floor((h - gap * (visible - 1)) / visible)
  -- keep a pleasant size but ensure it fits
  if slot_h > 60 then slot_h = 60 end

  for i = 1, visible do
    local ability = abilities[i]
    local ry = y + (i-1) * (slot_h + gap)
    local r = { x = x, y = ry, w = w, h = slot_h }
    local isSel = (selected.ability == i)

    love.graphics.setColor(isSel and 0.22 or 0.16, 0.17, isSel and 0.28 or 0.2, 0.9)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 10, 10)
    love.graphics.setColor(0.5, 0.55, 0.65, 0.8)
    love.graphics.setLineWidth(isSel and 3 or 2)
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h, 10, 10)

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.95, 0.98, 1, 1)
    love.graphics.print(ability.name or tostring(ability), r.x + 12, r.y + math.max(8, slot_h/2 - 8))

    abilities[i].rect = r -- store for clicks
  end
end

local function draw_hex_highlight(q, r, area)
  love.graphics.setColor(0.9, 0.95, 1.0, 0.15)
  love.graphics.polygon("fill", HexGrid.hex_points(q, r, area))
  love.graphics.setColor(0.9, 0.95, 1.0, 0.7)
  love.graphics.setLineWidth(2)
  love.graphics.polygon("line", HexGrid.hex_points(q, r, area))
end

local function draw_entity(q, r, area, filled)
  local cx, cy = HexGrid.axial_to_screen(q, r, area)
  love.graphics.setLineWidth(2)
  if filled then
    love.graphics.circle("fill", cx, cy, HexGrid.size * 0.45)
  else
    love.graphics.circle("line", cx, cy, HexGrid.size * 0.5)
  end
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

  -- 2) Entities (player + enemies)
  love.graphics.setColor(0.2, 0.65, 1.0, 0.9) -- player color
  draw_entity(player.q, player.r, layout.grid, true)

  love.graphics.setColor(1.0, 0.25, 0.25, 0.9) -- enemies color
  for _, e in ipairs(enemies) do
    draw_entity(e.q, e.r, layout.grid, true)
  end

  -- 3) UI overlays
  draw_weapons(layout.weapons)
  draw_cards(layout.cards)
  draw_abilities(layout.right)

  -- watermark
  love.graphics.setFont(fontSmall)
  love.graphics.setColor(0.8, 0.85, 0.95, 0.6)
  love.graphics.print("LOVE2D UI Shell — Hex Grid + Panels", 10, 6)
end

function love.mousepressed(x, y, button)
  -- UI takes precedence over grid
  -- weapons
  for i = 1, #weapons do
    if weapons[i].rect and pointInRect(x, y, weapons[i].rect) then
      selected.weapon = i
      print("Selected weapon:", weapons[i].name)
      return
    end
  end
  -- cards
  for i = 1, #cards do
    if cards[i].rect and pointInRect(x, y, cards[i].rect) then
      selected.card = (selected.card == i) and nil or i
      print("Selected card:", cards[i].title)
      return
    end
  end
  -- abilities
  for i = 1, #abilities do
    if abilities[i].rect and pointInRect(x, y, abilities[i].rect) then
      selected.ability = (selected.ability == i) and nil or i
      print("Selected ability:", abilities[i].name)
      return
    end
  end

  -- Grid interactions
  if pointInRect(x, y, layout.grid) then
    local q, r = HexGrid.pixel_to_axial(x, y, layout.grid)
    if button == 1 then
      -- move player if tile not occupied by enemy
      local occ, idx = occupied(q, r)
      if occ ~= "enemy" then
        player.q, player.r = q, r
      end
    elseif button == 2 then
      -- right click: place an enemy if empty
      if not occupied(q, r) then
        enemies[#enemies+1] = { q = q, r = r }
      end
    elseif button == 3 then
      -- middle click: remove enemy at tile
      local _, idx = occupied(q, r)
      if idx then table.remove(enemies, idx) end
    end
  end
end

function love.keypressed(key)
  if key == "escape" then love.event.quit() end
  if key == "r" then init_cards(love.math.random(5, 10)) end -- random hand size to test layout
end
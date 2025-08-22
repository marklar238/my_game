local Layout = require("src.layout")
local HexGrid = require("src.hexgrid")


local layout -- computed each frame in case of resize
local fontSmall, fontMedium


-- Fake data for UI placeholders
local cards = {}
local abilities = {"Cleave", "Dash", "Taunt", "Fireball", "Heal"}
local weapons = {
  { name = "Longsword", slot = "Main Hand" },
  { name = "Kite Shield", slot = "Off Hand" }
}


local function init_cards(n)
  cards = {}
  for i = 1, n do
    cards[i] = { title = "Card " .. i, subtitle = (i % 2 == 0) and "Rare" or "Common" }
  end
end


function love.load()
  love.graphics.setBackgroundColor(0.10, 0.11, 0.12)
  fontSmall = love.graphics.newFont(12)
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

--[[local function draw_weapons(rect)
  draw_panel(rect, "Weapons")
  local pad = 12
  local slot_h = (rect.h - 3*pad) / 2
  for i = 1, 2 do
    local y = rect.y + pad + (i-1) * (slot_h + pad)
    local r = {x = rect.x + pad, y = y, w = rect.w - 2*pad, h = slot_h}
    love.graphics.setColor(0.16, 0.17, 0.2, 0.9)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 8, 8)
    love.graphics.setColor(0.5, 0.55, 0.65, 0.8)
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h, 8, 8)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.9, 0.95, 1.0, 0.9)
    love.graphics.print(weapons[i].slot .. ": " .. weapons[i].name, r.x + 10, r.y + 10)
  end
end]]

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


    love.graphics.setColor(0.16, 0.17, 0.2, 0.9)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 8, 8)
    love.graphics.setColor(0.5, 0.55, 0.65, 0.8)
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h, 8, 8)


    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.9, 0.95, 1.0, 0.9)
    love.graphics.print(weapons[i].slot .. ": " .. weapons[i].name, r.x + 10, r.y + 10)
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
    local hover = (mx >= x and mx <= x+card_w and my >= y and my <= y+card_h)


    love.graphics.setColor(hover and 0.22 or 0.18, 0.2, hover and 0.26 or 0.23, 0.95)
    love.graphics.rectangle("fill", x, y, card_w, card_h, 10, 10)
    love.graphics.setColor(0.55, 0.6, 0.7, 0.9)
    love.graphics.rectangle("line", x, y, card_w, card_h, 10, 10)


    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.95, 0.98, 1, 1)
    love.graphics.printf(cards[i].title, x + 10, y + 10, card_w - 20, "left")
    love.graphics.setColor(0.8, 0.85, 0.95, 0.9)
    love.graphics.printf(cards[i].subtitle, x + 10, y + 28, card_w - 20, "left")
  end
end

local function draw_abilities(rect)
  draw_panel(rect, "Abilities")
  local pad = 12
  local slot_h = 60
  local gap = 10
  local x = rect.x + pad
  local y = rect.y + pad + 40
  local w = rect.w - 2*pad


  for i, name in ipairs(abilities) do
    local ry = y + (i-1) * (slot_h + gap)
    if ry + slot_h > rect.y + rect.h - pad then break end
    love.graphics.setColor(0.16, 0.17, 0.2, 0.9)
    love.graphics.rectangle("fill", x, ry, w, slot_h, 10, 10)
    love.graphics.setColor(0.5, 0.55, 0.65, 0.8)
    love.graphics.rectangle("line", x, ry, w, slot_h, 10, 10)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.95, 0.98, 1, 1)
    love.graphics.print(name, x + 12, ry + 20)
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


  -- 2) UI overlays
  draw_weapons(layout.weapons)
  draw_cards(layout.cards)
  draw_abilities(layout.right)


  -- debug outlines (toggleable): comment out if not needed
  --[[
  love.graphics.setColor(1,0,0,0.25); love.graphics.rectangle("line", layout.grid.x, layout.grid.y, layout.grid.w, layout.grid.h)
  love.graphics.setColor(0,1,0,0.25); love.graphics.rectangle("line", layout.bottom.x, layout.bottom.y, layout.bottom.w, layout.bottom.h)
  love.graphics.setColor(0,0,1,0.25); love.graphics.rectangle("line", layout.right.x, layout.right.y, layout.right.w, layout.right.h)
  ]]


  -- watermark
  love.graphics.setFont(fontSmall)
  love.graphics.setColor(0.8, 0.85, 0.95, 0.6)
  love.graphics.print("LOVE2D UI Shell — Hex Grid + Panels", 10, 6)
end


function love.keypressed(key)
  if key == "escape" then love.event.quit() end
  if key == "r" then init_cards(love.math.random(5, 10)) end -- random hand size to test layout
end
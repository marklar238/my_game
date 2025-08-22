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
  init_cards(5)

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
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

  local mx, my = love.mouse.getPosition()

  for i = 1, visible do
    local ability = abilities[i]
    local ry = y + (i-1) * (slot_h + gap)
    local r = { x = x, y = ry, w = w, h = slot_h }
    local isSel = (selectedIndex == i)
    local hover = pointInRect(mx, my, r)

    love.graphics.setColor( (hover and 0.22 or (isSel and 0.20 or 0.18)), 0.2, (hover and 0.26 or (isSel and 0.25 or 0.23)), 0.95)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, Theme.r, Theme.r)

    love.graphics.setColor(0.55, 0.6, 0.7, 0.9)
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
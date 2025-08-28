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

  local slots = math.min(2, #weapons)
  local gap = pad
  local slot_h = (inner_h - gap * (slots - 1)) / slots

  local mx, my = love.mouse.getPosition()

  for i = 1, slots do
    local y = inner_y + (i - 1) * (slot_h + gap)
    local r = { x = inner_x, y = y, w = inner_w, h = slot_h }
    local isSel = (selectedIndex == i)
    local hover = pointInRect(mx, my, r)

    love.graphics.setColor( (hover and 0.22 or (isSel and 0.20 or 0.18)), 0.2, (hover and 0.26 or (isSel and 0.25 or 0.23)), 0.95)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 8, 8)

    love.graphics.setColor(0.55, 0.6, 0.7, 0.9)
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
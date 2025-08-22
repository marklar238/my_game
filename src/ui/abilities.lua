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
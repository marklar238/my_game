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
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
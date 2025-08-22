local State = { current = nil }

function State.set(s)
  State.current = s
  if s and s.enter then s:enter() end
end

function State.update(dt)       if State.current and State.current.update       then State.current:update(dt) end end
function State.draw()           if State.current and State.current.draw         then State.current:draw() end end
function State.mousepressed(x,y,b) if State.current and State.current.mousepressed then State.current:mousepressed(x,y,b) end end
function State.keypressed(k)    if State.current and State.current.keypressed   then State.current:keypressed(k) end end

return State
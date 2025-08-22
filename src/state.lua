local State = { current = nil }

function State.set(next)
  State.current = next
  if next and next.enter then next:enter() end
end

function State.update(dt)
  if State.current and State.current.update then State.current:update(dt) end
end

function State.draw()
  if State.current and State.current.draw then State.current:draw() end
end

return State

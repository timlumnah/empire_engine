local Paddle = {}
Paddle.__index = Paddle

function Paddle:new(x, y, width, height)
    local self = setmetatable({}, Paddle)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dy = 0
    return self
end

function Paddle:update(dt)
    self.y = self.y + self.dy * dt
end

function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end

return Paddle
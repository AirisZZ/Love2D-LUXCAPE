local Player = {}

function Player:new(x, y, size)
    local player = {
        x = x,
        y = y,
        size = size,
        speed = 150,
        angle = 0,
        glowSize = size * 1.5,
        glowAlpha = 0.5,
        trail = {},
        maxTrailLength = 10
    }
    setmetatable(player, { __index = self })
    return player
end

function Player:update(dt, maze, camera)
    local dx, dy = 0, 0
    
    if love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end
    if love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end
    
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len
    end
    
    local newX = self.x + dx * self.speed * dt
    local newY = self.y + dy * self.speed * dt
    
    if not maze:isWall(newX, self.y) then
        self.x = newX
    end
    
    if not maze:isWall(self.x, newY) then
        self.y = newY
    end
    
    local mouseX, mouseY = love.mouse.getPosition()
    local worldMouseX, worldMouseY = camera:toWorldCoords(mouseX, mouseY)
    
    self.angle = math.atan2(worldMouseY - self.y, worldMouseX - self.x)
    
    if dx ~= 0 or dy ~= 0 then
        table.insert(self.trail, 1, {x = self.x, y = self.y, alpha = 1})
        if #self.trail > self.maxTrailLength then
            table.remove(self.trail)
        end
    end
    
    for i, point in ipairs(self.trail) do
        point.alpha = point.alpha - dt * 2
        if point.alpha < 0 then point.alpha = 0 end
    end
    
    self.glowAlpha = 0.3 + math.sin(love.timer.getTime() * 3) * 0.2
end

function Player:draw()
    for i, point in ipairs(self.trail) do
        love.graphics.setColor(1, 1, 1, point.alpha * 0.2)
        love.graphics.circle("fill", point.x, point.y, self.size * 0.5 * (1 - i/#self.trail))
    end
    
    love.graphics.setColor(0.2, 0.4, 1, self.glowAlpha)
    love.graphics.circle("fill", self.x, self.y, self.glowSize)
    
    love.graphics.setColor(1, 1, 1)
    
    love.graphics.push()
    
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)
    
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.rectangle("fill", -self.size/2, -self.size/2, self.size, self.size)
    
    love.graphics.setColor(0.1, 0.2, 0.4)
    love.graphics.rectangle("fill", self.size/4, -self.size/4, self.size/4, self.size/2)
    
    love.graphics.pop()
end

function Player:checkGoalCollision(goalX, goalY, goalSize)
    local playerLeft = self.x - self.size/2
    local playerRight = self.x + self.size/2
    local playerTop = self.y - self.size/2
    local playerBottom = self.y + self.size/2
    
    local goalLeft = goalX - goalSize/2
    local goalRight = goalX + goalSize/2
    local goalTop = goalY - goalSize/2
    local goalBottom = goalY + goalSize/2
    
    return playerRight > goalLeft and
           playerLeft < goalRight and
           playerBottom > goalTop and
           playerTop < goalBottom
end

return Player
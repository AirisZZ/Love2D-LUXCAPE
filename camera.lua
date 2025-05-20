local Camera = {}

function Camera:new(target)
    local camera = {
        target = target,
        x = target.x,
        y = target.y,
        scale = 1,
        minScale = 0.5,
        maxScale = 2,
        smoothSpeed = 5,
        shake = {
            intensity = 0,
            duration = 0,
            timer = 0
        }
    }
    setmetatable(camera, { __index = self })
    return camera
end

function Camera:update(dt)
    local targetX = self.target.x
    local targetY = self.target.y
    
    self.x = self.x + (targetX - self.x) * self.smoothSpeed * dt
    self.y = self.y + (targetY - self.y) * self.smoothSpeed * dt
    
    if self.shake.timer > 0 then
        self.shake.timer = self.shake.timer - dt
        if self.shake.timer <= 0 then
            self.shake.intensity = 0
        end
    end
end

function Camera:set()
    love.graphics.push()
    
    local width, height = love.graphics.getDimensions()
    love.graphics.translate(width/2, height/2)
    
    if self.shake.intensity > 0 then
        local shakeX = (math.random() * 2 - 1) * self.shake.intensity
        local shakeY = (math.random() * 2 - 1) * self.shake.intensity
        love.graphics.translate(shakeX, shakeY)
    end
    
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:unset()
    love.graphics.pop()
end

function Camera:zoom(amount)
    self.scale = self.scale + amount
    
    if self.scale < self.minScale then
        self.scale = self.minScale
    elseif self.scale > self.maxScale then
        self.scale = self.maxScale
    end
end

function Camera:shake(intensity, duration)
    self.shake.intensity = intensity
    self.shake.duration = duration
    self.shake.timer = duration
end

function Camera:toWorldCoords(screenX, screenY)
    local width, height = love.graphics.getDimensions()
    local worldX = (screenX - width/2) / self.scale + self.x
    local worldY = (screenY - height/2) / self.scale + self.y
    
    return worldX, worldY
end

return Camera
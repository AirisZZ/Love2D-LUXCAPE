local Particles = {}

function Particles:new()
    local particles = {
        effects = {}
    }
    setmetatable(particles, { __index = self })
    return particles
end

function Particles:update(dt)
    local i = 1
    while i <= #self.effects do
        self.effects[i].lifetime = self.effects[i].lifetime - dt
        if self.effects[i].lifetime <= 0 then
            table.remove(self.effects, i)
        else
            if self.effects[i].update then
                self.effects[i]:update(dt)
            end
            i = i + 1
        end
    end
end

function Particles:draw()
    for _, effect in ipairs(self.effects) do
        effect:draw()
    end
end

function Particles:createScanEffect(x, y, targetX, targetY)
    local angle = math.atan2(targetY - y, targetX - x)
    
    for i = 1, 30 do
        local particleAngle = angle + (math.random() - 0.5) * 0.5
        local speed = 100 + math.random() * 100
        local maxDist = 300
        

        table.insert(self.effects, {
            x = x,
            y = y,
            vx = math.cos(particleAngle) * speed,
            vy = math.sin(particleAngle) * speed,
            size = 2 + math.random() * 3,
            lifetime = 0.2 + math.random() * 0.3,
            maxLifetime = 0.2 + math.random() * 0.3,
            collided = false,
            
            update = function(self, dt)
                if not self.collided then
                    local newX = self.x + self.vx * dt
                    local newY = self.y + self.vy * dt
                    

                    local dx = newX - x
                    local dy = newY - y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist > maxDist then
                        self.collided = true
                    else

                        local rayAngle = math.atan2(dy, dx)
                        local hitX, hitY, hitDist = _G.maze:raycast(x, y, rayAngle, dist)
                        
                        if hitDist < dist then

                            self.x = hitX
                            self.y = hitY
                            self.collided = true
                        else

                            self.x = newX
                            self.y = newY
                        end
                    end
                    
                    self.vx = self.vx * 0.95
                    self.vy = self.vy * 0.95
                end
            end,
            
            draw = function(self)
                local alpha = self.lifetime / self.maxLifetime
                love.graphics.setColor(0.5, 0.8, 1, alpha * 0.8)
                love.graphics.circle("fill", self.x, self.y, self.size * alpha)
            end
        })
    end
    
    table.insert(self.effects, {
        x = x,
        y = y,
        targetX = targetX,
        targetY = targetY,
        lifetime = 0.3,
        draw = function(self)
            local progress = 1 - (self.lifetime / 0.3)
            
            local dx = self.targetX - self.x
            local dy = self.targetY - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            local rayAngle = math.atan2(dy, dx)
            
            local hitX, hitY, hitDist = _G.maze:raycast(self.x, self.y, rayAngle, dist)
            
            local maxLength = math.min(progress * 300, hitDist)
            local endX = self.x + math.cos(rayAngle) * maxLength
            local endY = self.y + math.sin(rayAngle) * maxLength
            
            love.graphics.setColor(0.4, 0.8, 1, 0.5 * (1 - progress))
            love.graphics.setLineWidth(2)
            love.graphics.line(self.x, self.y, endX, endY)
            
            love.graphics.setColor(1, 1, 1, 0.8 * (1 - progress))
            love.graphics.setLineWidth(1)
            love.graphics.line(self.x, self.y, endX, endY)
        end
    })
end

function Particles:createVictoryEffect(x, y)
    for i = 1, 200 do
        local angle = math.random() * math.pi * 2
        local speed = 50 + math.random() * 100
        table.insert(self.effects, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = 3 + math.random() * 5,
            lifetime = 1 + math.random() * 2,
            maxLifetime = 1 + math.random() * 2,
            draw = function(self)
                local alpha = self.lifetime / self.maxLifetime
                love.graphics.setColor(0, 1, 0, alpha * 0.8)
                love.graphics.circle("fill", self.x, self.y, self.size * alpha)
                self.x = self.x + self.vx * love.timer.getDelta()
                self.y = self.y + self.vy * love.timer.getDelta()
                self.vx = self.vx * 0.98
                self.vy = self.vy * 0.98
            end
        })
    end
    
    for i = 1, 8 do
        local angle = i * math.pi / 4
        table.insert(self.effects, {
            x = x,
            y = y,
            angle = angle,
            radius = 0,
            maxRadius = 100,
            lifetime = 2,
            draw = function(self)
                local progress = 1 - (self.lifetime / 2)
                self.radius = progress * self.maxRadius
                
                love.graphics.setColor(0, 1, 0, 0.5 * (1 - progress))
                love.graphics.setLineWidth(3)
                love.graphics.line(
                    self.x, self.y,
                    self.x + math.cos(self.angle) * self.radius,
                    self.y + math.sin(self.angle) * self.radius
                )
                
                love.graphics.setColor(0.5, 1, 0.5, 0.8 * (1 - progress))
                love.graphics.circle("fill", 
                    self.x + math.cos(self.angle) * self.radius,
                    self.y + math.sin(self.angle) * self.radius,
                    5 * (1 - progress)
                )
            end
        })
    end
end

return Particles
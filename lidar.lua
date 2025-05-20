local LIDAR = {}

function LIDAR:new(player, maze)
    local lidar = {
        player = player,
        maze = maze,
        scanPoints = {},
        scanRange = 300,
        scanAngle = math.pi / 3,
        scanResolution = 0.02,
        pointLifetime = 5,
        pointSize = 2,
        goalScanned = false,
        scanEffect = {
            active = false,
            angle = 0,
            time = 0,
            duration = 0.3,
            rayHits = {}
        }
    }
    setmetatable(lidar, { __index = self })
    return lidar
end

function LIDAR:update()
    local i = 1
    while i <= #self.scanPoints do
        self.scanPoints[i].lifetime = self.scanPoints[i].lifetime - love.timer.getDelta()
        
        if self.scanPoints[i].lifetime <= 0 then
            table.remove(self.scanPoints, i)
        else
            i = i + 1
        end
    end
    
    if self.scanEffect.active then
        self.scanEffect.time = self.scanEffect.time + love.timer.getDelta()
        if self.scanEffect.time >= self.scanEffect.duration then
            self.scanEffect.active = false
        end
    end
end

function LIDAR:scan(targetX, targetY)
    local dirX = targetX - self.player.x
    local dirY = targetY - self.player.y
    local centerAngle = math.atan2(dirY, dirX)
    
    self.scanEffect.active = true
    self.scanEffect.angle = centerAngle
    self.scanEffect.time = 0
    self.scanEffect.rayHits = {}
    
    local startAngle = centerAngle - self.scanAngle / 2
    local endAngle = centerAngle + self.scanAngle / 2
    
    local rayAngle = startAngle
    while rayAngle <= endAngle do
        local hitX, hitY, dist = self.maze:raycast(self.player.x, self.player.y, rayAngle, self.scanRange)
        
        table.insert(self.scanEffect.rayHits, {
            angle = rayAngle,
            dist = dist,
            x = hitX,
            y = hitY
        })
        
        rayAngle = rayAngle + 0.02 
    end
    
    local angle = startAngle
    while angle <= endAngle do
        local hitX, hitY, dist = self.maze:raycast(self.player.x, self.player.y, angle, self.scanRange)
        
        if dist < self.scanRange then
            local brightness = 1 - (dist / self.scanRange) * 0.5
            table.insert(self.scanPoints, {
                x = hitX,
                y = hitY,
                lifetime = self.pointLifetime,
                brightness = brightness,
                angle = angle,
                dist = dist
            })
        end
        
        local goalDist = math.sqrt((hitX - self.maze.goalX)^2 + (hitY - self.maze.goalY)^2)
        if goalDist < self.maze.goalSize then
            self.goalScanned = true
        end
        
        angle = angle + self.scanResolution
    end
end

function LIDAR:draw()
    if self.scanEffect.active then
        local progress = self.scanEffect.time / self.scanEffect.duration
        
        if #self.scanEffect.rayHits > 0 then
            love.graphics.setColor(0.2, 0.6, 1, 0.2 * (1 - progress))
            
            local vertices = {self.player.x, self.player.y}
            
            for _, hit in ipairs(self.scanEffect.rayHits) do
                local scaledDist = math.min(hit.dist, self.scanRange) * progress
                local rayX = self.player.x + math.cos(hit.angle) * scaledDist
                local rayY = self.player.y + math.sin(hit.angle) * scaledDist
                table.insert(vertices, rayX)
                table.insert(vertices, rayY)
            end
            
            love.graphics.polygon("fill", vertices)
        end
    end
    
    for _, point in ipairs(self.scanPoints) do
        local alpha = point.lifetime / self.pointLifetime
        local size = self.pointSize * (0.8 + point.brightness * 0.4)
        
        love.graphics.setColor(1, 1, 1, alpha * point.brightness)
        love.graphics.circle("fill", point.x, point.y, size)
        
        if point.brightness > 0.8 and math.random() > 0.95 then
            love.graphics.setColor(1, 1, 1, alpha * 0.3)
            love.graphics.circle("fill", point.x, point.y, size * 2)
        end
    end
    
    if self.goalScanned then
        love.graphics.setColor(0, 1, 0, 0.3 + math.sin(love.timer.getTime() * 2) * 0.1)
        love.graphics.rectangle("fill", self.maze.goalX - self.maze.goalSize/2, self.maze.goalY - self.maze.goalSize/2, self.maze.goalSize, self.maze.goalSize)
        
        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.rectangle("line", self.maze.goalX - self.maze.goalSize/2, self.maze.goalY - self.maze.goalSize/2, self.maze.goalSize, self.maze.goalSize)
    end
    
    love.graphics.setColor(1, 1, 1)
end

return LIDAR
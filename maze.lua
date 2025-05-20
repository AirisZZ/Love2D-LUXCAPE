local Maze = {}

function Maze:new(width, height, cellSize)
    local maze = {
        width = width,
        height = height,
        cellSize = cellSize,
        grid = {},
        walls = {},
        goalX = 0,
        goalY = 0,
        goalSize = cellSize * 2
    }
    setmetatable(maze, { __index = self })
    
    for y = 1, height do
        maze.grid[y] = {}
        for x = 1, width do
            maze.grid[y][x] = 1
        end
    end
    
    maze:generateMaze()
    maze:createWalls()
    maze:placeGoal()
    
    return maze
end

function Maze:generateMaze()
    local stack = {}
    local startX, startY = 2, 2
    
    self.grid[startY][startX] = 0
    table.insert(stack, {x = startX, y = startY})
    
    while #stack > 0 do
        local current = stack[#stack]
        local neighbors = self:getUnvisitedNeighbors(current.x, current.y)
        
        if #neighbors > 0 then
            local next = neighbors[math.random(#neighbors)]
            
            local wallX = current.x + math.floor((next.x - current.x) / 2)
            local wallY = current.y + math.floor((next.y - current.y) / 2)
            self.grid[wallY][wallX] = 0
            
            self.grid[next.y][next.x] = 0
            
            table.insert(stack, next)
        else
            table.remove(stack)
        end
    end
    
    local midX, midY = math.floor(self.width / 2), math.floor(self.height / 2)
    
    for y = midY-1, midY+1 do
        for x = midX-1, midX+1 do
            if y >= 1 and y <= self.height and x >= 1 and x <= self.width then
                self.grid[y][x] = 0
            end
        end
    end
    
    self:widenCorridors()
end

function Maze:widenCorridors()
    local tempGrid = {}
    for y = 1, self.height do
        tempGrid[y] = {}
        for x = 1, self.width do
            tempGrid[y][x] = self.grid[y][x]
        end
    end
    
    for y = 2, self.height-1 do
        for x = 2, self.width-1 do
            if self.grid[y][x] == 1 then
                local adjacentPaths = 0
                
                if self.grid[y-1][x] == 0 then adjacentPaths = adjacentPaths + 1 end
                if self.grid[y+1][x] == 0 then adjacentPaths = adjacentPaths + 1 end
                if self.grid[y][x-1] == 0 then adjacentPaths = adjacentPaths + 1 end
                if self.grid[y][x+1] == 0 then adjacentPaths = adjacentPaths + 1 end
                
                if adjacentPaths >= 3 then
                    tempGrid[y][x] = 0
                end
            end
        end
    end
    
    self.grid = tempGrid
end

function Maze:getUnvisitedNeighbors(x, y)
    local neighbors = {}
    local directions = {
        {x = 2, y = 0},
        {x = -2, y = 0},
        {x = 0, y = 2},
        {x = 0, y = -2}
    }
    
    for _, dir in ipairs(directions) do
        local nx, ny = x + dir.x, y + dir.y
        if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height and self.grid[ny][nx] == 1 then
            table.insert(neighbors, {x = nx, y = ny})
        end
    end
    
    return neighbors
end

function Maze:placeGoal()
    local farthestX, farthestY, maxDist = 0, 0, 0
    local startX, startY = math.floor(self.width / 2), math.floor(self.height / 2)
    
    for y = 1, self.height do
        for x = 1, self.width do
            if self.grid[y][x] == 0 then
                local dist = (x - startX)^2 + (y - startY)^2
                if dist > maxDist then
                    maxDist = dist
                    farthestX = x
                    farthestY = y
                end
            end
        end
    end
    
    for y = farthestY-1, farthestY+1 do
        for x = farthestX-1, farthestX+1 do
            if y >= 1 and y <= self.height and x >= 1 and x <= self.width then
                self.grid[y][x] = 0
            end
        end
    end
    
    self.goalX = (farthestX - 0.5) * self.cellSize
    self.goalY = (farthestY - 0.5) * self.cellSize
end

function Maze:createWalls()
    for y = 1, self.height do
        for x = 1, self.width do
            if self.grid[y][x] == 1 then
                local wx = (x - 1) * self.cellSize
                local wy = (y - 1) * self.cellSize
                
                table.insert(self.walls, {
                    x = wx,
                    y = wy,
                    width = self.cellSize,
                    height = self.cellSize
                })
            end
        end
    end
end

function Maze:isWall(x, y)
    local gridX = math.floor(x / self.cellSize) + 1
    local gridY = math.floor(y / self.cellSize) + 1
    
    if gridX < 1 or gridX > self.width or gridY < 1 or gridY > self.height then
        return true
    end
    
    return self.grid[gridY][gridX] == 1
end

function Maze:raycast(startX, startY, angle, maxDist)
    local dx = math.cos(angle)
    local dy = math.sin(angle)
    
    for dist = 0, maxDist, 1 do
        local x = startX + dx * dist
        local y = startY + dy * dist
        
        if self:isWall(x, y) then
            return x, y, dist
        end
    end
    
    return startX + dx * maxDist, startY + dy * maxDist, maxDist
end

return Maze
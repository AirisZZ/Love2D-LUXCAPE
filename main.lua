local Player = require("player")
local Maze = require("maze")
local LIDAR = require("lidar")
local Camera = require("camera")
local Particles = require("particles")

local player
local maze
local lidar
local camera
local particles
local gameWidth, gameHeight
local gameState = "playing"

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
    
    gameWidth, gameHeight = love.graphics.getDimensions()
    
    local cellSize = 30
    local mazeWidth, mazeHeight = 30, 30
    maze = Maze:new(mazeWidth, mazeHeight, cellSize)
    
    _G.maze = maze
    
    local playerX = mazeWidth * cellSize / 2
    local playerY = mazeHeight * cellSize / 2
    player = Player:new(playerX, playerY, 15)
    
    lidar = LIDAR:new(player, maze)
    
    camera = Camera:new(player)
    
    particles = Particles:new()
end

function love.update(dt)
    if gameState == "playing" then
        camera:update(dt)
        player:update(dt, maze, camera)
        lidar:update()
        particles:update(dt)
        
        if player:checkGoalCollision(maze.goalX, maze.goalY, maze.goalSize) then
            gameState = "won"
            particles:createVictoryEffect(maze.goalX, maze.goalY)
        end
    else
        particles:update(dt)
    end
end

function love.draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, gameWidth, gameHeight)
    
    camera:set()
    
    love.graphics.setColor(0.05, 0.05, 0.1)
    local gridSize = 50
    local gridExtent = 1000
    for x = -gridExtent, gridExtent, gridSize do
        love.graphics.line(x, -gridExtent, x, gridExtent)
    end
    for y = -gridExtent, gridExtent, gridSize do
        love.graphics.line(-gridExtent, y, gridExtent, y)
    end
    
    lidar:draw()
    
    particles:draw()
    
    player:draw()
    
    if gameState == "won" then
        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.rectangle("fill", maze.goalX - maze.goalSize/2, maze.goalY - maze.goalSize/2, maze.goalSize, maze.goalSize)
    end
    
    camera:unset()
    
    if gameState == "won" then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", gameWidth/2 - 150, gameHeight/2 - 50, 300, 100)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("line", gameWidth/2 - 150, gameHeight/2 - 50, 300, 100)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("You Win!", 0, gameHeight/2 - 30, gameWidth, "center")
        love.graphics.printf("Press 'R' to restart", 0, gameHeight/2, gameWidth, "center")
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and gameState == "playing" then
        local worldX, worldY = camera:toWorldCoords(x, y)
        lidar:scan(worldX, worldY)
        particles:createScanEffect(player.x, player.y, worldX, worldY)
    end
end

function love.wheelmoved(x, y)
    camera:zoom(y * 0.1)
end

function love.keypressed(key)
    if key == "r" and gameState == "won" then
        love.load()
        gameState = "playing"
    end
    
    if key == "escape" then
        love.event.quit()
    end
end
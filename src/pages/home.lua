local config = require("src.config")

local cameraX = 0 
local cameraY = 0
local zoom = 1.0
local displayZoom = 1.0
local isDragging = false

local buttons = {
    {
        id = 1,
        x = 0,
        y = 0,
        size = 80,
        name = "测试",
        description = "一个测试",
        icon = nil,
        color = {1, 1, 1, 0.2},
        link = {
            right = 2
        }
    },
    {
        id = 2,
        x = 360,
        y = 0,
        size = 80,
        name = "测试",
        description = "一个测试",
        icon = nil,
        color = {1, 1, 1, 0.2},
        link = {
            left = 1,
            top = 3
        }
    },
    {
        id = 3,
        x = 360,
        y = -180,
        size = 80,
        name = "测试",
        description = "一个测试",
        icon = nil,
        color = {1, 1, 1, 0.2},
        link = {
            left = 2
        }
    }
}

local dragStartX = 0
local dragStartY = 0
local dragThreshold = 12

function load()
    cameraX = 0
    cameraY = 0
    zoom = 1.0
    isDragging = false
end

function update(dt)
    local diff = zoom - displayZoom
    if math.abs(diff) < 0.01 then
        displayZoom = zoom
    else
        displayZoom = displayZoom + diff / 10
    end
end

function worldToScreen(worldX, worldY)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local screenX = (worldX - cameraX) * zoom + screenWidth / 2
    local screenY = (worldY - cameraY) * zoom + screenHeight / 2
    return screenX, screenY
end

function screenToWorld(screenX, screenY)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local worldX = (screenX - screenWidth / 2) / zoom + cameraX
    local worldY = (screenY - screenHeight / 2) / zoom + cameraY
    return worldX, worldY
end

function draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    love.graphics.clear(table.unpack(config.colors.background))
    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 2)
    love.graphics.scale(displayZoom, displayZoom)
    love.graphics.translate(-cameraX, -cameraY)
    
    for _, button in ipairs(buttons) do
        drawButton(button)
    end
    
    love.graphics.pop()
end

function drawButton(button)
    local halfSize = button.size / 2
    
    love.graphics.setColor(table.unpack(button.color))
    love.graphics.rectangle("fill", button.x - halfSize, button.y - halfSize, button.size, button.size)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x - halfSize, button.y - halfSize, button.size, button.size)
end

function keypressed(key)
    if key == "escape" then
        local main = require("main")
        main.switchState("title")
    end
end

function mousepressed(x, y, button)
    if button == 1 then
        dragStartX = x
        dragStartY = y
        isDragging = true
    end
end

function mousemoved(x, y, dx, dy)
    if isDragging then
        local worldDx = dx / displayZoom
        cameraX = cameraX - worldDx
    end
end

function mousereleased(x, y, button)
    if button == 1 then
        isDragging = false
        
        local moveX = math.abs(x - dragStartX)
        local moveY = math.abs(y - dragStartY)
        local totalMove = math.sqrt(moveX * moveX + moveY * moveY)
        
        if totalMove < dragThreshold then
            local worldX, worldY = screenToWorld(x, y)
            checkButtonClick(worldX, worldY)
        end
    end
end

function wheelmoved(x, y)
    local zoomStep = 0.4
    local minZoom = 0.2
    local maxZoom = 5.0
    
    if y > 0 then
        zoom = math.min(maxZoom, zoom + zoomStep)
    elseif y < 0 then
        zoom = math.max(minZoom, zoom - zoomStep)
    end
end

function checkButtonClick(worldX, worldY)
    for _, button in ipairs(buttons) do
        local halfSize = button.size / 2
        
        if worldX >= button.x - halfSize and worldX <= button.x + halfSize and
           worldY >= button.y - halfSize and worldY <= button.y + halfSize then
           
            print("点击按钮: " .. button.name)
            return true
        end
    end
    return false
end

return {
    load = load,
    update = update,
    draw = draw,
    keypressed = keypressed,
    mousepressed = mousepressed,
    mousemoved = mousemoved,
    mousereleased = mousereleased,
    wheelmoved = wheelmoved
}

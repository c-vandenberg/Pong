Paddle = Class{}

--[[ 
    Initliase Paddle class attributes. Paddle takes x and y for positioning, as well as width and height for its dimensions
]]
function Paddle:init(x, y, width, height)
    self. x = x
    self. y = y
    self.width = width
    self.height = height

    self.dy = 0
end

-- Define paddle update method
function Paddle:update(dt)
    
    -- Ensure paddle cannot do beyong top of screen (y = 0) when user is pressing up
    if self.dy < 0 then -- If dy < 0 paddle is going towards top of screen
        self.y = math.max(0, self.y + self.dy * dt)

    -- Ensure paddle cannot go beyond bottom of screen, i.e VIRTUAL_HEIGHT(bottom of screen) - 20 (paddle height), when user is pressing down
    elseif self.dy > 0 then -- IF dy > 0 paddle is going towards bottom of screen
        self.y = math.min(VIRTUAL_HEIGHT - 20, self.y + self.dy * dt)
    end
end

--[[ 
    Define paddle render method to be called by love.draw
]]
function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end
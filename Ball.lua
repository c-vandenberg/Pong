Ball = Class{}

--[[ 
    Initliase Ball class attributes. Paddle takes x and y for positioning, as well as width and height for its dimensions
]]

function Ball:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    self.dx = math.random(2) == 1 and 100 or -100
    self.dy =  math.random(-50, 50)
end

--[[
    Define collision detection method for rectangles (paddles and ball)
]]

function Ball:collides(box)
    -- Check if left edge of either if father to the right than the right edge of the other
    if self.x > box.x + box.width or self.x + self.width < box.x then
        return false
    end
    -- Check if bottom edge of either is higher than the top edge of the other
    if self.y > box.y + box.height or self.y + self.height < box.y then
        return false
    end 

    -- If the above aren't true, they are overlapping and there is a collision
    return true
end

--[[
   Define method to place the ball in the middle of the screen, with an intiial random velocity on both axes
]]

function Ball:reset()
    -- And resent balls position to starting position          
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2

    -- Ball velocity in x-direction (randomise for left or right direction for beginning of match)
    -- and or statement is ternary operator (i.e if math.random(2) == 1 Boolean is true, ballDX = -100, or left. But if math.random(2) == 1 Boolean is flase, ballDX = 100, or right)
    self.dx = math.random(2) == 1 and 100 or -100

    -- Ball velocity in y-direction (random range of values between -50 and 50)
    -- Both dx and dy velocities will give random angles the ball will move at the beginning of the match
    self.dy = math.random(-50, 50) * 1.5
end

--[[
    Define method to apply velocity to positiob, scaled by dt
]]

function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function Ball:render()
    -- Render ball in center of screen
    love.graphics.rectangle('fill', self.x, self.y, 4, 4)
end

-- Global variable to maintain 16:9 aspect ratio on physical window by stretching virtual raster to this size
WINDOW_HEIGHT = 720 
WINDOW_WIDTH = 1280 

-- Global variables to maintain 16:9 aspect ratio when we emulate smaller screen size/zooming in by drawing to a virtual raster
VIRTUAL_WIDTH = 432 
VIRTUAL_HEIGHT = 243 

-- Set paddle movement speed (in px/s)
PADDLE_SPEED = 200

-- Import class library 
Class = require 'class'

-- https://github.com/Ulydev/push
push = require 'push' -- Import push library so we can draw to a virtual raster

-- Declare Ball and Paddle classes
require 'Ball'
require 'Paddle'

--[[
    love.load runs when the game starts up, only once; used to initialise the game
]]

function love.load()
    -- Seed random number generator with Unix time to 'randomise' ball velocity
    math.randomseed(os.time())

    -- This uses neares-neighbour filtering n upscaling and downscaling to pervent blurring of text and graphics to get retro pixel look. This is nearest neighbour interpolation vs billinear interpolation.
    love.graphics.setDefaultFilter('nearest', 'nearest') 

    -- Create small font object for text with font.ttf file
    smallFont = love.graphics.newFont('font.ttf', 8)

    -- Create score font object for score with font.ttf file
    scoreFont = love.graphics.newFont('font.ttf', 32)

    -- Initialise our virtual raster/virtual resolution, which will be rendered within our actual window no matter it's dimensions. 
    -- Curly braces represent 'table' data structure, the only data structure in Lua, akin to a dictionary in Python, with key-value pairs 
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, { 
        fullscreen = false, -- Window cannot be made fullscreen to maintain aspect ratio
        vsync = true, -- Sync to monitors refresh rate (so we don't see any screen tearing)
        resizable = false -- Window cannot be resized to maintain aspect ratio
    })

    -- Initialise/Declare players score
    player1Score = 0
    player2Score = 0

    -- Instantiate paddle starting positions
    paddle1 = Paddle(5, 20, 5, 20)
    paddle2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- Instatiate ball starting position
    ball = Ball(VIRTUAL_WIDTH / 2 -2, VIRTUAL_HEIGHT / 2 - 2, 5, 5)

    gameState = 'start'

end

--[[
    Set up movement of paddles (dt allows us to have paddle speed remain constant no matter the frame rate. Higher frame rates on different devices could cause a lagging effect with dt.)
]]

function love.update(dt)

    paddle1:update(dt)
    paddle2:update(dt)
    
    -- Collision detection
    if ball:collides(paddle1) then
        -- Deflect ball to the right
        ball.dx = -ball.dx
    end
    if ball:collides(paddle2) then
        -- Deflect ball to the left
        ball.dx = -ball.dx
    end

    -- If ball is at top of screen
    if ball.y <= 0 then
        -- Deflect the ball down
        ball.dy = -ball.dy
        ball.y = 0
    end

    -- If ball is at bottom of screen
    if ball.y >= VIRTUAL_HEIGHT - 4 then
        -- Deflect ball up
        ball.dy = -ball.dy
        ball.y = VIRTUAL_HEIGHT - 4 
    end


    -- Player 1 paddle movement
    -- Add negative paddle speed to current y-coordinate scaled by dt for upward movement
    if love.keyboard.isDown('w') then
        paddle1.dy = -PADDLE_SPEED

    -- Add positive paddle speed to current y-coordinate scaled by dt for downward movement
    elseif love.keyboard.isDown('s') then
        paddle1.dy = PADDLE_SPEED

    else
        paddle1.dy = 0
    end

    -- Player 2 paddle movement
    -- Add negative paddle speed to current y-coordinate scaled by dt for upward movement
    if love.keyboard.isDown('up') then
        paddle2.dy = -PADDLE_SPEED

    -- Add positive paddle speed to current y-coordinate scaled by dt for downward movement
    elseif love.keyboard.isDown('down') then
        paddle2.dy = PADDLE_SPEED
    else
        paddle2.dy = 0
    end

    -- Set ball velocity when game state switches to play
    -- Remember we need to multiply all updates by dx to ensure consistent movement rendering no matter framerate
    if gameState == 'play' then
        ball:update(dt)
    end
end

--[[
    Keyboard handling, called by LÖVE each frame; passes in the key we pressed so we can access
]]

function love.keypressed(key)
    if key == 'escape' then -- IF users presses esc key, application quits
        love.event.quit()
    
    -- Change game state to 'play' when user presses enter key (return key for mac)
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then 
            gameState = 'play'
        elseif gameState == 'play' then 

            -- Reset game state to 'start' if user presses enter/return key when game state == play
            gameState ='start'

            ball:reset()

        end 
    end
end

--[[
    love.draw is called after update by LÖVE
]]

function love.draw()

    -- Begin using 'push' to begin drawing to virtual raster
    push:apply('start')

    -- Apply background colour (has to be before we draw anything else as it will cover anything drawn before it)
    -- Have to divide RGB value by 255 because LÖVE treats each value as 0.0 - 1.0 to map the values 0 - 255
    love.graphics.clear(40 / 255, 45 / 255, 52 / 255, 255 / 255)


    -- Set small font object
    love.graphics.setFont(smallFont)

    if gameState == 'start' then
        -- Draw 'Hello Pong' welcome text at top of screen if game state == start
        love.graphics.printf(
            'Hello Pong!',              -- Text to render
            0,                          -- Starting x-coordinate = 0 (since we're going to center it based on width)
            20,                         -- Starting y-coordinate = WINDOW_HEIGHT / 2 - 6 (Halfway down the screen. -6 because font-size = 12 px)
            VIRTUAL_WIDTH,              -- Number of pixels to center within (the entire screen width in this case)
            'center')                   -- Alignment mode, can be 'center', 'left' or 'right'
    
    elseif gameState == 'play' then
        -- Draw 'Hello, Play State' text at top of screen if game state == play
        love.graphics.printf('Hello Play State!', 0, 20, VIRTUAL_WIDTH, 'center')
    end

    -- Set score font object    
    love.graphics.setFont(scoreFont)

    -- Draw players scores
    love.graphics.print(player1Score, VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(player2Score, VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)

    -- Draw Pong 'ball'
    ball:render()

    -- Draw pong left 'paddle'
    paddle1:render()

    -- Draw pong right 'paddle'
    paddle2:render()

    displayFPS()
    
    -- End drawing to virtual raster/end rendering at virtual resolution
    push:apply('end') 
end

-- Display FPS across all game states
function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10) -- .. is the Lua string concatenation operator.
    love.graphics.setColor(255, 255, 255, 255) -- Reset default color to white
end

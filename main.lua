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

    -- Set title for application
    love.window.setTitle('Pong')

    -- Create small font object for text with font.ttf file
    smallFont = love.graphics.newFont('font.ttf', 8)

    -- Create score font object for score with font.ttf file
    scoreFont = love.graphics.newFont('font.ttf', 32)

    -- Create victory font object with font.ttf file
    victoryFont = love.graphics.newFont('font.ttf', 24)

    -- Initialise sound effects table
    sounds = {
        ['paddle_hit'] = love.audio.newSource('paddle-hit.wav', 'static'),
        ['point_scored'] = love.audio.newSource('point-scored.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('wall-hit.wav', 'static')
    }

    -- Initialise our virtual raster/virtual resolution, which will be rendered within our actual window no matter it's dimensions. 
    -- Curly braces represent 'table' data structure, the only data structure in Lua, akin to a dictionary in Python, with key-value pairs 
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, { 
        fullscreen = false,
        vsync = true, -- Sync to monitors refresh rate (so we don't see any screen tearing)
        resizable = true
    })

    -- Initialise/Declare players score
    player1Score = 0
    player2Score = 0

    -- Initialise winner 
    winner = 0

    -- Instantiate paddle starting positions
    paddle1 = Paddle(5, 20, 5, 20)
    paddle2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- Instatiate ball starting position
    ball = Ball(VIRTUAL_WIDTH / 2 -2, VIRTUAL_HEIGHT / 2 - 2, 5, 5)

    -- 'Coin flip' to decide who gets to serve first
    servingPlayer = math.random(2) == 1 and 1 or 2

    -- Set starting velocity of ball after coin clip depending on what player won coin flip
    if servingPlayer == 1 then
        ball.dx = 100
    else
        ball.dx = - 100
    end

    gameState = 'start'
end

-- Maintain aspect ratio on window resizing
function love.resize(width, height)
    push:resize(width, height)
end

--[[
    Set up movement of paddles (dt allows us to have paddle speed remain constant no matter the frame rate. Higher frame rates on different devices could cause a lagging effect with dt.)
]]
function love.update(dt)

    if gameState == 'play' then

        -- Paddle 1 collision detection
        if ball:collides(paddle1) then

            -- Deflect ball to the right and slightly increase ball velocity
            ball.dx = -ball.dx * 1.03
            ball.x = paddle1.x + 5

            -- Paddle collision sound effect
            sounds['paddle_hit']:play()
        end

        -- Paddle 2 collision detection
        if ball:collides(paddle2) then

            -- Deflect ball to the left and slightly increase ball velocity
            ball.dx = -ball.dx * 1.03
            ball.x = paddle2.x - 4

            -- Paddle collision sound effect
            sounds['paddle_hit']:play()
        end

        --  Top of screen collision detection
        if ball.y <= 0 then

            -- Deflect the ball down
            ball.dy = -ball.dy
            ball.y = 0

            -- Wall collision sound effect
            sounds['wall_hit']:play()
        end

        -- Bottom of screen collision detection
        if ball.y >= VIRTUAL_HEIGHT - 4 then

            -- Deflect ball up
            ball.dy = -ball.dy
            ball.y = VIRTUAL_HEIGHT - 4 

            -- Wall collision sound effect
            sounds['wall_hit']:play()
        end

        --  Player 1 has scored
        if ball.x >= VIRTUAL_WIDTH - 4 then

            -- Point scored sound effect and update score
            sounds['point_scored']:play()
            player1Score = player1Score + 1

            --Set serving player to be player 2 and reset ball
            servingPlayer = 2
            ball:reset()

            -- If player 1 scores, we want player 2 to serve so ball must go towards player 1 after serve
            ball.dx = - 100

            -- Check if player 1 score is 10
            if player1Score == 10 then

                -- End game and declare plater 1 the winnner if true
                gameState = 'victory'
                winner = 'Player 1'

            else
                -- Continue game if flase
                gameState = 'serve'
            end
        end

        -- Player 2 has scored
        if ball.x <= 0 then

            -- Point scored sound effect and update score
            sounds['point_scored']:play()
            player2Score = player2Score + 1

            -- Set serving player to be player 1 and reset ball
            servingPlayer = 1
            ball:reset()

            -- If player 2 scores, we want player 1 to serve so ball must go towards player 2 after serve
            ball.dx = 100

            -- Check if player 2 score is 10
            if player2Score == 10 then

                -- End game and declare player 2 the winner if true
                gameState = 'victory'
                winner = 'Player 2'

            else
                -- Continue game if false
                gameState = 'serve'
            end
        end

        -- Player 1 paddle movement
        -- Add negative paddle speed to current y-coordinate scaled by dt for upward movement
        if love.keyboard.isDown('w') then
            paddle1.dy = -PADDLE_SPEED

        -- Add positive paddle speed to current y-coordinate scaled by dt for downward movement
        elseif love.keyboard.isDown('s') then
            paddle1.dy = PADDLE_SPEED
        
        -- If keys aren't pressed paddle 1 velocity = 0
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

        -- If keys aren't pressed paddle 2 velocity = 0
        else
            paddle2.dy = 0
        end

        -- Update ball when game state = play
        if gameState == 'play' then
            ball:update(dt)
        end

        -- Update paddes
        paddle1:update(dt)
        paddle2:update(dt)       
    end
end

--[[
    Keyboard handling, called by LÖVE each frame; passes in the key pressed
]]
function love.keypressed(key)

    -- If user presses esc key, applcation quits
    if key == 'escape' then
        love.event.quit()
    end
    
    -- Change game state to 'serve' or 'play' when user presses space key depending on current game state
    if key == 'space' then
        if gameState == 'start' then 
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'

        -- If game state = victory when reset players scores and restart game
        elseif gameState == 'victory' then
            player1Score = 0
            player2Score = 0
            gameState = 'start'
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

    -- Render welcome message when game state = start
    if gameState == 'start' then
        love.graphics.printf('Welcome to Pong!', 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Space to Play', 0, 32, VIRTUAL_WIDTH, 'center')
    
    -- Render message to show which player is serving
    elseif gameState == 'serve' then
        love.graphics.printf("Player " .. tostring(servingPlayer) .. "'s turn!", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Space to Serve', 0, 32, VIRTUAL_WIDTH, 'center')

    -- Render victory message
    elseif gameState == 'victory' then
        love.graphics.setFont(victoryFont)
        love.graphics.printf(tostring(winner) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Space to Restart", 0, 42, VIRTUAL_WIDTH, 'center')
        ball:reset()
    end

    -- Set score font object    
    love.graphics.setFont(scoreFont)

    -- Render players scores
    love.graphics.print(player1Score, VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(player2Score, VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)

    -- Render Pong 'ball'
    ball:render()

    -- Render pong left 'paddle'
    paddle1:render()

    -- Render pong right 'paddle'
    paddle2:render()

    displayFPS()

    
    -- End rendering to virtual raster/end rendering at virtual resolution
    push:apply('end') 
end

-- Display FPS across all game states
function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10) -- .. is the Lua string concatenation operator.
    love.graphics.setColor(255, 255, 255, 255) -- Reset default color to white
end
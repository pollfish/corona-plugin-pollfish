local pollfish = require( "plugin.pollfish" );

local widget = require( "widget" );
widget.setTheme( "widget_theme_ios" );

-- Pollfish params

local pos = 0;
local indPadding = 0;
local apiKey = "";
local debugMode = true;
local customMode = false;
local requestUUID = "";

-- Pollfish indicator positions

local PollFishPositionTopLeft, PollFishPositionBottomLeft,PollFishPositionTopRight,PollFishPositionBottomRight,PollFishPositionMiddleLeft,PollFishPositionMiddleRight = 0, 1, 2, 3, 4, 5

-- Logging label

local txt = display.newText("Logging area..", display.contentWidth * 0.5,  display.contentHeight * 0.8, native.sytemFont, 10);

-- Listen for Pollfish events/notifications

local function listenerFunc(event)

    print("[Pollfish] listenerFunc: " .. tostring(event.phase))

    if event.phase == "onPollfishSurveyReceived" then

        print("Pollfish - onPollfishSurveyReceived")
        txt.text="onPollfishSurveyReceived";

    elseif event.phase == "onPollfishSurveyCompleted" then

        print("Pollfish - onPollfishSurveyCompleted")
        txt.text="onPollfishSurveyCompleted";

    elseif event.phase == "onPollfishSurveyNotAvailable" then

        print("Pollfish - onPollfishSurveyNotAvailable")
        txt.text="onPollfishSurveyNotAvailable";

    elseif event.phase == "onUserNotEligible" then

        print("Pollfish - onUserNotEligible")
        txt.text="onUserNotEligible";

    elseif event.phase == "onPollfishOpened" then

        print("Pollfish - onPollfishOpened")
        txt.text="onPollfishOpened";

    elseif event.phase == "onPollfishClosed" then

        print("Pollfish - onPollfishClosed")
        txt.text="onPollfishClosed";

    else

        print("Pollfish - event not recognised: " .. tostring(event.phase))

    end


end

-- Intit Pollfish Button

local pollfishInitButton = widget.newButton
{
	label = "Init";
	
    onRelease = function( event )

        pollfish.init(
        {
            pos = PollFishPositionTopRight,
            indPadding = 50,
            apiKey = "YOUR_API_KEY",
            debugMode = true,
            customMode = false,
            requestUUID = "my_uuid",
            listener = listenerFunc,
        }
        );

        
	end,
}

pollfishInitButton.x = display.contentCenterX;
pollfishInitButton.y = 130;

-- Show Pollfish Button

local pollfishShowButton = widget.newButton
{
	label = "Show",
	
    onRelease = function( event )
		
        pollfish.show(listenerFunc)
	
    end,
}


pollfishShowButton.x = display.contentCenterX;
pollfishShowButton.y = pollfishInitButton.y + pollfishInitButton.contentHeight + pollfishShowButton.contentHeight * 0.5;

-- Hide Pollfish Button

local hidePollfishButton = widget.newButton
{
	label = "Hide",
    
	onRelease = function( event )
    
		pollfish.hide(listenerFunc)
        
	end,
}

hidePollfishButton.x = display.contentCenterX;
hidePollfishButton.y = pollfishShowButton.y + pollfishShowButton.contentHeight + hidePollfishButton.contentHeight * 0.5;

-- Register to listen and handle system events

local function systemEvent( event )

    local phase = event.phase;

	if event.type == 'applicationResume' then

        print("applicationResume")

    elseif event.type == 'applicationStart' then

        print("applicationStart")

    end
	
	return true

end


Runtime:addEventListener( 'system', systemEvent );





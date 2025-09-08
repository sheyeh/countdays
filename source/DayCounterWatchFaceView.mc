// DayCounterWatchFaceView.mc
// This is the main view class where all the drawing happens.

using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.ActivityMonitor as Am;

//! The main WatchFace View
class DayCounterWatchFaceView extends Ui.WatchFace {

    private var yellowRibbon;
    private var screenWidth;
    private var screenHeight;
    private var centerX;
    private var centerY;
    private var myFont;
    private var hand_width;
    private var pen_width;
    private var hasFloorsClimbed;
    private var stepsXPos;

    private var heartIcon;
    private var stairsIcon;
    private var stepsIcon;

    private var batteryIcon100;
    private var batteryIcon75;
    private var batteryIcon50;
    private var batteryIcon25;
    private var batteryIconLow;

    //! Constructor
    function initialize() {
        WatchFace.initialize();
        hasFloorsClimbed = Am.getInfo() != null && Am.getInfo() has :floorsClimbed;
        stepsXPos = hasFloorsClimbed ? 0.2 : 0.425;
    }

    //! Load resources at startup.
    function onLayout(dc as Gfx.Dc) {
        // Get screen dimensions for layout calculations
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;

        var hi_res = screenWidth > 280;
        // Load the custom graphics.
        yellowRibbon = hi_res
            ? Ui.loadResource(Rez.Drawables.yellowRibbonBitmap)
            : Ui.loadResource(Rez.Drawables.yellowRibbonBitmapLow);

        myFont = hi_res
            ? Ui.loadResource(Rez.Fonts.MyFont)
            : Ui.loadResource(Rez.Fonts.MyFont8);

        heartIcon = Ui.loadResource(Rez.Drawables.heart);
        stairsIcon = Ui.loadResource(Rez.Drawables.stairs);
        stepsIcon = Ui.loadResource(Rez.Drawables.steps);

        batteryIcon100 = Ui.loadResource(Rez.Drawables.battery100);
        batteryIcon75 = Ui.loadResource(Rez.Drawables.battery75);
        batteryIcon50 = Ui.loadResource(Rez.Drawables.battery50);
        batteryIcon25 = Ui.loadResource(Rez.Drawables.battery25);
        batteryIconLow = Ui.loadResource(Rez.Drawables.battery15);
    
        hand_width = hi_res ? 10.0 : 6.0;
        pen_width = hi_res ? 3 : 2;
    }

    //! This method is called when the device re-enters an active state.
    //! In this state, it can update more frequently and show more data.
    function onEnterSleep() {
        // Clear the screen and prepare for low-power mode
        Ui.requestUpdate();
    }

    //! This method is called when the device exits an active state.
    //! In this state, it updates less frequently and should use a simple drawing.
    function onExitSleep() {
        // Clear the screen and draw in high-power mode.
        Ui.requestUpdate();
    }

    const OCT_7_2023 = Time.Gregorian.moment({
        :year => 2023,
        :month => 10,
        :day => 7,
        :hour => 0,
        :minute => 0,
        :second => 0
    });

    //! --- Calculate days passed since October 7, 2023 ---
    function daysSinceOct7() {
        // Get the current date
        var today = new Time.Moment(Time.today().value());
        // Calculate the difference in days
        var duration = today.subtract(OCT_7_2023);
        // convert seconds to days, adding 2 to include both start and end dates
        return duration.value() / (60 * 60 * 24) + 2;
    }

    //! This method is called to update the watch face.
    //! It draws the graphics and data fields on the screen.
    function onUpdate(dc) {
        // Clear the screen with a black background
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        // Draw yellow ribbon as background using the whole screen
        if (yellowRibbon != null) {
            dc.drawBitmap(0, 0, yellowRibbon);
        }
        drawDaysCount(dc);
        drawBattery(dc);
        drawHeartRate(dc);
        drawFloors(dc);
        drawSteps(dc);
        drawDate(dc);
        drawAnalogTime(dc);
    }

    const JUST = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;

    //! Draw the number of days since October 7, 2023
    function drawDaysCount(dc) {
        var dayCountText = daysSinceOct7().toString();
        var posx = screenWidth * 0.75;
        var posy = screenHeight * 0.25;
    
        // draw red shadow
        dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(posx + 2, posy + 2, myFont, dayCountText, JUST);
        // draw yellow text
        dc.setColor(0xFFCC00, Gfx.COLOR_TRANSPARENT);
        dc.drawText(posx, posy, myFont, dayCountText, JUST);
    }

    function drawDate(dc) {
        var dateInfo = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$ $2$", [dateInfo.day_of_week, dateInfo.day]);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth * 0.93, // X position
            screenHeight / 2, // Y position
            Gfx.FONT_XTINY,
            dateString,
            Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    const RED_BATTERY_LEVEL = 10;

    function drawBattery(dc) {
        var battery = Sys.getSystemStats().battery;
        var batteryIcon =
                    battery <= RED_BATTERY_LEVEL ? batteryIconLow : 
                    battery < 30 ? batteryIcon25 :
                    battery < 60 ? batteryIcon50 :
                    battery < 85 ? batteryIcon75 :
                    batteryIcon100;

        // battery icons are scaled to 9% of screen size in resources/drawables/drawables.xml
        dc.drawBitmap(screenWidth * 0.055, screenHeight * 0.455, batteryIcon);
        dc.setColor(
            battery <= RED_BATTERY_LEVEL ? Gfx.COLOR_RED : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth * 0.16, // X position
            screenHeight * 0.5, // Y position
            Gfx.FONT_XTINY,
            format("$1$%", [battery.format("%d")]),
            Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    function drawHeartRate(dc) {
        var hrSample = Am.getHeartRateHistory(1, true).next();
        var hr = hrSample != null ? hrSample.heartRate : 0;
        if (hr > 0) {
            drawMetric(dc, heartIcon, hr, 0.425, 0.9);
        }
    }

    function drawMetric(dc, icon, value, posXFactor, posYFactor) {
        if (value != null) {
            dc.drawBitmap(
                screenWidth * posXFactor,
                screenHeight * posYFactor,
                icon
            );
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(
                screenWidth * (posXFactor + 0.08),
                screenHeight * posYFactor,
                Gfx.FONT_XTINY,
                format("$1$", [value.toString()]),
                Gfx.TEXT_JUSTIFY_LEFT
            );
        }
    }

    function drawFloors(dc) {
        if (hasFloorsClimbed == false) {
            return;
        } 
        var info = Am.getInfo(); // make sure data is fresh
        if (info != null && info.floorsClimbed != null) {
            drawMetric(dc, stairsIcon, info.floorsClimbed, 0.64, 0.78);
        }
    }

    function drawSteps(dc) {
        var info = Am.getInfo(); // make sure data is fresh
        if (info != null && info.steps != null) {
            drawMetric(dc, stepsIcon, thousandsSeparator(info.steps), stepsXPos, 0.78);
        }
    }

    function thousandsSeparator(num) {
        if (num < 1000) {
            return num.toString();
        } else if (num < 1e6) {
            return (num / 1000).format("%d") + "," + (num % 1000).format("%03d");
        } else {
            // Handle the very unlikely event of more than a million steps in one day
            return (num / 1e6).format("%.1f") + "M";
        }
    }

    function drawAnalogTime(dc) {
        var now = Sys.getClockTime();
        var hours = now.hour % 12;
        var minutes = now.min;
        var seconds = 15 * (now.sec / 15); // Round to nearest 10 seconds for smoother movement

        // Calculate angles for the hands
        var hourAngle = (hours + minutes / 60.0) * (Math.PI / 6); // 30 degrees per hour
        var minuteAngle = (minutes + seconds / 60.0) * (Math.PI / 30); // 6 degrees per minute

        // Draw the hands
        drawRotatedHand(dc, minuteAngle, screenWidth * 0.45, Gfx.COLOR_TRANSPARENT, Gfx.COLOR_WHITE);
        drawRotatedHand(dc, hourAngle, screenWidth * 0.25, Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
    }

    //! A utility function to draw a rotated rectangle for the watch hands.
    //! @param dc The drawing context.
    //! @param angle The angle in radians.
    //! @param height The length of the hand.
    //! @param color_fill The fill color of the hand.
    //! @param color_out The outline color of the hand.
    function drawRotatedHand(dc, angle, height, color_fill, color_out) {
        var halfWidth = hand_width / 2.0;

        // Define the unrotated vertices of the rectangle.
        var points = [
            [-halfWidth, -height], // Top-left
            [halfWidth, -height],  // Top-right
            [halfWidth, -10],        // Bottom-right
            [-halfWidth, -10]        // Bottom-left
        ];

        // Rotate and translate the points.
        var ZERO = [0.0, 0.0];
        var rotatedPoints = [ZERO, ZERO, ZERO, ZERO];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        
        for (var i = 0; i < 4; i++) {
            var x = points[i][0];
            var y = points[i][1];
            
            // Apply rotation
            var newX = x * cos - y * sin;
            var newY = x * sin + y * cos;
            
            // Translate to the center of the watch face
            rotatedPoints[i] = [centerX + newX, centerY + newY];
        }

        // Draw the polygon
        dc.setColor(color_fill, color_fill);
        dc.setPenWidth(1);
        dc.fillPolygon(rotatedPoints);
        dc.setColor(color_out, color_out);
        dc.setPenWidth(pen_width);
        for (var i = 0; i < 4; i++) {
            var nextIndex = (i + 1) % 4;
            dc.drawLine(
                rotatedPoints[i][0], rotatedPoints[i][1],
                rotatedPoints[nextIndex][0], rotatedPoints[nextIndex][1]
            );
        }
    }
}

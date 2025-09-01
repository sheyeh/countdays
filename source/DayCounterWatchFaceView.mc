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

    //! Constructor
    function initialize() {
        WatchFace.initialize();
        myFont = Application.loadResource(Rez.Fonts.MyFont);
    }

    //! Load resources at startup.
    function onLayout(dc as Gfx.Dc) {
        // Get screen dimensions for layout calculations
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;

        // Load the custom graphics.
        yellowRibbon = Ui.loadResource(Rez.Drawables.yellowRibbonBitmap);
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
        dc.drawText(posx + 3, posy + 3, myFont, dayCountText, JUST);
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
        var batteryResource =
                        battery <= RED_BATTERY_LEVEL ? Rez.Drawables.battery15 : 
                        battery < 30 ? Rez.Drawables.battery25 :
                        battery < 60 ? Rez.Drawables.battery50 :
                        battery < 85 ? Rez.Drawables.battery75 :
                        Rez.Drawables.battery100;

        // battery icons are scaled to 9% of screen size in resources/drawables/drawables.xml
        dc.drawBitmap(screenWidth * 0.055, screenHeight * 0.455, Ui.loadResource(batteryResource));
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
        var hr = hrSample !=null ? hrSample.heartRate : 0;
        if (hr > 0) {
            // heart icon is scaled to 7% of screen size in resources/drawables/drawables.xml
            dc.drawBitmap(
                screenWidth * 0.425,
                screenHeight * 0.9,
                Ui.loadResource(Rez.Drawables.heart)
            );
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(
                screenWidth * 0.505,
                screenHeight * 0.9,
                Gfx.FONT_XTINY,
                format("$1$", [hr.toString()]),
                Gfx.TEXT_JUSTIFY_LEFT
            );
        }
    }

    function drawAnalogTime(dc) {
        var now = Sys.getClockTime();
        var hours = now.hour % 12;
        var minutes = now.min;
        var seconds = now.sec;

        // Calculate angles for the hands
        var hourAngle = (hours + minutes / 60.0) * (Math.PI / 6); // 30 degrees per hour
        var minuteAngle = (minutes + seconds / 60.0) * (Math.PI / 30); // 6 degrees per minute

        // Draw the hands
        drawRotatedHand(dc, minuteAngle, screenWidth * 0.45, Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        drawRotatedHand(dc, hourAngle, screenWidth * 0.25, Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
    }

    const HAND_WIDTH = 8.0;
    //! A utility function to draw a rotated rectangle for the watch hands.
    //! @param dc The drawing context.
    //! @param angle The angle in radians.
    //! @param height The length of the hand.
    //! @param color_fill The fill color of the hand.
    //! @param color_out The outline color of the hand.
    function drawRotatedHand(dc, angle, height, color_fill, color_out) {
        var halfWidth = HAND_WIDTH / 2.0;

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
        dc.setPenWidth(1);
        for (var i = 0; i < 4; i++) {
            var nextIndex = (i + 1) % 4;
            dc.drawLine(
                rotatedPoints[i][0], rotatedPoints[i][1],
                rotatedPoints[nextIndex][0], rotatedPoints[nextIndex][1]
            );
        }
    }
}

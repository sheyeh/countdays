// DayCounterWatchFaceApp.mc
// This is the application entry point.

using Toybox.Application as App;
using Toybox.WatchUi as Ui;

//! The main application class
class DayCounterWatchFaceApp extends App.AppBase {

    //! Constructor
    function initialize() {
        AppBase.initialize();
    }

    //! On app startup, create the initial view
    //! @return Array of View and InputDelegate
    function getInitialView() {
        return [ new DayCounterWatchFaceView() ];
    }
}

// DayCounterWatchFaceView.mc
// This is the main view class where all the drawing happens.

using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Greg;
using Toybox.ActivityMonitor as Am;
using Toybox.Sensor as Sensor;

//! The main WatchFace View
class DayCounterWatchFaceView extends Ui.WatchFace {

    private var yellowRibbon;
    private var screenWidth;
    private var screenHeight;

    //! Constructor
    function initialize() {
        WatchFace.initialize();
    }

    //! Load resources at startup.
    function onLayout(dc as Gfx.Dc) {
        // Get screen dimensions for layout calculations
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();

        // Load the custom graphics.
        yellowRibbon = Ui.loadResource(Rez.Drawables.yellowRibbonBitmap);

        // Load fonts for the data fields. You can create custom fonts if desired.
        // fontDayCount = Ui.loadResource(Rez.Fonts.DayCountFont);

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

    const oct_7_2023 = Greg.moment({
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
        var duration = today.subtract(oct_7_2023);
        return duration.value() / (60 * 60 * 24) + 2; // Convert seconds to days
    }

    //! This method is called to update the watch face.
    //! It draws the graphics and data fields on the screen.
    function onUpdate(dc) {
        // Clear the screen with a black background
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        // Draw the custom graphic
        if (yellowRibbon != null) {
            dc.drawScaledBitmap(
                0, // X position
                0, // Y position
                screenWidth, // Width to scale to
                screenWidth, // Height to scale to
                yellowRibbon // Bitmap to draw
            );
        }

        var dayCountText = daysSinceOct7().toString();
        dc.setColor(0xFFCC00, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth * 0.5, // Center the text horizontally
            screenHeight * 0.2, // Top part of the screen
            Gfx.FONT_LARGE,
            dayCountText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // --- Draw the data fields (date, heart rate, battery) ---
        // Draw the date

        drawBattery(dc);
        drawHeartRate(dc);
        drawDate(dc);

    }

    function drawDate(dc) {
        var dateInfo = Greg.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$ $2$ $3$", [dateInfo.day_of_week, dateInfo.month, dateInfo.day]);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth * 0.93, // X position
            screenHeight / 2, // Y position
            Gfx.FONT_XTINY,
            dateString,
            Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER
        );

    }
    function drawBattery(dc) {
        var battery = Sys.getSystemStats().battery;
        var batteryResource =
                        battery <= 10 ? Rez.Drawables.battery15 : 
                        battery < 30 ? Rez.Drawables.battery25 :
                        battery < 60 ? Rez.Drawables.battery50 :
                        battery < 85 ? Rez.Drawables.battery75 :
                        Rez.Drawables.battery100;

        dc.drawScaledBitmap(
            screenWidth * 0.1 - 40, // X position
            screenHeight / 2 - 20, // Y position
            40, // Width to scale to
            40, // Height to scale to
            Ui.loadResource(batteryResource) // Bitmap to draw
        );
        dc.setColor(
            battery <= 10 ? Gfx.COLOR_RED : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth * 0.1 + 5, // X position
            screenHeight / 2, // Y position
            Gfx.FONT_XTINY,
            format("$1$%", [battery.format("%d")]),
            Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER
        );
        
    }

    function drawHeartRate(dc) {
        var hrSample = Am.getHeartRateHistory(1, true).next();
        var hr = hrSample !=null ? hrSample.heartRate : 0;
        if (hr > 0) {
            dc.drawScaledBitmap(
                screenWidth * 0.5 - 30, // X position
                screenHeight * 0.9, // Y position
                30, // Width to scale to
                30, // Height to scale to
                Ui.loadResource(Rez.Drawables.heart) // Bitmap to draw
            );
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(
                screenWidth * 0.5 + 5, // X position
                screenHeight * 0.9, // Y position
                Gfx.FONT_XTINY,
                format("$1$", [hr.toString()]),
                Gfx.TEXT_JUSTIFY_LEFT
            );
        }
    }

}

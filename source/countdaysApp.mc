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
    private var fontDayCount;
    private var fontDataFields;
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
        fontDayCount = Gfx.FONT_LARGE;
        fontDataFields = Gfx.FONT_TINY;
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

    const oct_7_2023 = new Time.Moment(1696649340); // October 7, 2023 in seconds since epoch

    //! --- Calculate days passed since October 7, 2023 ---
    function daysSinceOct7() {
        // Get the current date
        var today = new Time.Moment(Time.today().value());

        // Calculate the difference in days
        var duration = today.subtract(oct_7_2023);
        return duration.value() / (60 * 60 * 24); // Convert seconds to days
    }

    //! This method is called to update the watch face.
    //! It draws the graphics and data fields on the screen.
    function onUpdate(dc) {
        // Clear the screen with a black background
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        var daysPassed = daysSinceOct7();

        // --- Draw the graphics and day count ---

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

        // Draw the day count on the right half
        var dayCountText = daysPassed.toString();
        dc.setColor(0xFFCC00, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth * 0.5, // Center the text horizontally
            screenHeight * 0.2, // Top part of the screen
            fontDayCount,
            dayCountText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // --- Draw the data fields (date, heart rate, battery) ---
        // Position them in a row at the bottom of the screen
        var dataY = screenHeight * 0.85;
        var dataSpacing = screenWidth / 3;

        // Draw the date
        var dateInfo = Greg.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$ $2$ $3$", [dateInfo.day, dateInfo.month, dateInfo.year]);
        dc.drawText(
            dataSpacing * 0.5,
            dataY,
            fontDataFields,
            dateString,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // Draw the heart rate
        var hr = "HR: --";
        var hrIterator = Am.getHeartRateHistory(1, true);
        var hrSample = hrIterator.next();
        if (hrSample != null && hrSample.heartRate != null && hrSample.heartRate > 0) {
            hr = "HR: " + hrSample.heartRate.toString();
        }
        dc.drawText(
            dataSpacing * 1.5,
            dataY,
            fontDataFields,
            hr,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // Draw the battery level
        var stats = Sys.getSystemStats();
        var battery = "Bat: " + stats.battery.toNumber().toString() + "%";
        dc.drawText(
            dataSpacing * 2.5,
            dataY,
            fontDataFields,
            battery,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }
}

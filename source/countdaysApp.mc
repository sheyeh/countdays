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

    private var leftHalfGraphic;
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
        // NOTE: You must place your graphic file in the project's 'resources/drawables/' folder.
        // For example, a file named 'graphic.svg' in that folder will be loaded by this line.
        // You will need to create a `drawables.xml` file in `resources` to define this resource.
        // <drawable-list id="leftHalfGraphic"><bitmap id="leftHalfGraphicBitmap" filename="your_graphic_file_name.svg" /></drawable-list>
        leftHalfGraphic = Ui.loadResource(Rez.Drawables.yellowRibbonBitmap);

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

    //! This method is called to update the watch face.
    //! It draws the graphics and data fields on the screen.
    function onUpdate(dc) {
        // Clear the screen with a black background
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        // Get the current time and date
        var clockTime = Sys.getClockTime();

        // --- Calculate days passed since October 7, 2023 ---
        // Define the start date (October 7, 2023)
        // Create the start date Moment (October 7, 2023)
        var oct_7_2023 = new Time.Moment(1696649340);
        // Get the current date
        var today = new Time.Moment(Time.today().value());

        // Calculate the difference in days
        var duration = today.subtract(oct_7_2023);
        var daysPassed = duration.value() / (60 * 60 * 24); // Convert seconds to days

        // --- Draw the graphics and day count ---
        var graphicWidth = screenWidth / 2;
        var graphicHeight = screenHeight;

        // Draw the custom graphic on the left half
        if (leftHalfGraphic != null) {
            // The graphic is centered vertically in the left half
            var graphicX = (graphicWidth - leftHalfGraphic.getWidth()) / 2;
            var graphicY = (graphicHeight - leftHalfGraphic.getHeight()) / 2;
            dc.drawBitmap(graphicX, graphicY, leftHalfGraphic);
        }

        // Draw the day count on the right half
        var dayCountText = daysPassed.toString();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth * 0.75, // Center the text in the right half
            screenHeight * 0.5, // Center the text vertically
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

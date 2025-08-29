// DayCounterWatchFaceApp.mc
// This is the application entry point.

using Toybox.Application as App;

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


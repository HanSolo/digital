using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Sensor as Sens;
using Toybox.ActivityMonitor as Act;
using Toybox.Attention as Att;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Greg;
using Toybox.Application as App;
using Toybox.UserProfile as UserProfile;

class DigitalView extends Ui.WatchFace {
    enum { WOMAN, MEN }    
    var weekdays = new [7];
    var timeFont, dateFont, valueFont;
    var batteryIcon, bleIcon, bpmIcon, burnedIcon, stepsIcon;
    var heartRate;    

    function initialize() {
        WatchFace.initialize();
    }

    //! Load your resources here
    function onLayout(dc) {        
        timeFont      = Ui.loadResource(Rez.Fonts.digitalUpright66);
        dateFont      = Ui.loadResource(Rez.Fonts.digitalUpright26);
        valueFont     = Ui.loadResource(Rez.Fonts.digitalUpright24);        
        batteryIcon   = Ui.loadResource(Rez.Drawables.battery);
        bleIcon       = Ui.loadResource(Rez.Drawables.ble);
        bpmIcon       = Ui.loadResource(Rez.Drawables.bpm);
        burnedIcon    = Ui.loadResource(Rez.Drawables.burned);
        stepsIcon     = Ui.loadResource(Rez.Drawables.steps);      
        weekdays[0]   = Ui.loadResource(Rez.Strings.Sun);
        weekdays[1]   = Ui.loadResource(Rez.Strings.Mon);
        weekdays[2]   = Ui.loadResource(Rez.Strings.Tue);
        weekdays[3]   = Ui.loadResource(Rez.Strings.Wed);
        weekdays[4]   = Ui.loadResource(Rez.Strings.Thu);
        weekdays[5]   = Ui.loadResource(Rez.Strings.Fri);
        weekdays[6]   = Ui.loadResource(Rez.Strings.Sat);        
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        View.onUpdate(dc);

        // General
        var width       = dc.getWidth();
        var height      = dc.getHeight();
        var centerX     = width * 0.5;
        var centerY     = height * 0.5;
        var clockTime   = Sys.getClockTime();
        var nowinfo     = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var actinfo     = Act.getInfo();
        var systemStats = Sys.getSystemStats();
        var hrIter      = Act.getHeartRateHistory(null, true);
        var hr          = hrIter.next();
        var steps       = actinfo.steps;
        var stepGoal    = actinfo.stepGoal;
        var kcal        = actinfo.calories;
        var bpm         = (hr.heartRate != Act.INVALID_HR_SAMPLE && hr.heartRate > 0) ? hr.heartRate : 0;
        var charge      = systemStats.battery;
        var dayOfWeek   = nowinfo.day_of_week;
        var connected   = Sys.getDeviceSettings().phoneConnected;        
        var profile     = UserProfile.getProfile();
        var gender;
        var userWeight;
        var userHeight;
        var userAge;
        
        if (profile == null) {
            gender     = Application.getApp().getProperty("Gender");
            userWeight = Application.getApp().getProperty("Weight");
            userHeight = Application.getApp().getProperty("Height");
            userAge    = Application.getApp().getProperty("Age");
        } else {
            gender     = profile.gender;
            userWeight = profile.weight / 1000d;
            userHeight = profile.height;
            userAge    = nowinfo.year - profile.birthYear;            
        }        
                        
        // Mifflin-St.Jeor Formula (1990)
        var goalMen   = (10.0 * userWeight) + (6.25 * userHeight) - (5 * userAge) + 5;
        var goalWoman = (10.0 * userWeight) + (6.25 * userHeight) - (5 * userAge) - 161;                
        var goal      = gender == MEN ? goalMen : goalWoman;
                
        var showBpmZones = false;
        var maxBpm       = gender == 1 ? (223 - 0.9 * userAge).toNumber() : (226 - 1.0 * userAge).toNumber();        
        var bpmZone1     = (0.5 * maxBpm).toNumber();
        var bpmZone2     = (0.6 * maxBpm).toNumber();
        var bpmZone3     = (0.7 * maxBpm).toNumber();
        var bpmZone4     = (0.8 * maxBpm).toNumber();
        var bpmZone5     = (0.9 * maxBpm).toNumber();
        var currentZone;
        if (bpm >= bpmZone5) {
            currentZone = 5;
        } else if (bpm >= bpmZone4) {
            currentZone = 4;
        } else if (bpm >= bpmZone3) {
            currentZone = 3;
        } else if (bpm >= bpmZone2) {
            currentZone = 2;
        } else {
            currentZone = 1;
        }

            
        // Draw Background
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, 121);
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);    
        dc.fillRectangle(0, 121, width, 59);
            
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 121, width, 121);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 122, width, 122);
                
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(106, 121, 3, 28);
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 149, width, 3);
        
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 152, width, 152);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 153, width, 153);
            
        // Battery
        dc.drawBitmap(95, 4, batteryIcon);
        dc.setColor(charge < 20 ? Gfx.COLOR_RED : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(97, 6 , 20.0 * charge / 100, 7);

        // BLE
        if (connected) { dc.drawBitmap(139, 2, bleIcon); }
       
       // Steps
        dc.drawBitmap(21, 127, stepsIcon);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(98, 124, valueFont, steps, Gfx.TEXT_JUSTIFY_RIGHT);
            
        // KCal
        dc.drawBitmap(181, 127, burnedIcon);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(173, 124, valueFont, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);        

        // BPM       
        dc.drawBitmap(80, 157, bpmIcon);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);        
        dc.drawText(146, 153, valueFont, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);


        // Time        
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, 23, timeFont, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, 23, timeFont, Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
    
        // Date
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);        
        dc.drawText(centerX, 89, dateFont, Lang.format(weekdays[dayOfWeek -1] + "$1$.$2$", [nowinfo.day.format("%02d"), nowinfo.month.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
    }


    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {}

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {}

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {}
}

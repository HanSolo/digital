using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.ActivityMonitor as Act;
using Toybox.Attention as Att;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Greg;
using Toybox.Application as App;
using Toybox.UserProfile as UserProfile;


class DigitalView extends Ui.WatchFace {
    enum { WOMAN, MEN }
    const STEP_COLORS = [ Gfx.COLOR_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_YELLOW, Gfx.COLOR_DK_GREEN, Gfx.COLOR_GREEN ];
    var weekdays = new [7];
    var timeFont, dateFont, valueFont, distanceFont, sunFont;
    var bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon;
    var alarmIcon, batteryIcon, bleIcon, bpmIcon, burnedIcon, mailIcon, stepsIcon;    
    var heartRate;    

    function initialize() {
        WatchFace.initialize();
    }

    //! Load your resources here
    function onLayout(dc) {        
        timeFont      = Ui.loadResource(Rez.Fonts.digitalUpright66);
        dateFont      = Ui.loadResource(Rez.Fonts.digitalUpright26);
        valueFont     = Ui.loadResource(Rez.Fonts.digitalUpright24);
        distanceFont  = Ui.loadResource(Rez.Fonts.digitalUpright16);
        alarmIcon     = Ui.loadResource(Rez.Drawables.alarm);
        batteryIcon   = Ui.loadResource(Rez.Drawables.battery);
        bleIcon       = Ui.loadResource(Rez.Drawables.ble);
        bpmIcon       = Ui.loadResource(Rez.Drawables.bpm);
        bpm1Icon      = Ui.loadResource(Rez.Drawables.bpm1);
        bpm2Icon      = Ui.loadResource(Rez.Drawables.bpm2);
        bpm3Icon      = Ui.loadResource(Rez.Drawables.bpm3);
        bpm4Icon      = Ui.loadResource(Rez.Drawables.bpm4);
        bpm5Icon      = Ui.loadResource(Rez.Drawables.bpm5);
        burnedIcon    = Ui.loadResource(Rez.Drawables.burned);
        mailIcon      = Ui.loadResource(Rez.Drawables.mail);
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
        
        var bpmZoneIcons         = [ bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon ];

        // General
        var width                = dc.getWidth();
        var height               = dc.getHeight();
        var centerX              = width * 0.5;
        var centerY              = height * 0.5;
        var clockTime            = Sys.getClockTime();
        var nowinfo              = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var actinfo              = Act.getInfo();
        var systemStats          = Sys.getSystemStats();
        var hrIter               = Act.getHeartRateHistory(null, true);
        var hr                   = hrIter.next();
        var steps                = actinfo.steps;
        var stepGoal             = actinfo.stepGoal;
        var stepsReached         = steps.toDouble() / stepGoal;
        var distance             = actinfo.distance * 0.00001;
        var kcal                 = actinfo.calories;
        var bpm                  = (hr.heartRate != Act.INVALID_HR_SAMPLE && hr.heartRate > 0) ? hr.heartRate : 0;
        var charge               = systemStats.battery;
        var dayOfWeek            = nowinfo.day_of_week;
        var lcdBackgroundVisible = Application.getApp().getProperty("LcdBackground");         
        var connected            = Sys.getDeviceSettings().phoneConnected;        
        var profile              = UserProfile.getProfile();
        var notificationCount    = Sys.getDeviceSettings().notificationCount;
        var alarmCount           = Sys.getDeviceSettings().alarmCount;
        var dst                  = Application.getApp().getProperty("DST");    
        var timezoneOffset       = clockTime.timeZoneOffset;
        var showHomeTimezone     = Application.getApp().getProperty("ShowHomeTimezone");
        var homeTimezoneOffset   = dst ? Application.getApp().getProperty("HomeTimezoneOffset") + 3600 : Application.getApp().getProperty("HomeTimezoneOffset");
        var onTravel             = timezoneOffset != homeTimezoneOffset;    
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
        var goalMen      = (10.0 * userWeight) + (6.25 * userHeight) - (5 * userAge) + 5;
        var goalWoman    = (10.0 * userWeight) + (6.25 * userHeight) - (5 * userAge) - 161;                
        var kcalGoal     = gender == MEN ? goalMen : goalWoman;
        var kcalReached  = kcal / kcalGoal;
                
        var showBpmZones = Application.getApp().getProperty("BpmZones");
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
        dc.setPenWidth(1);     
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, 121);
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);    
        dc.fillRectangle(0, 121, width, 59);
            
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 121, width, 121);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 122, width, 122);

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 149, width, 3);
        
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 152, width, 152);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 153, width, 153);
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(106, 121, 3, 59);
                    
        // Notification
        if (notificationCount > 0) { dc.drawBitmap(58, 4, mailIcon); }    
            
        // Battery
        dc.drawBitmap(95, 4, batteryIcon);
        dc.setColor(charge < 20 ? Gfx.COLOR_RED : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(97, 6 , 20.0 * charge / 100, 7);

        // BLE
        if (connected) { dc.drawBitmap(137, 2, bleIcon); }
        
        // Alarm
        if (alarmCount > 0) { dc.drawBitmap(156, 3, alarmIcon); }
       
       // Steps
        dc.drawBitmap(18, 127, stepsIcon);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(102, 124, valueFont, steps, Gfx.TEXT_JUSTIFY_RIGHT);
            
        // KCal
        dc.drawBitmap(183, 127, burnedIcon);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(179, 124, valueFont, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);        

        // BPM
        dc.drawBitmap(40, 158, showBpmZones ? bpmZoneIcons[currentZone - 1] : bpmIcon);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);        
        dc.drawText(102, 155, valueFont, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);

        // Distance
        dc.drawText(156, 155, valueFont, distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(172, 162, distanceFont, "km", Gfx.TEXT_JUSTIFY_RIGHT);
                
        // Step Bar background
        dc.setPenWidth(8);           
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        for(var i = 0; i < 10 ; i++) {            
            var startAngleLeft  = 136 + (i * 6);
            dc.drawArc(centerX, centerY, 105, 0, startAngleLeft, startAngleLeft + 5);
        }
        
        // Step Goal Bar
        stepsReached = stepsReached > 1.0 ? 1.0 : stepsReached;        
        dc.setColor(STEP_COLORS[(stepsReached * 4.0).toNumber()], Gfx.COLOR_TRANSPARENT);
        var stopAngleLeft = (190.0 - 59.0 * stepsReached).toNumber();
        stopAngleLeft = stopAngleLeft < 136.0 ? 136.0 : stopAngleLeft;
        for(var i = 10; i >= 0 ; i--) {
            var startAngleLeft = 190 - (i * 6);
            if (startAngleLeft >= stopAngleLeft && steps > 0) { dc.drawArc(centerX, centerY, 105, 0, startAngleLeft, startAngleLeft + 5); }
        }

        // KCal Goal Bar Background        
        if (kcalReached > 2.0) {
            dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        } else if (kcalReached > 1.0) {
            dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        }
        for(var i = 0; i < 10 ; i++) {            
            var startAngleRight = -15 + (i * 6);         
            dc.drawArc(centerX, centerY, 105, 0, startAngleRight, startAngleRight + 5);            
        }
                
        // KCal Goal Bar
        if (kcalReached > 2.0) {
            dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
            kcalReached -= 2.0;
        } else if (kcalReached > 1.0) {
            dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
            kcalReached -= 1.0;
        } else {
            dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
        }
        var stopAngleRight = (-15.0 + 59.0 * kcalReached).toNumber();
        stopAngleRight = stopAngleRight > 59.0 ? 59.0 : stopAngleRight;
        for(var i = 0; i < 10 ; i++) {
            var startAngleRight = -15 + (i * 6);
            if (startAngleRight < stopAngleRight) { dc.drawArc(centerX, centerY, 105, 0, startAngleRight, startAngleRight + 5); }
        }

        // Time        
        if (lcdBackgroundVisible) {
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, 23, timeFont, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, 23, timeFont, Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
    
        // Date and home timezone
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);        
        if (onTravel && showHomeTimezone) {
            dc.drawText(25, 89, dateFont, Lang.format(weekdays[dayOfWeek -1] + "$1$.$2$", [nowinfo.day.format("%02d"), nowinfo.month.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);          
            var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
            var utcSeconds     = currentSeconds - clockTime.timeZoneOffset - (dst ? 3600 : 0); //
            var homeSeconds    = utcSeconds + homeTimezoneOffset;
            var homeHour       = ((homeSeconds / 3600)).toNumber() % 24l;
            var homeMinute     = ((homeSeconds - (homeHour.abs() * 3600)) / 60) % 60;           
            dc.drawText(190, 89, dateFont, Lang.format("$1$:$2$", [homeHour.format("%02d"), homeMinute.format("%02d")]), Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(centerX, 89, dateFont, Lang.format(weekdays[dayOfWeek -1] + "$1$.$2$", [nowinfo.day.format("%02d"), nowinfo.month.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
        }
    }


    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {}

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {}

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {}
    
    function onSettingsChanged() {
        Sys.println("Settings changed");
    }
}

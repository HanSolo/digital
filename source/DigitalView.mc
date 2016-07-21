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
using Toybox.Ant as Ant;


class DigitalView extends Ui.WatchFace {
    enum { WOMAN, MEN }
    const STEP_COLORS  = [ Gfx.COLOR_DK_RED, Gfx.COLOR_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_ORANGE, Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW, Gfx.COLOR_DK_GREEN, Gfx.COLOR_DK_GREEN, Gfx.COLOR_GREEN, Gfx.COLOR_GREEN ];
    const LEVEL_COLORS = [ Gfx.COLOR_GREEN, Gfx.COLOR_DK_GREEN, Gfx.COLOR_YELLOW, Gfx.COLOR_ORANGE, Gfx.COLOR_RED ];
    var weekdays       = new [7];
    var timeFont, dateFont, valueFont, distanceFont, sunFont;
    var timeFontAnalog, dateFontAnalog, valueFontAnalog, distanceFontAnalog;
    var chargeFont;
    var bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon, bpmMaxRedIcon, bpmMaxBlackIcon;
    var alarmIcon, alertIcon, batteryIcon, bleIcon, bpmIcon, burnedIcon, mailIcon, stepsIcon;    
    var heartRate;    

    function initialize() {
        WatchFace.initialize();
    }

    //! Load your resources here
    function onLayout(dc) {        
        timeFont           = Ui.loadResource(Rez.Fonts.digitalUpright66);
        dateFont           = Ui.loadResource(Rez.Fonts.digitalUpright26);
        valueFont          = Ui.loadResource(Rez.Fonts.digitalUpright24);
        distanceFont       = Ui.loadResource(Rez.Fonts.digitalUpright16);
        timeFontAnalog     = Ui.loadResource(Rez.Fonts.analog66);
        dateFontAnalog     = Ui.loadResource(Rez.Fonts.analog26);
        valueFontAnalog    = Ui.loadResource(Rez.Fonts.analog24);
        distanceFontAnalog = Ui.loadResource(Rez.Fonts.analog16);
        chargeFont         = Ui.loadResource(Rez.Fonts.droidSansMono12);        
        alarmIcon          = Ui.loadResource(Rez.Drawables.alarm);
        alertIcon          = Ui.loadResource(Rez.Drawables.alert);
        batteryIcon        = Ui.loadResource(Rez.Drawables.battery);
        bleIcon            = Ui.loadResource(Rez.Drawables.ble);
        bpmIcon            = Ui.loadResource(Rez.Drawables.bpm);
        bpm1Icon           = Ui.loadResource(Rez.Drawables.bpm1);
        bpm2Icon           = Ui.loadResource(Rez.Drawables.bpm2);
        bpm3Icon           = Ui.loadResource(Rez.Drawables.bpm3);
        bpm4Icon           = Ui.loadResource(Rez.Drawables.bpm4);
        bpm5Icon           = Ui.loadResource(Rez.Drawables.bpm5);
        bpmMaxRedIcon      = Ui.loadResource(Rez.Drawables.bpmMaxRed);
        bpmMaxBlackIcon    = Ui.loadResource(Rez.Drawables.bpmMaxBlack);
        burnedIcon         = Ui.loadResource(Rez.Drawables.burned);
        mailIcon           = Ui.loadResource(Rez.Drawables.mail);
        stepsIcon          = Ui.loadResource(Rez.Drawables.steps);        
        weekdays[0]        = Ui.loadResource(Rez.Strings.Sun);
        weekdays[1]        = Ui.loadResource(Rez.Strings.Mon);
        weekdays[2]        = Ui.loadResource(Rez.Strings.Tue);
        weekdays[3]        = Ui.loadResource(Rez.Strings.Wed);
        weekdays[4]        = Ui.loadResource(Rez.Strings.Thu);
        weekdays[5]        = Ui.loadResource(Rez.Strings.Fri);
        weekdays[6]        = Ui.loadResource(Rez.Strings.Sat); 
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        View.onUpdate(dc);
        
        var bpmZoneIcons          = [ bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon ];

        // General
        var width                 = dc.getWidth();
        var height                = dc.getHeight();
        var isFenix3Hr            = Sys.getDeviceSettings().screenShape == Sys.SCREEN_SHAPE_ROUND && width == 218 && height == 218;
        var offsetX               = isFenix3Hr ?  2 : 0;
        var offsetY               = isFenix3Hr ? 19 : 0;
        var centerX               = width * 0.5;
        var centerY               = height * 0.5;
        var clockTime             = Sys.getClockTime();
        var midnightInfo          = Greg.info(Time.today(), Time.FORMAT_SHORT);
        var nowinfo               = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var actinfo               = Act.getInfo();        
        var systemStats           = Sys.getSystemStats();
        var is24Hour              = Sys.getDeviceSettings().is24Hour;
        var hrIter                = Act.getHeartRateHistory(null, true);
        var hr                    = hrIter.next();
        var steps                 = actinfo.steps;
        var stepGoal              = actinfo.stepGoal;
        var stepsReached          = steps.toDouble() / stepGoal;        
        var kcal                  = actinfo.calories;
        var showActiveKcalOnly    = Application.getApp().getProperty("ShowActiveKcalOnly");
        var bpm                   = (hr.heartRate != Act.INVALID_HR_SAMPLE && hr.heartRate > 0) ? hr.heartRate : 0;
        var charge                = systemStats.battery;
        var showChargePercentage  = Application.getApp().getProperty("ShowChargePercentage");
        var showPercentageUnder20 = Application.getApp().getProperty("ShowPercentageUnder20");
        var dayOfWeek             = nowinfo.day_of_week;
        var lcdBackgroundVisible  = Application.getApp().getProperty("LcdBackground");         
        var connected             = Sys.getDeviceSettings().phoneConnected;        
        var profile               = UserProfile.getProfile();
        var notificationCount     = Sys.getDeviceSettings().notificationCount;
        var alarmCount            = Sys.getDeviceSettings().alarmCount;
        var dst                   = Application.getApp().getProperty("DST");    
        var timezoneOffset        = clockTime.timeZoneOffset;
        var showHomeTimezone      = Application.getApp().getProperty("ShowHomeTimezone");
        var homeTimezoneOffset    = dst ? Application.getApp().getProperty("HomeTimezoneOffset") + 3600 : Application.getApp().getProperty("HomeTimezoneOffset");
        var onTravel              = timezoneOffset != homeTimezoneOffset;        
        var distanceUnit          = Application.getApp().getProperty("DistanceUnit"); // 0 -> Kilometer, 1 -> Miles
        var distance              = distanceUnit == 0 ? actinfo.distance * 0.00001 : actinfo.distance * 0.00001 * 0.621371;        
        var dateFormat            = Application.getApp().getProperty("DateFormat") == 0 ? "$1$.$2$" : "$2$/$1$";
        var showMoveBar           = Application.getApp().getProperty("ShowMoveBar");
        var showLeadingZero       = Application.getApp().getProperty("ShowLeadingZero");
        var lcdFont               = Application.getApp().getProperty("LcdFont");
        var moveBarLevel          = actinfo.moveBarLevel;
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
        var goalMen       = (10.0 * userWeight) + (6.25 * userHeight) - (5 * userAge) + 5;                // base kcal men
        var goalWoman     = (10.0 * userWeight) + (6.25 * userHeight) - (5 * userAge) - 161;              // base kcal woman
        var kcalGoal      = gender == MEN ? goalMen : goalWoman;                                          // base kcal related to gender
        var kcalPerMinute = kcalGoal / 1440;                                                              // base kcal per minute        
        var activeKcal    = (kcal - (kcalPerMinute * (clockTime.hour * 60 + clockTime.min))).toNumber();  // active kcal
        var kcalReached   = kcal / kcalGoal;                                                              // kcal reached 

        var showBpmZones  = Application.getApp().getProperty("BpmZones");
        var maxBpm        = gender == 1 ? (223 - 0.9 * userAge).toNumber() : (226 - 1.0 * userAge).toNumber();        
        var bpmZone1      = (0.5 * maxBpm).toNumber();
        var bpmZone2      = (0.6 * maxBpm).toNumber();
        var bpmZone3      = (0.7 * maxBpm).toNumber();
        var bpmZone4      = (0.8 * maxBpm).toNumber();
        var bpmZone5      = (0.9 * maxBpm).toNumber();
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
        dc.fillRectangle(offsetX, offsetY, width, 121);
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);    
        dc.fillRectangle(offsetX, 121 + offsetY, width, 59);
            
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(offsetX, 121 + offsetY, width, 121 + offsetY);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(offsetX, 122 + offsetY, width, 122 + offsetY);

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(offsetX, 149 + offsetY, width, 3);
        
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(offsetX, 152 + offsetY, width, 152 + offsetY);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(offsetX, 153 + offsetY, width, 153 + offsetY);
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(106 + offsetX, 121 + offsetY, 3, 59);
                    
        // Notification
        if (notificationCount > 0) { dc.drawBitmap(58 + offsetX, 4 + offsetY, mailIcon); }    
            
        // Battery
        dc.drawBitmap(93 + offsetX, 4 + offsetY, batteryIcon);
        dc.setColor(charge < 20 ? Gfx.COLOR_RED : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(95 + offsetX, 6 + offsetY , 24.0 * charge / 100, 7);
        if (showChargePercentage) {
            if (showPercentageUnder20) {
                if (charge.toNumber() <= 20) {
                    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);                    
                    dc.drawText(107 + offsetX, 11 + offsetY, chargeFont, charge.toNumber() + "%", Gfx.TEXT_JUSTIFY_CENTER);                    
                }
            } else {
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                dc.drawText(107 + offsetX, 11 + offsetY, chargeFont, charge.toNumber() + "%", Gfx.TEXT_JUSTIFY_CENTER);
            }            
        }

        // BLE
        if (connected) { dc.drawBitmap(137 + offsetX, 2 + offsetY, bleIcon); }
        
        // Alarm
        if (alarmCount > 0) { dc.drawBitmap(156 + offsetX, 3 + offsetY, alarmIcon); }
       
       // Steps
        dc.drawBitmap(18 + offsetX, 127 + offsetY, stepsIcon);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        if (lcdFont) {
            dc.drawText(102 + offsetX, 124 + offsetY, valueFont, steps, Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(102 + offsetX, 121 + offsetY, valueFontAnalog, steps, Gfx.TEXT_JUSTIFY_RIGHT);
        }
            
        // KCal
        dc.drawBitmap(183 + offsetX, 127 + offsetY, burnedIcon);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        if (showActiveKcalOnly) {            
            if (lcdFont) {
                dc.drawText(179 + offsetX, 124 + offsetY, valueFont, activeKcal < 0 ? 0 : activeKcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(179 + offsetX, 121 + offsetY, valueFontAnalog, activeKcal < 0 ? 0 : activeKcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            }
        } else {
            if (lcdFont) {
                dc.drawText(179 + offsetX, 124 + offsetY, valueFont, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(179 + offsetX, 121 + offsetY, valueFontAnalog, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            }
        }        

        // BPM        
        if (bpm >= maxBpm) {
            dc.drawBitmap(40 + offsetX, 158 + offsetY, showBpmZones ? bpmMaxRedIcon : bpmMaxBlackIcon);
        } else {
            dc.drawBitmap(40 + offsetX, 158 + offsetY, showBpmZones ? bpmZoneIcons[currentZone - 1] : bpmIcon);
        }        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);        
        if (lcdFont) {
            dc.drawText(102 + offsetX, 155 + offsetY, valueFont, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(102 + offsetX, 152 + offsetY, valueFontAnalog, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        }

        // Distance
        if (lcdFont) {
            dc.drawText(156 + offsetX, 155 + offsetY, valueFont, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(172 + offsetX, 162 + offsetY, distanceFont, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(154 + offsetX, 152 + offsetY, valueFontAnalog, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(172 + offsetX, 159 + offsetY, distanceFontAnalog, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_RIGHT);
        }
                
        // Step Bar background
        dc.setPenWidth(8);           
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        for(var i = 0; i < 10 ; i++) {            
            var startAngleLeft  = 136 + (i * 6);
            dc.drawArc(centerX, centerY, 105, 0, startAngleLeft, startAngleLeft + 5);
        }
        
        // Step Goal Bar
        stepsReached      = stepsReached > 1.0 ? 1.0 : stepsReached;                
        var endIndex      = (10.0 * stepsReached).toNumber();        
        var stopAngleLeft = (190.0 - 59.0 * stepsReached).toNumber();
        stopAngleLeft     = stopAngleLeft < 136.0 ? 136.0 : stopAngleLeft;        
        dc.setColor(endIndex > 0 ? STEP_COLORS[endIndex - 1] : Gfx.COLOR_TRANSPARENT, Gfx.COLOR_TRANSPARENT);
        for(var i = 0; i < endIndex ; i++) {            
            var startAngleLeft  = 190 - (i * 6);            
            dc.drawArc(centerX, centerY, 105, 0, startAngleLeft, startAngleLeft + 5);
        }

        // KCal Goal Bar Background        
        if (kcalReached > 3.0) {
            dc.setColor(Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
        } else if (kcalReached > 2.0) {
            dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        } else if (kcalReached > 1.0) {
            dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        }
        for(var i = 0; i < 10 ; i++) {            
            var startAngleRight = -15 + (i * 6);         
            dc.drawArc(centerX, centerY, 105, 0, startAngleRight, startAngleRight + 5);            
        }
                
        // KCal Goal Bar
        if (kcalReached > 3.0) {
            dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
            kcalReached -= 3.0;
        } else if (kcalReached > 2.0) {
            dc.setColor(Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
            kcalReached -= 2.0;
        } else if (kcalReached > 1.0) {
            dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
            kcalReached -= 1.0;
        } else {
            dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
        }
        var stopAngleRight = (-15.0 + 59.0 * kcalReached).toNumber();
        stopAngleRight = stopAngleRight > 59.0 ? 59.0 : stopAngleRight;
        for(var i = 0; i < 10 ; i++) {
            var startAngleRight = -15 + (i * 6);
            if (startAngleRight < stopAngleRight) { dc.drawArc(centerX, centerY, 105, 0, startAngleRight, startAngleRight + 5); }
        }

        // Move Bar
        if (showMoveBar) {
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            for (var i = 0 ; i < 5 ; i++) { dc.fillRectangle(41 + (i * 27) + offsetX, 116 + offsetY, 25, 4); }
            if (moveBarLevel > Act.MOVE_BAR_LEVEL_MIN) { dc.setColor(LEVEL_COLORS[moveBarLevel - 1], Gfx.COLOR_TRANSPARENT); }
            for (var i = 0 ; i < moveBarLevel ; i++) { dc.fillRectangle(41 + (i * 27) + offsetX, 116 + offsetY, 25, 4); }
            if (moveBarLevel == 5) { dc.drawBitmap(177 + offsetX, 112 + offsetY, alertIcon); }
        }
        

        // Time        
        if (lcdBackgroundVisible && lcdFont) {
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            if (showLeadingZero) {
                dc.drawText(centerX, 25 + offsetY, timeFont, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                if (is24Hour) {
                    if (clockTime.hour < 10) {
                        dc.drawText(centerX, 25 + offsetY, timeFont, "8:88", Gfx.TEXT_JUSTIFY_CENTER);
                    } else {
                        dc.drawText(centerX, 25 + offsetY, timeFont, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                    }
                } else {
                    if (clockTime.hour < 10 || clockTime.hour > 12) {
                        dc.drawText(centerX, 25 + offsetY, timeFont, "8:88", Gfx.TEXT_JUSTIFY_CENTER);
                    } else {
                        dc.drawText(centerX, 25 + offsetY, timeFont, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                    }
                }
            }            
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        if (is24Hour) {
            if (lcdFont) {
                dc.drawText(centerX, 25 + offsetY, timeFont, Lang.format("$1$:$2$", [clockTime.hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                dc.drawText(centerX, 18 + offsetY, timeFontAnalog, Lang.format("$1$:$2$", [clockTime.hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
            }    
        } else {
            var hour = clockTime.hour;
            var amPm = "am";
            if (hour > 12) {
                hour = clockTime.hour - 12;
                amPm = "pm";
            } else if (hour == 0) {
                hour = 12;              
            } else if (hour == 12) {                
                amPm = "pm";
            }         
            if (lcdFont) {   
                dc.drawText(centerX, 25 + offsetY, timeFont, Lang.format("$1$:$2$", [hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
                dc.drawText(178 + offsetX, 65 + offsetY, distanceFont, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(centerX, 18 + offsetY, timeFontAnalog, Lang.format("$1$:$2$", [hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
                dc.drawText(178 + offsetX, 63 + offsetY, distanceFontAnalog, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            }    
        }        
    
        // Date and home timezone
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var dateYPosition = showMoveBar ? 86 : 89;
        dateYPosition = lcdFont ? dateYPosition : dateYPosition - 3;
        if (onTravel && showHomeTimezone) {
            var homeDayOfWeek  = dayOfWeek - 1;
            var homeDay        = nowinfo.day;
            var homeMonth      = nowinfo.month;
            var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
            var utcSeconds     = currentSeconds - clockTime.timeZoneOffset;// - (dst ? 3600 : 0);
            var homeSeconds    = utcSeconds + homeTimezoneOffset;
            if (dst) { homeSeconds = homeTimezoneOffset > 0 ? homeSeconds : homeSeconds - 3600; }
            var homeHour       = ((homeSeconds / 3600)).toNumber() % 24l;
            var homeMinute     = ((homeSeconds - (homeHour.abs() * 3600)) / 60) % 60;
            if (homeHour < 0) {
                homeHour += 24;
                homeDay--;
                if (homeDay == 0) {
                    homeMonth--;
                    if (homeMonth == 0) { homeMonth = 12; }
                    homeDay = daysOfMonth(homeMonth);
                }
                homeDayOfWeek--;
                if (homeDayOfWeek < 0) { homeDayOfWeek = 6; }
            }
            if (homeMinute < 0) { homeMinute += 60; }
                        
            if (lcdFont) {
                dc.drawText(25 + offsetX, dateYPosition + offsetY, dateFont, Lang.format(weekdays[homeDayOfWeek] + dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(190 + offsetX, dateYPosition + offsetY, dateFont, Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(25 + offsetX, dateYPosition + offsetY, dateFontAnalog, Lang.format(weekdays[homeDayOfWeek] + dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(190 + offsetX, dateYPosition + offsetY, dateFontAnalog, Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]), Gfx.TEXT_JUSTIFY_RIGHT);
            }            
        } else {
            if (lcdFont) {
                dc.drawText(centerX, dateYPosition + offsetY, dateFont, Lang.format(weekdays[dayOfWeek -1] + dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                dc.drawText(centerX, dateYPosition + offsetY, dateFontAnalog, Lang.format(weekdays[dayOfWeek -1] + dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
    }

    function floor(x) {
        if(x > 0) { return x.toNumber(); }
        return (x - 0.9999999999999999).toNumber();
    }

    function daysOfMonth(month) { return 28 + (month + floor(month / 8)) % 2 + 2 % month + 2 * floor(1 / month); }


    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {}

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {}

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {}
    
    function onSettingsChanged() {
        //Sys.println("Settings changed");
    }
}

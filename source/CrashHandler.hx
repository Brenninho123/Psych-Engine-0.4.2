package;

import openfl.Lib;
import openfl.events.UncaughtErrorEvent;

class CrashHandler
{
    public static function init()
    {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
            UncaughtErrorEvent.UNCAUGHT_ERROR,
            onCrash
        );
    }

    static function onCrash(e:UncaughtErrorEvent)
    {
        CrashLog.save(Std.string(e.error));
    }
}
package;

import sys.io.File;
import sys.FileSystem;

class CrashLog
{
    public static function save(msg:String)
    {
        var path = "crash_log.txt";

        var old = FileSystem.exists(path)
            ? File.getContent(path)
            : "";

        File.saveContent(path, msg + "\n\n" + old);
    }
}
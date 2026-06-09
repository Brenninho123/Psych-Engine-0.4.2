package;

#if android
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.io.Bytes;
#end

using StringTools;

class Storage
{
#if android

public static var storagePath(default, null):String = "";
public static var assetsPath(default, null):String = "";
public static var modsPath(default, null):String = "";

public static function init():Void
{
    storagePath = getStoragePath();
    assetsPath = storagePath + "/assets";
    modsPath = storagePath + "/mods";

    createDirectory(storagePath);
    createDirectory(assetsPath);
    createDirectory(modsPath);
}

public static function requestPermissions():Void
{
}

public static function getStoragePath():String
{
    return "/storage/emulated/0/Android/data/com.shadowmario.psychengine042/files";
}

public static function createDirectory(path:String):Void
{
    try
    {
        if (!FileSystem.exists(path))
            FileSystem.createDirectory(path);
    }
    catch (_:Dynamic) {}
}

public static function createDirectoryForFile(path:String):Void
{
    try
    {
        var dir = Path.directory(path);

        if (dir != null && dir.length > 0)
        {
            if (!FileSystem.exists(dir))
                FileSystem.createDirectory(dir);
        }
    }
    catch (_:Dynamic) {}
}

public static function saveBytes(path:String, bytes:Bytes):Bool
{
    try
    {
        createDirectoryForFile(path);
        File.saveBytes(path, bytes);
        return true;
    }
    catch (_:Dynamic) {}

    return false;
}

public static function saveText(path:String, content:String):Bool
{
    try
    {
        createDirectoryForFile(path);
        File.saveContent(path, content);
        return true;
    }
    catch (_:Dynamic) {}

    return false;
}

public static function loadText(path:String):String
{
    try
    {
        if (FileSystem.exists(path))
            return File.getContent(path);
    }
    catch (_:Dynamic) {}

    return "";
}

public static function loadBytes(path:String):Null<Bytes>
{
    try
    {
        if (FileSystem.exists(path))
            return File.getBytes(path);
    }
    catch (_:Dynamic) {}

    return null;
}

public static function exists(path:String):Bool
{
    try
    {
        return FileSystem.exists(path);
    }
    catch (_:Dynamic) {}

    return false;
}

public static function delete(path:String):Bool
{
    try
    {
        if (FileSystem.exists(path))
        {
            FileSystem.deleteFile(path);
            return true;
        }
    }
    catch (_:Dynamic) {}

    return false;
}

public static function fileSize(path:String):Int
{
    try
    {
        if (FileSystem.exists(path))
            return FileSystem.stat(path).size;
    }
    catch (_:Dynamic) {}

    return 0;
}

public static function listFiles(path:String):Array<String>
{
    try
    {
        if (FileSystem.exists(path))
            return FileSystem.readDirectory(path);
    }
    catch (_:Dynamic) {}

    return [];
}

#end

}
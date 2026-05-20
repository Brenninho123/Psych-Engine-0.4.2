package;

#if android
import extension.androidtools.content.Context as AndroidContext;
import extension.androidtools.os.Environment as AndroidEnvironment;
import extension.androidtools.Settings as AndroidSettings;
import extension.androidtools.Permissions as AndroidPermissions;
import extension.androidtools.os.Build.VERSION as AndroidVersion;
import extension.androidtools.os.Build.VERSION_CODES as AndroidVersionCode;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path as HxPath;
import haxe.io.Bytes;
#end

using StringTools;

class Storage
{
	#if android
	public static var storagePath(default, null):String = "";
	public static var assetsPath(default, null):String  = "";
	public static var modsPath(default, null):String    = "";

	public static var extractedFiles:Int = 0;
	public static var skippedFiles:Int   = 0;
	public static var errorFiles:Int     = 0;
	public static var totalFiles:Int     = 0;

	static final VERSION_FILE:String = ".version";
	static final APP_VERSION:String  = "0.4.2";

	static final LIBS:Array<String> = [
		"assets", "shared",
		"week2", "week3", "week4", "week5", "week6",
		"mods"
	];

	static final SCAN_TYPES:Array<AssetType> = [
		AssetType.TEXT,
		AssetType.IMAGE,
		AssetType.SOUND,
		AssetType.MUSIC,
		AssetType.BINARY,
		AssetType.FONT
	];

	public static function init(?onProgress:Float->String->String->Int->Int->Void):Void
	{
		try
		{
			storagePath = resolveExternalDataPath();
			assetsPath  = '${storagePath}/assets';
			modsPath    = '${storagePath}/mods';
			mkdirSafe([storagePath, assetsPath, modsPath]);
		}
		catch (_:Dynamic) {}

		runExtraction(onProgress);
	}

	public static function requestPermissions():Void
	{
		try
		{
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
				AndroidPermissions.requestPermissions(["READ_MEDIA_IMAGES", "READ_MEDIA_VIDEO", "READ_MEDIA_AUDIO"]);
			else
				AndroidPermissions.requestPermissions(["READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE"]);
		}
		catch (_:Dynamic) {}

		try
		{
			if (!AndroidEnvironment.isExternalStorageManager())
			{
				if (AndroidVersion.SDK_INT >= AndroidVersionCode.S)
					AndroidSettings.requestSetting("REQUEST_MANAGE_MEDIA");
				AndroidSettings.requestSetting("MANAGE_APP_ALL_FILES_ACCESS_PERMISSION");
			}
		}
		catch (_:Dynamic) {}
	}

	static function resolveExternalDataPath():String
	{
		try
		{
			var r:String = AndroidContext.getExternalFilesDir();
			if (r != null && r.length > 0) return r;
		}
		catch (_:Dynamic) {}
		return "/sdcard/Android/data/com.shadowmario.psychengine042/files";
	}

	static function destForLib(lib:String):String
	{
		return switch (lib)
		{
			case "assets": assetsPath;
			case "mods":   modsPath;
			default:       '${assetsPath}/${lib}';
		};
	}

	static function mkdirSafe(paths:Array<String>):Void
	{
		for (p in paths)
			try { if (!FileSystem.exists(p)) FileSystem.createDirectory(p); }
			catch (_:Dynamic) {}
	}

	static function mkdirForFile(filePath:String):Void
	{
		try
		{
			var dir = HxPath.directory(filePath);
			if (dir != null && dir.length > 0 && !FileSystem.exists(dir))
				FileSystem.createDirectory(dir);
		}
		catch (_:Dynamic) {}
	}

	static function needsWrite(destPath:String, bytes:Bytes):Bool
	{
		try
		{
			if (!FileSystem.exists(destPath)) return true;
			var s = FileSystem.stat(destPath);
			return s.size == 0 || s.size != bytes.length;
		}
		catch (_:Dynamic) {}
		return true;
	}

	static function scanAllKeys():Array<String>
	{
		var seen = new Map<String, Bool>();
		var keys = new Array<String>();

		for (type in SCAN_TYPES)
		{
			var list:Array<String> = [];
			try { list = OpenFlAssets.list(type); } catch (_:Dynamic) {}

			for (k in list)
				if (k != null && k.length > 0 && !seen.exists(k))
				{
					seen.set(k, true);
					keys.push(k);
				}
		}

		var listAll:Array<String> = [];
		try { listAll = OpenFlAssets.list(); } catch (_:Dynamic) {}

		for (k in listAll)
			if (k != null && k.length > 0 && !seen.exists(k))
			{
				seen.set(k, true);
				keys.push(k);
			}

		return keys;
	}

	static function runExtraction(?onProgress:Float->String->String->Int->Int->Void):Void
	{
		var vf      = '${storagePath}/${VERSION_FILE}';
		var current = "";
		try { current = FileSystem.exists(vf) ? StringTools.trim(File.getContent(vf)) : ""; }
		catch (_:Dynamic) {}

		if (current == APP_VERSION)
		{
			try { if (onProgress != null) onProgress(1.0, "Up to date", "", 0, 0); } catch (_:Dynamic) {}
			return;
		}

		extractedFiles = 0;
		skippedFiles   = 0;
		errorFiles     = 0;

		var allKeys = scanAllKeys();

		var queue:Array<{key:String, dest:String, label:String}> = [];

		for (lib in LIBS)
		{
			var dest  = destForLib(lib);
			var label = lib.charAt(0).toUpperCase() + lib.substr(1);

			for (key in allKeys)
			{
				var matchColon = key.startsWith(lib + ":");
				var matchSlash = key.startsWith(lib + "/");
				if (!matchColon && !matchSlash) continue;

				var clean = matchColon ? key.substr(lib.length + 1) : key.substr(lib.length + 1);
				if (clean == null || clean.length == 0) continue;

				queue.push({ key: key, dest: '${dest}/${clean}', label: label });
			}
		}

		totalFiles = queue.length;
		var done   = 0;

		for (item in queue)
		{
			done++;

			var pct  = totalFiles > 0 ? done / totalFiles : 1.0;
			var name = HxPath.withoutDirectory(item.dest);

			try { if (onProgress != null) onProgress(pct, item.label, name, done, totalFiles); }
			catch (_:Dynamic) {}

			try
			{
				mkdirForFile(item.dest);

				var bytes:Bytes = null;
				try { bytes = OpenFlAssets.getBytes(item.key); } catch (_:Dynamic) {}

				if (bytes == null)
				{
					errorFiles++;
					continue;
				}

				if (!needsWrite(item.dest, bytes))
				{
					skippedFiles++;
					continue;
				}

				File.saveBytes(item.dest, bytes);
				extractedFiles++;
			}
			catch (_:Dynamic) { errorFiles++; }
		}

		try { File.saveContent(vf, APP_VERSION); } catch (_:Dynamic) {}

		try
		{
			if (onProgress != null)
				onProgress(1.0, "Complete",
					'${extractedFiles} extracted  ·  ${skippedFiles} unchanged  ·  ${errorFiles} errors',
					totalFiles, totalFiles);
		}
		catch (_:Dynamic) {}
	}
	#end
}

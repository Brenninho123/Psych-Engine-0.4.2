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
import lime.utils.Assets as LimeAssets;
import sys.thread.Lock;
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

	static final LIB_NAMES:Array<String> = [
		"shared",
		"week2", "week3", "week4",
		"week5", "week6"
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

	public static function needsWrite(destPath:String, bytes:Bytes):Bool
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

	static function mkdirSafe(dirs:Array<String>):Void
	{
		for (d in dirs)
			try { if (!FileSystem.exists(d)) FileSystem.createDirectory(d); }
			catch (_:Dynamic) {}
	}

	static function mkdirForFile(path:String):Void
	{
		try
		{
			var d = HxPath.directory(path);
			if (d != null && d.length > 0 && !FileSystem.exists(d))
				FileSystem.createDirectory(d);
		}
		catch (_:Dynamic) {}
	}

	// Carrega uma biblioteca nomeada e bloqueia até completar (timeout 8s)
	static function loadLibrarySync(name:String):Void
	{
		try
		{
			if (LimeAssets.getLibrary(name) != null) return;

			var future = LimeAssets.loadLibrary(name);

			if (future == null) return;

			if (future.isComplete) return;

			var lock = new Lock();
			future.onComplete(function(_) lock.release());
			future.onError(function(_)   lock.release());
			lock.wait(8.0);
		}
		catch (_:Dynamic) {}
	}

	// Força o carregamento de todas as bibliotecas conhecidas
	static function ensureAllLibrariesLoaded():Void
	{
		for (name in LIB_NAMES)
			loadLibrarySync(name);
	}

	static function normalizePath(key:String):Null<String>
	{
		if (key == null || key.length == 0) return null;
		var p = key;
		var ci = p.indexOf(":");
		if (ci > 0) p = p.substr(ci + 1);
		p = p.replace("\\", "/");
		while (p.startsWith("/")) p = p.substr(1);
		return p;
	}

	static function destForNormalized(norm:String):Null<String>
	{
		if (norm.startsWith("assets/")) return '${storagePath}/${norm}';
		if (norm.startsWith("mods/"))   return '${storagePath}/${norm}';
		return null;
	}

	static function labelFor(norm:String):String
	{
		if (norm.startsWith("assets/characters/")) return "Characters";
		if (norm.startsWith("assets/data/"))       return "Data";
		if (norm.startsWith("assets/fonts/"))      return "Fonts";
		if (norm.startsWith("assets/images/"))     return "Images";
		if (norm.startsWith("assets/music/"))      return "Music";
		if (norm.startsWith("assets/songs/"))      return "Songs";
		if (norm.startsWith("assets/sounds/"))     return "Sounds";
		if (norm.startsWith("assets/stages/"))     return "Stages";
		if (norm.startsWith("assets/weeks/"))      return "Weeks";
		if (norm.startsWith("assets/shared/"))     return "Shared";
		if (norm.startsWith("assets/week2/"))      return "Week 2";
		if (norm.startsWith("assets/week3/"))      return "Week 3";
		if (norm.startsWith("assets/week4/"))      return "Week 4";
		if (norm.startsWith("assets/week5/"))      return "Week 5";
		if (norm.startsWith("assets/week6/"))      return "Week 6";
		if (norm.startsWith("mods/"))              return "Mods";
		return "Assets";
	}

	static function scanAllKeys():Array<{key:String, norm:String}>
	{
		var seen   = new Map<String, Bool>();
		var result = new Array<{key:String, norm:String}>();

		function add(k:String):Void
		{
			if (k == null || k.length == 0) return;
			var norm = normalizePath(k);
			if (norm == null || norm.length == 0) return;
			if (seen.exists(norm)) return;
			if (destForNormalized(norm) == null) return;
			seen.set(norm, true);
			result.push({key: k, norm: norm});
		}

		for (type in SCAN_TYPES)
		{
			var list:Array<String> = [];
			try { list = OpenFlAssets.list(type); } catch (_:Dynamic) {}
			for (k in list) add(k);
		}

		var all:Array<String> = [];
		try { all = OpenFlAssets.list(); } catch (_:Dynamic) {}
		for (k in all) add(k);

		// Varre cada biblioteca nomeada diretamente via LimeAssets
		for (name in LIB_NAMES)
		{
			try
			{
				var lib = LimeAssets.getLibrary(name);
				if (lib == null) continue;

				for (type in SCAN_TYPES)
				{
					var libList:Array<String> = [];
					try { libList = lib.list(type); } catch (_:Dynamic) {}
					for (k in libList) add(k);
				}

				var libAll:Array<String> = [];
				try { libAll = lib.list(null); } catch (_:Dynamic) {}
				for (k in libAll) add(k);
			}
			catch (_:Dynamic) {}
		}

		return result;
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

		try { if (onProgress != null) onProgress(0.0, "Loading libraries...", "", 0, 0); } catch (_:Dynamic) {}

		ensureAllLibrariesLoaded();

		extractedFiles = 0;
		skippedFiles   = 0;
		errorFiles     = 0;

		var queue = scanAllKeys();
		totalFiles = queue.length;
		var done   = 0;

		for (item in queue)
		{
			done++;
			var dest  = destForNormalized(item.norm);
			var label = labelFor(item.norm);
			var name  = HxPath.withoutDirectory(item.norm);
			var pct   = totalFiles > 0 ? done / totalFiles : 1.0;

			try { if (onProgress != null) onProgress(pct, label, name, done, totalFiles); }
			catch (_:Dynamic) {}

			if (dest == null) continue;

			try
			{
				mkdirForFile(dest);

				var bytes:Bytes = null;
				try { bytes = OpenFlAssets.getBytes(item.key); } catch (_:Dynamic) {}

				if (bytes == null)
				{
					errorFiles++;
					continue;
				}

				if (!needsWrite(dest, bytes))
				{
					skippedFiles++;
					continue;
				}

				File.saveBytes(dest, bytes);
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

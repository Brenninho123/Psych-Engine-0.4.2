package;

#if android
import extension.androidtools.content.Context as AndroidContext;
import extension.androidtools.os.Environment as AndroidEnvironment;
import extension.androidtools.Settings as AndroidSettings;
import extension.androidtools.Permissions as AndroidPermissions;
import extension.androidtools.os.Build.VERSION as AndroidVersion;
import extension.androidtools.os.Build.VERSION_CODES as AndroidVersionCode;
import lime.system.System as LimeSystem;
import sys.FileSystem;
import sys.io.File;
import openfl.utils.Assets as OpenFlAssets;
import haxe.io.Path as HxPath;
import haxe.io.Bytes;
#end

using StringTools;

class Storage
{
	#if android
	public static var storagePath(default, null):String  = "";
	public static var assetsPath(default, null):String   = "";
	public static var modsPath(default, null):String     = "";

	public static var extractedFiles:Int = 0;
	public static var skippedFiles:Int   = 0;
	public static var totalFiles:Int     = 0;

	static final VERSION_FILE:String = ".version";
	static final APP_VERSION:String  = "0.4.2";

	static final EXTRACT_LIBS:Array<String> = [
		"assets",
		"shared",
		"week2",
		"week3",
		"week4",
		"week5",
		"week6",
		"mods"
	];

	public static function init(?onProgress:Float->String->String->Int->Int->Void):Void
	{
		try
		{
			storagePath = resolveExternalDataPath();
			assetsPath  = '${storagePath}/assets';
			modsPath    = '${storagePath}/mods';

			mkdirSafe([
				storagePath,
				assetsPath,
				modsPath,
				'${assetsPath}/shared'
			]);
		}
		catch (e:Dynamic) {}

		extractAll(onProgress);
	}

	public static function requestPermissions():Void
	{
		try
		{
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
				AndroidPermissions.requestPermissions([
					"READ_MEDIA_IMAGES",
					"READ_MEDIA_VIDEO",
					"READ_MEDIA_AUDIO"
				]);
			else
				AndroidPermissions.requestPermissions([
					"READ_EXTERNAL_STORAGE",
					"WRITE_EXTERNAL_STORAGE"
				]);
		}
		catch (e:Dynamic) {}

		try
		{
			if (!AndroidEnvironment.isExternalStorageManager())
			{
				if (AndroidVersion.SDK_INT >= AndroidVersionCode.S)
					AndroidSettings.requestSetting("REQUEST_MANAGE_MEDIA");
				AndroidSettings.requestSetting("MANAGE_APP_ALL_FILES_ACCESS_PERMISSION");
			}
		}
		catch (e:Dynamic) {}
	}

	public static function needsExtract(destPath:String, bytes:Bytes):Bool
	{
		try
		{
			if (!FileSystem.exists(destPath)) return true;
			var stat = FileSystem.stat(destPath);
			return stat.size != bytes.length || stat.size == 0;
		}
		catch (e:Dynamic) {}
		return true;
	}

	static function resolveExternalDataPath():String
	{
		try
		{
			var result:String = AndroidContext.getExternalFilesDir();
			if (result != null && result.length > 0) return result;
		}
		catch (e:Dynamic) {}
		return "/sdcard/Android/data/com.shadowmario.psychengine042/files";
	}

	static function mkdirSafe(paths:Array<String>):Void
	{
		for (p in paths)
			try { if (!FileSystem.exists(p)) FileSystem.createDirectory(p); }
			catch (e:Dynamic) {}
	}

	static function destForLib(lib:String):String
	{
		return switch (lib)
		{
			case "mods":   modsPath;
			case "assets": assetsPath;
			default:       '${assetsPath}/${lib}';
		}
	}

	static function extractAll(?onProgress:Float->String->String->Int->Int->Void):Void
	{
		var versionFile = '${storagePath}/${VERSION_FILE}';
		var current     = "";
		try
		{
			current = FileSystem.exists(versionFile)
				? StringTools.trim(File.getContent(versionFile))
				: "";
		}
		catch (e:Dynamic) {}

		if (current == APP_VERSION)
		{
			if (onProgress != null)
				try { onProgress(1.0, "Up to date", "", 0, 0); } catch (_:Dynamic) {}
			return;
		}

		extractedFiles = 0;
		skippedFiles   = 0;

		var allAssets:Array<String> = [];
		try { allAssets = OpenFlAssets.list(); } catch (e:Dynamic) {}

		var queue:Array<{key:String, dest:String, label:String}> = [];

		for (lib in EXTRACT_LIBS)
		{
			var dest  = destForLib(lib);
			var label = lib.charAt(0).toUpperCase() + lib.substr(1);

			mkdirSafe([dest]);

			for (key in allAssets)
			{
				if (!matchesLib(key, lib)) continue;
				var cleanKey = stripLibPrefix(key, lib);
				if (cleanKey == null || cleanKey.length == 0) continue;
				queue.push({ key: key, dest: '${dest}/${cleanKey}', label: label });
			}
		}

		totalFiles = queue.length;
		var done   = 0;

		for (item in queue)
		{
			done++;
			var pct      = totalFiles > 0 ? done / totalFiles : 1.0;
			var filename = HxPath.withoutDirectory(item.dest);

			if (onProgress != null)
				try { onProgress(pct, item.label, filename, done, totalFiles); } catch (_:Dynamic) {}

			try
			{
				var destDir = HxPath.directory(item.dest);
				if (destDir != null && destDir.length > 0 && !FileSystem.exists(destDir))
					FileSystem.createDirectory(destDir);

				var bytes = OpenFlAssets.getBytes(item.key);
				if (bytes == null) continue;

				if (!needsExtract(item.dest, bytes))
				{
					skippedFiles++;
					continue;
				}

				File.saveBytes(item.dest, bytes);
				extractedFiles++;
			}
			catch (e:Dynamic) {}
		}

		try { File.saveContent(versionFile, APP_VERSION); } catch (e:Dynamic) {}

		if (onProgress != null)
			try { onProgress(1.0, "Done", '${extractedFiles} extracted · ${skippedFiles} unchanged', totalFiles, totalFiles); }
			catch (_:Dynamic) {}
	}

	static function matchesLib(key:String, lib:String):Bool
	{
		return key.startsWith(lib + ":") || key.startsWith(lib + "/");
	}

	static function stripLibPrefix(key:String, lib:String):String
	{
		return key.replace(lib + ":", "").replace(lib + "/", "");
	}
	#end
}

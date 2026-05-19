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
	public static var storagePath(default, null):String = "";
	public static var assetsPath(default, null):String  = "";
	public static var modsPath(default, null):String    = "";

	static final VERSION_FILE:String = ".version";
	static final APP_VERSION:String  = "0.4.2";

	// [prefixo OpenFL, subpasta destino, label, skip áudio]
	static final EXTRACT_LIBS:Array<{lib:String, dest:String, label:String, skipAudio:Bool}> = [
		{ lib: "assets", dest: "assets",         label: "Preload",  skipAudio: true  },
		{ lib: "shared", dest: "assets/shared",  label: "Shared",   skipAudio: true  },
		{ lib: "mods",   dest: "mods",           label: "Mods",     skipAudio: false },
	];

	static final AUDIO_EXTS:Array<String> = [".ogg", ".mp3", ".wav"];

	// Estatísticas da última extração
	public static var extractedFiles:Int   = 0;
	public static var skippedFiles:Int     = 0;
	public static var totalFiles:Int       = 0;

	public static function init(?onProgress:Float->String->String->Int->Int->Void):Void
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

		extractAll(onProgress);
	}

	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions([
				"READ_MEDIA_IMAGES", "READ_MEDIA_VIDEO", "READ_MEDIA_AUDIO"
			]);
		else
			AndroidPermissions.requestPermissions([
				"READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE"
			]);

		if (!AndroidEnvironment.isExternalStorageManager())
		{
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.S)
				AndroidSettings.requestSetting("REQUEST_MANAGE_MEDIA");
			AndroidSettings.requestSetting("MANAGE_APP_ALL_FILES_ACCESS_PERMISSION");
		}
	}

	// Verifica se um arquivo externo precisa ser (re)extraído comparando tamanho
	public static function needsExtract(destPath:String, bytes:Bytes):Bool
	{
		if (!FileSystem.exists(destPath)) return true;
		try
		{
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

	static function extractAll(?onProgress:Float->String->String->Int->Int->Void):Void
	{
		var versionFile = '${storagePath}/${VERSION_FILE}';
		var current     = FileSystem.exists(versionFile)
			? StringTools.trim(File.getContent(versionFile))
			: "";

		if (current == APP_VERSION)
		{
			if (onProgress != null) onProgress(1.0, "Up to date", "", 0, 0);
			return;
		}

		extractedFiles = 0;
		skippedFiles   = 0;

		// Pré-escaneio: lista todos os arquivos elegíveis
		var queue:Array<{key:String, dest:String, label:String}> = [];
		var allAssets:Array<String> = [];
		try { allAssets = OpenFlAssets.list(); } catch (e:Dynamic) {}

		for (entry in EXTRACT_LIBS)
		{
			for (key in allAssets)
			{
				if (!matchesLib(key, entry.lib)) continue;
				if (entry.skipAudio && isAudio(key))  continue;

				var cleanKey = stripLibPrefix(key, entry.lib);
				var destPath = '${storagePath}/${entry.dest}/${cleanKey}';
				queue.push({ key: key, dest: destPath, label: entry.label });
			}
		}

		totalFiles = queue.length;
		var done   = 0;

		for (item in queue)
		{
			done++;
			var pct = totalFiles > 0 ? done / totalFiles : 1.0;
			var filename = HxPath.withoutDirectory(item.dest);

			if (onProgress != null)
				onProgress(pct, item.label, filename, done, totalFiles);

			try
			{
				var destDir = HxPath.directory(item.dest);
				if (!FileSystem.exists(destDir))
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

		try { File.saveContent(versionFile, APP_VERSION); }
		catch (e:Dynamic) {}

		if (onProgress != null)
			onProgress(1.0, "Done", '${extractedFiles} extracted, ${skippedFiles} skipped', totalFiles, totalFiles);
	}

	static function matchesLib(key:String, lib:String):Bool
	{
		return key.startsWith(lib + ":") || key.startsWith(lib + "/");
	}

	static function stripLibPrefix(key:String, lib:String):String
	{
		return key.replace(lib + ":", "").replace(lib + "/", "");
	}

	static function isAudio(path:String):Bool
	{
		var lower = path.toLowerCase();
		for (ext in AUDIO_EXTS)
			if (lower.endsWith(ext)) return true;
		return false;
	}
	#end
}

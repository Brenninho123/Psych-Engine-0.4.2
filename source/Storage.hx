package;

#if android
import AndroidContext;
import AndroidEnvironment;
import AndroidPermissions;
import AndroidSettings;
import AndroidVersion;
import AndroidVersionCode;
import sys.FileSystem;
import sys.io.File;
import openfl.utils.Assets as OpenFlAssets;
import haxe.io.Path as HxPath;
#end

using StringTools;

class Storage
{
	#if android
	public static var storagePath(default, null):String = "";

	static final VERSION_FILE:String = ".version";
	static final APP_VERSION:String  = "0.4.2";

	public static function init(?onProgress:Float->String->Void):Void
	{
		storagePath = AndroidContext.getExternalFilesDir();

		try
		{
			if (!FileSystem.exists(storagePath))
				FileSystem.createDirectory(storagePath);
			if (!FileSystem.exists('${storagePath}/mods'))
				FileSystem.createDirectory('${storagePath}/mods');
		}
		catch (e:Dynamic) {}

		extractOnce(onProgress);
	}

	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions([
				'READ_MEDIA_IMAGES',
				'READ_MEDIA_VIDEO',
				'READ_MEDIA_AUDIO'
			]);
		else
			AndroidPermissions.requestPermissions([
				'READ_EXTERNAL_STORAGE',
				'WRITE_EXTERNAL_STORAGE'
			]);

		if (!AndroidEnvironment.isExternalStorageManager())
		{
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.S)
				AndroidSettings.requestSetting('REQUEST_MANAGE_MEDIA');
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}
	}

	static function extractOnce(?onProgress:Float->String->Void):Void
	{
		var versionFile = '${storagePath}/${VERSION_FILE}';
		var current     = FileSystem.exists(versionFile)
			? StringTools.trim(File.getContent(versionFile))
			: "";

		if (current == APP_VERSION)
		{
			if (onProgress != null) onProgress(1.0, "Done.");
			return;
		}

		copyEmbeddedLibrary("mods", '${storagePath}/mods', onProgress);

		File.saveContent(versionFile, APP_VERSION);

		if (onProgress != null) onProgress(1.0, "Done.");
	}

	static function copyEmbeddedLibrary(prefix:String, dest:String, ?onProgress:Float->String->Void):Void
	{
		var all:Array<String> = [];
		try   { all = OpenFlAssets.list(); }
		catch (e:Dynamic) {}

		var filtered:Array<String> = all.filter(function(k)
			return k.startsWith(prefix + ":") || k.startsWith(prefix + "/")
		);

		var total = filtered.length;
		var idx   = 0;

		for (assetKey in filtered)
		{
			idx++;

			var cleanKey = assetKey
				.replace(prefix + ":", "")
				.replace(prefix + "/", "");

			var destPath = '${dest}/${cleanKey}';
			var destDir  = HxPath.directory(destPath);

			if (onProgress != null)
				onProgress(idx / total, 'Extracting: ${cleanKey}');

			try
			{
				if (!FileSystem.exists(destDir))
					FileSystem.createDirectory(destDir);

				if (FileSystem.exists(destPath)) continue;

				var bytes = OpenFlAssets.getBytes(assetKey);
				if (bytes != null)
					File.saveBytes(destPath, bytes);
			}
			catch (e:Dynamic) {}
		}
	}
	#end
}

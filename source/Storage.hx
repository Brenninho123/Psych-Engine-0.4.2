package;

#if android
import lime.system.JNI;
import sys.FileSystem;
import sys.io.File;
import openfl.utils.Assets as OpenFlAssets;
import haxe.io.Path as HxPath;
#end

using StringTools;

class Storage
{
	#if android
	public static var externalPath(default, null):String = "";
	public static var storagePath(default, null):String  = "";
	public static var dataPath(default, null):String     = "";

	static final APP_FOLDER:String   = ".PsychEngine042";
	static final VERSION_FILE:String = ".version";
	static final APP_VERSION:String  = "0.4.2";

	public static function init():Void
	{
		externalPath = resolveExternalPath();
		dataPath     = resolveDataPath();
		storagePath  = '${externalPath}/${APP_FOLDER}';

		mkdirAll([
			storagePath,
			'${storagePath}/assets',
			'${storagePath}/mods',
			dataPath,
			'${dataPath}/assets',
			'${dataPath}/mods'
		]);

		extractOnce();
	}

	// /sdcard/  via Environment.getExternalStorageDirectory()
	static function resolveExternalPath():String
	{
		try
		{
			var getDir  = JNI.createStaticMethod(
				"android/os/Environment",
				"getExternalStorageDirectory",
				"()Ljava/io/File;"
			);
			var getPath = JNI.createMemberMethod(
				"java/io/File",
				"getAbsolutePath",
				"()Ljava/lang/String;"
			);
			var result:String = getPath(getDir());
			if (result != null && result.length > 0) return result;
		}
		catch (e:Dynamic) {}
		return "/sdcard";
	}

	// /sdcard/Android/data/<package>/files/  via Context.getExternalFilesDir(null)
	static function resolveDataPath():String
	{
		try
		{
			var getInstance = JNI.createStaticMethod(
				"org/haxe/lime/GameActivity",
				"getInstance",
				"()Lorg/haxe/lime/GameActivity;"
			);
			var getExtFiles = JNI.createMemberMethod(
				"android/content/Context",
				"getExternalFilesDir",
				"(Ljava/lang/String;)Ljava/io/File;"
			);
			var getAbsPath = JNI.createMemberMethod(
				"java/io/File",
				"getAbsolutePath",
				"()Ljava/lang/String;"
			);
			var activity = getInstance();
			var dir      = getExtFiles(activity, null);
			var result:String = getAbsPath(dir);
			if (result != null && result.length > 0) return result;
		}
		catch (e:Dynamic) {}
		return '${externalPath}/Android/data';
	}

	static function mkdirAll(paths:Array<String>):Void
	{
		for (p in paths)
		{
			try
			{
				if (!FileSystem.exists(p))
					FileSystem.createDirectory(p);
			}
			catch (e:Dynamic) {}
		}
	}

	static function extractOnce():Void
	{
		var versionFile = '${storagePath}/${VERSION_FILE}';
		var current     = FileSystem.exists(versionFile)
			? StringTools.trim(File.getContent(versionFile))
			: "";

		if (current == APP_VERSION) return;

		copyEmbeddedLibrary("assets", '${storagePath}/assets');
		copyEmbeddedLibrary("mods",   '${storagePath}/mods');

		// espelha mods também no caminho Android/data para fácil acesso pelo gerenciador
		copyEmbeddedLibrary("mods", '${dataPath}/mods');

		File.saveContent(versionFile, APP_VERSION);
	}

	static function copyEmbeddedLibrary(prefix:String, dest:String):Void
	{
		var all:Array<String> = [];
		try   { all = OpenFlAssets.list(); }
		catch (e:Dynamic) {}

		for (assetKey in all)
		{
			if (!assetKey.startsWith(prefix + ":") && !assetKey.startsWith(prefix + "/"))
				continue;

			var cleanKey = assetKey
				.replace(prefix + ":", "")
				.replace(prefix + "/", "");

			var destPath = '${dest}/${cleanKey}';
			var destDir  = HxPath.directory(destPath);

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

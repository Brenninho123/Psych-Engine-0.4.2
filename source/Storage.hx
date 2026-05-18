package;

#if android
import lime.system.JNI;
import sys.FileSystem;
import sys.io.File;
import openfl.utils.Assets as OpenFlAssets;
import haxe.io.Path as HxPath;
#end

class Storage
{
	#if android
	public static var externalPath(default, null):String = "";
	public static var storagePath(default, null):String  = "";

	static final APP_FOLDER:String   = ".PsychEngine042";
	static final VERSION_FILE:String = ".version";
	static final APP_VERSION:String  = "0.4.2";

	public static function init():Void
	{
		externalPath = resolveExternalPath();
		storagePath  = '${externalPath}/${APP_FOLDER}';

		mkdirAll([
			storagePath,
			'${storagePath}/assets',
			'${storagePath}/mods'
		]);

		extractOnce();
	}

	static function resolveExternalPath():String
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
		return getPath(getDir());
	}

	static function mkdirAll(paths:Array<String>):Void
	{
		for (p in paths)
			if (!FileSystem.exists(p))
				FileSystem.createDirectory(p);
	}

	static function extractOnce():Void
	{
		var versionFile = '${storagePath}/${VERSION_FILE}';

		if (FileSystem.exists(versionFile) && File.getContent(versionFile).trim() == APP_VERSION)
			return;

		copyEmbeddedLibrary("assets", '${storagePath}/assets');
		copyEmbeddedLibrary("mods",   '${storagePath}/mods');

		File.saveContent(versionFile, APP_VERSION);
	}

	static function copyEmbeddedLibrary(library:String, dest:String):Void
	{
		var list:Array<String> = [];
		try   { list = OpenFlAssets.list(library); }
		catch (e:Dynamic) {}

		for (assetKey in list)
		{
			var cleanKey = assetKey.replace(library + "/", "").replace(library + ":", "");
			var destPath = '${dest}/${cleanKey}';
			var destDir  = HxPath.directory(destPath);

			if (!FileSystem.exists(destDir))
				FileSystem.createDirectory(destDir);

			if (FileSystem.exists(destPath))
				continue;

			try
			{
				var bytes = OpenFlAssets.getBytes(assetKey);
				if (bytes != null)
					File.saveBytes(destPath, bytes);
			}
			catch (e:Dynamic) {}
		}
	}
	#end
}

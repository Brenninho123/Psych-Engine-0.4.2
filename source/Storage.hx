package;

#if android
import lime.system.JNI;
import lime.system.System as LimeSystem;
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

	public static function init():Void
	{
		storagePath = getExternalDataPath();

		try
		{
			if (!FileSystem.exists(storagePath))
				FileSystem.createDirectory(storagePath);
			if (!FileSystem.exists('${storagePath}/mods'))
				FileSystem.createDirectory('${storagePath}/mods');
		}
		catch (e:Dynamic)
		{
			LimeSystem.exit(1);
		}

		extractOnce();
	}

	public static function requestPermissions():Void
	{
		var sdkInt:Int = getSdkInt();

		if (sdkInt >= 33)
			requestRuntimePermissions(["android.permission.READ_MEDIA_IMAGES",
			                           "android.permission.READ_MEDIA_VIDEO",
			                           "android.permission.READ_MEDIA_AUDIO"]);
		else
			requestRuntimePermissions(["android.permission.READ_EXTERNAL_STORAGE",
			                           "android.permission.WRITE_EXTERNAL_STORAGE"]);

		if (sdkInt >= 30 && !isExternalStorageManager())
			openManageStorageSettings();
	}

	// /sdcard/Android/data/<package>/files  via Context.getExternalFilesDir(null)
	static function getExternalDataPath():String
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
			var result:String = getAbsPath(getExtFiles(getInstance(), null));
			if (result != null && result.length > 0) return result;
		}
		catch (e:Dynamic) {}
		return "/sdcard/Android/data/com.shadowmario.psychengine042/files";
	}

	static function getSdkInt():Int
	{
		try
		{
			return JNI.createStaticField("android/os/Build$VERSION", "SDK_INT", "I").get();
		}
		catch (e:Dynamic) {}
		return 0;
	}

	static function isExternalStorageManager():Bool
	{
		try
		{
			return JNI.createStaticMethod("android/os/Environment", "isExternalStorageManager", "()Z")();
		}
		catch (e:Dynamic) {}
		return false;
	}

	static function requestRuntimePermissions(perms:Array<String>):Void
	{
		try
		{
			var getInstance    = JNI.createStaticMethod(
				"org/haxe/lime/GameActivity",
				"getInstance",
				"()Lorg/haxe/lime/GameActivity;"
			);
			var requestPerms = JNI.createMemberMethod(
				"android/app/Activity",
				"requestPermissions",
				"([Ljava/lang/String;I)V"
			);
			requestPerms(getInstance(), perms, 0);
		}
		catch (e:Dynamic) {}
	}

	static function openManageStorageSettings():Void
	{
		try
		{
			var getInstance  = JNI.createStaticMethod(
				"org/haxe/lime/GameActivity",
				"getInstance",
				"()Lorg/haxe/lime/GameActivity;"
			);
			var uriParse     = JNI.createStaticMethod(
				"android/net/Uri",
				"parse",
				"(Ljava/lang/String;)Landroid/net/Uri;"
			);
			var newIntent    = JNI.createStaticMethod(
				"android/content/Intent",
				"<init>",  // workaround: usamos startActivity via reflection
				"(Ljava/lang/String;Landroid/net/Uri;)V"
			);
			var startActivity = JNI.createMemberMethod(
				"android/app/Activity",
				"startActivity",
				"(Landroid/content/Intent;)V"
			);
			var getPackageName = JNI.createMemberMethod(
				"android/content/Context",
				"getPackageName",
				"()Ljava/lang/String;"
			);
			var activity   = getInstance();
			var pkgName:String = getPackageName(activity);
			var uri        = uriParse("package:" + pkgName);

			var intentCtor = JNI.createMemberMethod(
				"android/content/Intent",
				"<init>",
				"(Ljava/lang/String;Landroid/net/Uri;)V"
			);
			var ACTION = "android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION";
			var intent = JNI.createStaticMethod(
				"android/content/Intent",
				"<init>",
				"()V"
			)();
			startActivity(activity, intent);
		}
		catch (e:Dynamic) {}
	}

	static function extractOnce():Void
	{
		var versionFile = '${storagePath}/${VERSION_FILE}';
		var current     = FileSystem.exists(versionFile)
			? StringTools.trim(File.getContent(versionFile))
			: "";

		if (current == APP_VERSION) return;

		copyEmbeddedLibrary("mods", '${storagePath}/mods');

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

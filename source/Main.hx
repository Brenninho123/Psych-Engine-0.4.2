package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
#if android
import lime.system.JNI;
#end

class Main extends Sprite
{
	var gameWidth:Int        = 1280;
	var gameHeight:Int       = 720;
	var initialState:Class<FlxState> = TitleState;
	var framerate:Int        = 60;
	var skipSplash:Bool      = true;
	var startFullscreen:Bool = false;
	public static var fpsVar:FPS;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		#if !debug
		initialState = TitleState;
		#end

		#if desktop
		Paths.getModFolders();
		#end

		addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));

		#if !mobile
		fpsVar = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		if (fpsVar != null)
			fpsVar.visible = ClientPrefs.showFPS;
		#end

		#if (html5 || mobile)
		FlxG.autoPause     = false;
		FlxG.mouse.visible = false;
		#end

		#if android
		lime.system.System.allowScreenTimeout = false;
		requestExternalStoragePermission();
		#end

		#if mobile
		stage.addEventListener(Event.RESIZE, onStageResize);
		#end
	}

	#if android
	private function requestExternalStoragePermission():Void
	{
		var getActivity = JNI.createStaticMethod(
			"org/haxe/lime/GameActivity",
			"getInstance",
			"()Lorg/haxe/lime/GameActivity;"
		);
		var activity = getActivity();

		var sdkVersion:Int = JNI.createStaticField(
			"android/os/Build$VERSION",
			"SDK_INT",
			"I"
		).get();

		var perms:Array<String> = [
			"android.permission.READ_EXTERNAL_STORAGE",
			"android.permission.WRITE_EXTERNAL_STORAGE"
		];

		if (sdkVersion >= 30)
			perms.push("android.permission.MANAGE_EXTERNAL_STORAGE");

		if (sdkVersion >= 33)
		{
			perms.push("android.permission.READ_MEDIA_IMAGES");
			perms.push("android.permission.READ_MEDIA_AUDIO");
			perms.push("android.permission.READ_MEDIA_VIDEO");
		}

		var requestPermissions = JNI.createMemberMethod(
			"android/app/Activity",
			"requestPermissions",
			"([Ljava/lang/String;I)V"
		);
		requestPermissions(activity, perms, 0);
	}
	#end

	#if mobile
	private function onStageResize(E:Event):Void
	{
		FlxG.resizeGame(stage.stageWidth, stage.stageHeight);
	}
	#end
}

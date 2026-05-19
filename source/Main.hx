package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
#if android
import sys.thread.Thread;
import sys.thread.Mutex;
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
		if (stage != null) init();
		else addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
	}

	private function setupGame():Void
	{
		#if android
		Storage.requestPermissions();
		showLoadingScreen();
		#else
		finishSetup();
		#end
	}

	#if android
	private function showLoadingScreen():Void
	{
		var sw:Float = stage.stageWidth;
		var sh:Float = stage.stageHeight;

		var bg = new Shape();
		bg.graphics.beginFill(0x000000);
		bg.graphics.drawRect(0, 0, sw, sh);
		bg.graphics.endFill();
		addChild(bg);

		var titleFmt = new TextFormat("_sans", 32, 0xFFFFFF, true);
		var title    = new TextField();
		title.defaultTextFormat = titleFmt;
		title.text              = "FNF: Psych Engine 0.4.2";
		title.autoSize          = TextFieldAutoSize.CENTER;
		title.selectable        = false;
		title.x                 = (sw - title.textWidth) / 2;
		title.y                 = sh * 0.3;
		addChild(title);

		var subtitleFmt = new TextFormat("_sans", 18, 0xAAAAAA);
		var subtitle    = new TextField();
		subtitle.defaultTextFormat = subtitleFmt;
		subtitle.text              = "Extracting files, please wait...";
		subtitle.autoSize          = TextFieldAutoSize.CENTER;
		subtitle.selectable        = false;
		subtitle.x                 = (sw - subtitle.textWidth) / 2;
		subtitle.y                 = title.y + 50;
		addChild(subtitle);

		var barW:Float = sw * 0.65;
		var barH:Float = 22;
		var barX:Float = (sw - barW) / 2;
		var barY:Float = sh * 0.55;

		var barBg = new Shape();
		barBg.graphics.beginFill(0x333333);
		barBg.graphics.drawRoundRect(barX, barY, barW, barH, 11, 11);
		barBg.graphics.endFill();
		addChild(barBg);

		var barFill = new Shape();
		addChild(barFill);

		var statusFmt = new TextFormat("_sans", 14, 0x888888);
		var statusTF  = new TextField();
		statusTF.defaultTextFormat = statusFmt;
		statusTF.width             = sw;
		statusTF.autoSize          = TextFieldAutoSize.CENTER;
		statusTF.selectable        = false;
		statusTF.x                 = 0;
		statusTF.y                 = barY + barH + 10;
		addChild(statusTF);

		var mutex    = new Mutex();
		var progress = {v: 0.0};
		var msg      = {v: "Preparing..."};
		var done     = {v: false};

		Thread.create(function()
		{
			Storage.init(function(p:Float, m:String)
			{
				mutex.acquire();
				progress.v = p;
				msg.v      = m;
				mutex.release();
			});
			mutex.acquire();
			done.v = true;
			mutex.release();
		});

		var onFrame:Event->Void = null;
		onFrame = function(e:Event)
		{
			mutex.acquire();
			var p:Float  = progress.v;
			var m:String = msg.v;
			var d:Bool   = done.v;
			mutex.release();

			barFill.graphics.clear();
			if (p > 0)
			{
				barFill.graphics.beginFill(0xFF2E6EE3);
				barFill.graphics.drawRoundRect(barX, barY, barW * p, barH, 11, 11);
				barFill.graphics.endFill();
			}

			statusTF.text = m;

			if (d)
			{
				stage.removeEventListener(Event.ENTER_FRAME, onFrame);
				removeChild(barFill);
				removeChild(barBg);
				removeChild(statusTF);
				removeChild(subtitle);
				removeChild(title);
				removeChild(bg);
				finishSetup();
			}
		};

		stage.addEventListener(Event.ENTER_FRAME, onFrame);
	}
	#end

	private function finishSetup():Void
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
		#end

		#if mobile
		stage.addEventListener(Event.RESIZE, onStageResize);
		#end
	}

	#if mobile
	private function onStageResize(E:Event):Void
	{
		FlxG.resizeGame(stage.stageWidth, stage.stageHeight);
	}
	#end
}

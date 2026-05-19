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

		function makeTF(size:Int, color:UInt, bold:Bool = false):TextField
		{
			var tf  = new TextField();
			tf.defaultTextFormat = new TextFormat("_sans", size, color, bold);
			tf.autoSize   = TextFieldAutoSize.CENTER;
			tf.selectable = false;
			tf.width      = sw;
			tf.x          = 0;
			return tf;
		}

		var titleTF = makeTF(30, 0xFFFFFF, true);
		titleTF.text = "FNF: Psych Engine 0.4.2";
		titleTF.y    = sh * 0.22;
		addChild(titleTF);

		var libTF = makeTF(20, 0xDDDDDD);
		libTF.text = "Preparing...";
		libTF.y    = sh * 0.42;
		addChild(libTF);

		var fileTF = makeTF(14, 0x888888);
		fileTF.text = "";
		fileTF.y    = sh * 0.49;
		addChild(fileTF);

		var countTF = makeTF(14, 0x666666);
		countTF.text = "";
		countTF.y    = sh * 0.55;
		addChild(countTF);

		var barW:Float = sw * 0.68;
		var barH:Float = 18;
		var barX:Float = (sw - barW) / 2;
		var barY:Float = sh * 0.46;

		var barBg = new Shape();
		barBg.graphics.beginFill(0x222222);
		barBg.graphics.drawRoundRect(barX, barY, barW, barH, 9, 9);
		barBg.graphics.endFill();
		addChild(barBg);

		var barFill = new Shape();
		addChild(barFill);

		var mutex   = new Mutex();
		var state   = { pct: 0.0, lib: "Preparing...", file: "", cur: 0, total: 0, done: false };

		Thread.create(function()
		{
			Storage.init(function(pct:Float, lib:String, file:String, cur:Int, total:Int)
			{
				mutex.acquire();
				state.pct   = pct;
				state.lib   = lib;
				state.file  = file;
				state.cur   = cur;
				state.total = total;
				mutex.release();
			});
			mutex.acquire();
			state.done = true;
			mutex.release();
		});

		var onFrame:Event->Void = null;
		onFrame = function(_)
		{
			mutex.acquire();
			var pct   = state.pct;
			var lib   = state.lib;
			var file  = state.file;
			var cur   = state.cur;
			var total = state.total;
			var done  = state.done;
			mutex.release();

			barFill.graphics.clear();
			if (pct > 0)
			{
				barFill.graphics.beginFill(0x3399FF);
				barFill.graphics.drawRoundRect(barX, barY, barW * pct, barH, 9, 9);
				barFill.graphics.endFill();
			}

			libTF.text   = lib;
			fileTF.text  = file.length > 60 ? '...${file.substr(file.length - 57)}' : file;
			countTF.text = total > 0 ? '${cur} / ${total}' : "";

			if (done)
			{
				stage.removeEventListener(Event.ENTER_FRAME, onFrame);
				removeChild(barFill);
				removeChild(barBg);
				removeChild(countTF);
				removeChild(fileTF);
				removeChild(libTF);
				removeChild(titleTF);
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

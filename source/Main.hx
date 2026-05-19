package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
#if android
import sys.thread.Thread;
import sys.thread.Mutex;
import sys.io.File;
import sys.FileSystem;
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

		setupCrashHandler();
		setupGame();
	}

	// ─── Crash Handler ────────────────────────────────────────────────────────

	private function setupCrashHandler():Void
	{
		try
		{
			Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
				UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError
			);
		}
		catch (e:Dynamic) {}
	}

	private function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		try { e.preventDefault(); } catch (_:Dynamic) {}

		var msg:String = "";
		try { msg = Std.string(e.error); } catch (_:Dynamic) { msg = "Unknown error"; }

		writeCrashLog(msg);
		showCrashScreen(msg);
	}

	private function writeCrashLog(msg:String):Void
	{
		#if android
		try
		{
			var basePath:String = Storage.storagePath != null && Storage.storagePath.length > 0
				? Storage.storagePath
				: "/sdcard/Android/data/com.shadowmario.psychengine042/files";

			if (!FileSystem.exists(basePath))
				FileSystem.createDirectory(basePath);

			var timestamp:String = Date.now().toString();
			var content:String   =
				'=== Psych Engine 0.4.2 Crash Log ===\n' +
				'Time:    $timestamp\n' +
				'Version: 0.4.2\n' +
				'Error:   $msg\n' +
				'=====================================\n';

			var logPath:String = '$basePath/crash_log.txt';
			var existing:String = FileSystem.exists(logPath) ? File.getContent(logPath) : "";
			File.saveContent(logPath, content + "\n" + existing);
		}
		catch (logErr:Dynamic) {}
		#end

		#if sys
		try
		{
			var timestamp:String = Date.now().toString();
			var content:String   =
				'=== Psych Engine 0.4.2 Crash Log ===\n' +
				'Time:  $timestamp\n' +
				'Error: $msg\n' +
				'=====================================\n\n';
			var logPath:String = "crash_log.txt";
			var existing:String = sys.FileSystem.exists(logPath) ? sys.io.File.getContent(logPath) : "";
			sys.io.File.saveContent(logPath, content + existing);
		}
		catch (e:Dynamic) {}
		#end
	}

	private function showCrashScreen(msg:String):Void
	{
		try
		{
			var sw:Float = stage != null ? stage.stageWidth  : 1280;
			var sh:Float = stage != null ? stage.stageHeight : 720;

			var overlay = new Sprite();

			var bg = new Shape();
			bg.graphics.beginFill(0x1A0000);
			bg.graphics.drawRect(0, 0, sw, sh);
			bg.graphics.endFill();
			overlay.addChild(bg);

			function addTF(text:String, size:Int, color:UInt, y:Float, bold:Bool = false):Void
			{
				var tf = new TextField();
				tf.defaultTextFormat = new TextFormat("_sans", size, color, bold);
				tf.autoSize   = TextFieldAutoSize.CENTER;
				tf.selectable = true;
				tf.width      = sw;
				tf.x          = 0;
				tf.y          = y;
				tf.text       = text;
				overlay.addChild(tf);
			}

			addTF("CRASH!", 48, 0xFF3333, sh * 0.08, true);
			addTF("The game has crashed. Details below:", 20, 0xCCCCCC, sh * 0.22);

			var errBox = new TextField();
			errBox.defaultTextFormat = new TextFormat("_typewriter", 16, 0xFF9966);
			errBox.width        = sw * 0.85;
			errBox.height       = sh * 0.32;
			errBox.x            = sw * 0.075;
			errBox.y            = sh * 0.29;
			errBox.text         = msg;
			errBox.wordWrap     = true;
			errBox.multiline    = true;
			errBox.selectable   = true;
			errBox.border       = true;
			errBox.borderColor  = 0x550000;
			errBox.background   = true;
			errBox.backgroundColor = 0x220000;
			overlay.addChild(errBox);

			#if android
			var logPath = Storage.storagePath != null && Storage.storagePath.length > 0
				? '${Storage.storagePath}/crash_log.txt'
				: '/sdcard/Android/data/com.shadowmario.psychengine042/files/crash_log.txt';
			addTF('Crash log saved to:\n$logPath', 16, 0x888888, sh * 0.65);
			addTF("Tap anywhere to close the game.", 20, 0xAAAAAA, sh * 0.80);
			#else
			addTF("Crash log saved to: crash_log.txt", 16, 0x888888, sh * 0.65);
			addTF("Click anywhere to close the game.", 20, 0xAAAAAA, sh * 0.80);
			#end

			overlay.addEventListener(Event.ENTER_FRAME, function(_) {
				if (FlxG.mouse.justPressed || (FlxG.touches.list.length > 0 && FlxG.touches.list[0].justPressed))
					lime.system.System.exit(1);
			});

			addChild(overlay);
		}
		catch (e:Dynamic)
		{
			lime.system.System.exit(1);
		}
	}

	// ─── Game Setup ───────────────────────────────────────────────────────────

	private function setupGame():Void
	{
		#if android
		try { Storage.requestPermissions(); } catch (e:Dynamic) { writeCrashLog("requestPermissions: " + e); }
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
			var tf = new TextField();
			tf.defaultTextFormat = new TextFormat("_sans", size, color, bold);
			tf.autoSize   = TextFieldAutoSize.CENTER;
			tf.selectable = false;
			tf.width      = sw;
			tf.x          = 0;
			return tf;
		}

		var titleTF = makeTF(34, 0xFFFFFF, true);
		titleTF.text = "FNF: Psych Engine 0.4.2";
		titleTF.y    = sh * 0.20;
		addChild(titleTF);

		var subTF = makeTF(17, 0x888888);
		subTF.text = "Loading, please wait...";
		subTF.y    = titleTF.y + 54;
		addChild(subTF);

		var barW:Float = sw * 0.68;
		var barH:Float = 20;
		var barX:Float = (sw - barW) / 2;
		var barY:Float = sh * 0.47;

		var barTrack = new Shape();
		barTrack.graphics.beginFill(0x1A1A1A);
		barTrack.graphics.drawRoundRect(barX, barY, barW, barH, 10, 10);
		barTrack.graphics.endFill();
		addChild(barTrack);

		var barFill = new Shape();
		addChild(barFill);

		var pctTF = makeTF(13, 0x555555);
		pctTF.text = "0%";
		pctTF.y    = barY - 22;
		addChild(pctTF);

		var libTF = makeTF(18, 0xDDDDDD);
		libTF.text = "Preparing...";
		libTF.y    = barY + barH + 12;
		addChild(libTF);

		var fileTF = makeTF(13, 0x666666);
		fileTF.text = "";
		fileTF.y    = libTF.y + 28;
		addChild(fileTF);

		var countTF = makeTF(13, 0x444444);
		countTF.text = "";
		countTF.y    = fileTF.y + 20;
		addChild(countTF);

		var statusTF = makeTF(15, 0x33AA55);
		statusTF.text    = "";
		statusTF.visible = false;
		statusTF.y       = sh * 0.72;
		addChild(statusTF);

		var mutex = new Mutex();
		var state = {
			pct:    0.0,
			lib:    "Preparing...",
			file:   "",
			cur:    0,
			total:  0,
			status: "",
			error:  "",
			done:   false
		};

		Thread.create(function()
		{
			try
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
				state.status = 'Done  —  ${Storage.extractedFiles} extracted, ${Storage.skippedFiles} skipped';
				state.done   = true;
				mutex.release();
			}
			catch (e:Dynamic)
			{
				mutex.acquire();
				state.error = Std.string(e);
				state.done  = true;
				mutex.release();
				writeCrashLog("Storage.init: " + e);
			}
		});

		var onFrame:Event->Void = null;
		onFrame = function(_)
		{
			mutex.acquire();
			var pct    = state.pct;
			var lib    = state.lib;
			var file   = state.file;
			var cur    = state.cur;
			var total  = state.total;
			var status = state.status;
			var error  = state.error;
			var done   = state.done;
			mutex.release();

			// barra de progresso
			barFill.graphics.clear();
			if (pct > 0)
			{
				var fillW = barW * Math.min(pct, 1.0);
				// gradiente simples: azul → verde conforme progresso
				var r:Int = Std.int(0x33 + (0x00 - 0x33) * pct);
				var g:Int = Std.int(0x66 + (0xCC - 0x66) * pct);
				var b:Int = Std.int(0xFF + (0x55 - 0xFF) * pct);
				barFill.graphics.beginFill((r << 16) | (g << 8) | b);
				barFill.graphics.drawRoundRect(barX, barY, fillW, barH, 10, 10);
				barFill.graphics.endFill();
			}

			pctTF.text   = Std.int(pct * 100) + "%";
			libTF.text   = lib;
			fileTF.text  = file.length > 58 ? '...${file.substr(file.length - 55)}' : file;
			countTF.text = total > 0 ? '${cur} / ${total} files' : "";

			if (error.length > 0)
			{
				libTF.text      = "Error during extraction";
				fileTF.text     = error.length > 80 ? error.substr(0, 80) + "..." : error;
				statusTF.text   = "Continuing anyway...";
				statusTF.visible = true;
			}
			else if (status.length > 0)
			{
				statusTF.text    = status;
				statusTF.visible = true;
			}

			if (done)
			{
				stage.removeEventListener(Event.ENTER_FRAME, onFrame);
				// pequena pausa visual antes de prosseguir
				haxe.Timer.delay(function()
				{
					removeChild(countTF);
					removeChild(fileTF);
					removeChild(libTF);
					removeChild(statusTF);
					removeChild(pctTF);
					removeChild(barFill);
					removeChild(barTrack);
					removeChild(subTF);
					removeChild(titleTF);
					removeChild(bg);
					finishSetup();
				}, 400);
			}
		};
		stage.addEventListener(Event.ENTER_FRAME, onFrame);
	}
	#end

	private function finishSetup():Void
	{
		try
		{
			#if !debug
			initialState = TitleState;
			#end

			#if desktop
			try { Paths.getModFolders(); } catch (e:Dynamic) {}
			#end

			addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));
		}
		catch (e:Dynamic)
		{
			writeCrashLog("FlxGame init: " + e);
			showCrashScreen("Failed to start game:\n" + Std.string(e));
			return;
		}

		#if !mobile
		try
		{
			fpsVar = new FPS(10, 3, 0xFFFFFF);
			addChild(fpsVar);
			if (fpsVar != null)
				fpsVar.visible = ClientPrefs.showFPS;
		}
		catch (e:Dynamic) {}
		#end

		#if (html5 || mobile)
		try { FlxG.autoPause     = false; } catch (e:Dynamic) {}
		try { FlxG.mouse.visible = false; } catch (e:Dynamic) {}
		#end

		#if android
		try { lime.system.System.allowScreenTimeout = false; } catch (e:Dynamic) {}
		#end

		#if mobile
		try { stage.addEventListener(Event.RESIZE, onStageResize); } catch (e:Dynamic) {}
		#end
	}

	#if mobile
	private function onStageResize(E:Event):Void
	{
		try { FlxG.resizeGame(stage.stageWidth, stage.stageHeight); } catch (e:Dynamic) {}
	}
	#end
}

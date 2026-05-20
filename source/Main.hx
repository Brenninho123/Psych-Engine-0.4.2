package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
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
#if sys
import sys.io.File as SysFile;
import sys.FileSystem as SysFS;
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
	public static var instance:Main;

	public static function main():Void
	{
		try { Lib.current.addChild(new Main()); } catch (_:Dynamic) {}
	}

	public function new()
	{
		super();
		instance = this;
		try
		{
			if (stage != null) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		catch (e:Dynamic) { writeCrashLog("constructor\n" + e); safeExit(); }
	}

	private function init(?_:Event):Void
	{
		try { if (hasEventListener(Event.ADDED_TO_STAGE)) removeEventListener(Event.ADDED_TO_STAGE, init); }
		catch (_:Dynamic) {}

		setupCrashHandler();
		setupGame();
	}

	private function setupCrashHandler():Void
	{
		try
		{
			Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
				UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError, false, 100
			);
		}
		catch (_:Dynamic) {}
	}

	private function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		try { e.preventDefault(); e.stopImmediatePropagation(); } catch (_:Dynamic) {}
		var msg = "Unknown error";
		try { if (e.error != null) msg = Std.string(e.error); } catch (_:Dynamic) {}
		writeCrashLog(msg);
		showCrashScreen(msg);
	}

	private function writeCrashLog(msg:String):Void
	{
		var ts = "";
		try { ts = Date.now().toString(); } catch (_:Dynamic) {}
		var body = '=== Psych Engine 0.4.2 ===\nTime: $ts\n\n$msg\n\n';

		#if android
		try
		{
			var base = (Storage.storagePath != null && Storage.storagePath.length > 0)
				? Storage.storagePath
				: "/sdcard/Android/data/com.shadowmario.psychengine042/files";
			if (!FileSystem.exists(base)) FileSystem.createDirectory(base);
			var path = '$base/crash_log.txt';
			var prev = FileSystem.exists(path) ? File.getContent(path) : "";
			File.saveContent(path, body + prev);
		}
		catch (_:Dynamic) {}
		#end

		#if (sys && !android)
		try
		{
			var path = "crash_log.txt";
			var prev = SysFS.exists(path) ? SysFile.getContent(path) : "";
			SysFile.saveContent(path, body + prev);
		}
		catch (_:Dynamic) {}
		#end
	}

	private function showCrashScreen(msg:String):Void
	{
		try
		{
			var sw:Float = (stage != null) ? stage.stageWidth  : 1280;
			var sh:Float = (stage != null) ? stage.stageHeight : 720;

			while (numChildren > 0)
				try { removeChildAt(0); } catch (_:Dynamic) { break; }

			var panel = new Sprite();

			var bg = new Shape();
			bg.graphics.beginFill(0x110000);
			bg.graphics.drawRect(0, 0, sw, sh);
			bg.graphics.endFill();
			panel.addChild(bg);

			function addLabel(text:String, size:Int, col:UInt, yPos:Float, bold:Bool = false, selectable:Bool = false):TextField
			{
				var t = new TextField();
				t.defaultTextFormat = new TextFormat("_sans", size, col, bold);
				t.autoSize   = TextFieldAutoSize.CENTER;
				t.selectable = selectable;
				t.wordWrap   = false;
				t.width      = sw;
				t.x          = 0;
				t.y          = yPos;
				t.text       = text;
				panel.addChild(t);
				return t;
			}

			addLabel("CRASH!", 52, 0xFF2222, sh * 0.05, true);
			addLabel("The game crashed. See details below.", 18, 0xBBBBBB, sh * 0.20);

			var errBox = new TextField();
			errBox.defaultTextFormat = new TextFormat("_typewriter", 15, 0xFFAA66);
			errBox.width             = sw * 0.86;
			errBox.height            = sh * 0.30;
			errBox.x                 = sw * 0.07;
			errBox.y                 = sh * 0.27;
			errBox.wordWrap          = true;
			errBox.multiline         = true;
			errBox.selectable        = true;
			errBox.border            = true;
			errBox.borderColor       = 0x440000;
			errBox.background        = true;
			errBox.backgroundColor   = 0x1A0000;
			errBox.text              = msg;
			panel.addChild(errBox);

			#if android
			var logPath = (Storage.storagePath != null && Storage.storagePath.length > 0)
				? '${Storage.storagePath}/crash_log.txt'
				: '/sdcard/Android/data/com.shadowmario.psychengine042/files/crash_log.txt';
			addLabel('Log: $logPath', 13, 0x555555, sh * 0.63);
			addLabel("Tap to close the game.", 20, 0x888888, sh * 0.78);
			#else
			addLabel("Log saved to: crash_log.txt", 13, 0x555555, sh * 0.63);
			addLabel("Click to close the game.", 20, 0x888888, sh * 0.78);
			#end

			panel.addEventListener(MouseEvent.CLICK,       function(_) safeExit());
			panel.addEventListener(TouchEvent.TOUCH_BEGIN, function(_) safeExit());

			addChild(panel);
		}
		catch (_:Dynamic) { safeExit(); }
	}

	private function safeExit():Void
	{
		try { lime.system.System.exit(1); } catch (_:Dynamic) {}
	}

	private function setupGame():Void
	{
		#if android
		try { Storage.requestPermissions(); } catch (e:Dynamic) { writeCrashLog("permissions\n" + e); }
		showLoadingScreen();
		#else
		finishSetup();
		#end
	}

	#if android
	private function showLoadingScreen():Void
	{
		var sw:Float = 1280;
		var sh:Float = 720;
		try { sw = stage.stageWidth; sh = stage.stageHeight; } catch (_:Dynamic) {}

		var bg = new Shape();
		bg.graphics.beginFill(0x000000);
		bg.graphics.drawRect(0, 0, sw, sh);
		bg.graphics.endFill();
		addChild(bg);

		function mktf(size:Int, col:UInt, bold:Bool = false):TextField
		{
			var t = new TextField();
			t.defaultTextFormat = new TextFormat("_sans", size, col, bold);
			t.autoSize   = TextFieldAutoSize.CENTER;
			t.selectable = false;
			t.width      = sw;
			t.x          = 0;
			return t;
		}

		var titleTF = mktf(34, 0xFFFFFF, true);
		titleTF.text = "FNF: Psych Engine 0.4.2";
		titleTF.y    = sh * 0.14;
		addChild(titleTF);

		var subTF = mktf(15, 0x666666);
		subTF.text = "Preparing files...";
		subTF.y    = titleTF.y + 52;
		addChild(subTF);

		var barW:Float = sw * 0.68;
		var barH:Float = 18;
		var barX:Float = (sw - barW) / 2;
		var barY:Float = sh * 0.44;

		var barBg = new Shape();
		barBg.graphics.beginFill(0x111111);
		barBg.graphics.drawRoundRect(barX, barY, barW, barH, 9, 9);
		barBg.graphics.endFill();
		addChild(barBg);

		var barFill = new Shape();
		addChild(barFill);

		var pctTF = mktf(13, 0x3A3A3A);
		pctTF.text = "";
		pctTF.y    = barY - 22;
		addChild(pctTF);

		var libTF = mktf(17, 0xDDDDDD);
		libTF.text = "";
		libTF.y    = barY + barH + 14;
		addChild(libTF);

		var fileTF = mktf(12, 0x4A4A4A);
		fileTF.text = "";
		fileTF.y    = libTF.y + 26;
		addChild(fileTF);

		var countTF = mktf(12, 0x333333);
		countTF.text = "";
		countTF.y    = fileTF.y + 20;
		addChild(countTF);

		var totalScanTF = mktf(12, 0x2A2A2A);
		totalScanTF.text = "";
		totalScanTF.y    = countTF.y + 18;
		addChild(totalScanTF);

		var statusTF = mktf(14, 0x44CC66);
		statusTF.text    = "";
		statusTF.visible = false;
		statusTF.y       = sh * 0.76;
		addChild(statusTF);

		var mutex = new Mutex();
		var s = {
			pct:    0.0,
			lib:    "",
			file:   "",
			cur:    0,
			total:  0,
			status: "",
			err:    "",
			done:   false
		};

		Thread.create(function()
		{
			try
			{
				Storage.init(function(pct:Float, lib:String, file:String, cur:Int, total:Int)
				{
					try
					{
						mutex.acquire();
						s.pct   = pct;
						s.lib   = lib;
						s.file  = file;
						s.cur   = cur;
						s.total = total;
						mutex.release();
					}
					catch (_:Dynamic) {}
				});

				mutex.acquire();
				s.status = '${Storage.extractedFiles} extracted  ·  ${Storage.skippedFiles} unchanged  ·  ${Storage.errorFiles} errors';
				s.done   = true;
				mutex.release();
			}
			catch (e:Dynamic)
			{
				try
				{
					writeCrashLog("Storage.init\n" + e);
					mutex.acquire();
					s.err  = Std.string(e);
					s.done = true;
					mutex.release();
				}
				catch (_:Dynamic) {}
			}
		});

		var smooth:Float = 0;
		var onFrame:Event->Void = null;
		onFrame = function(_)
		{
			var pct    = 0.0;
			var lib    = "";
			var file   = "";
			var cur    = 0;
			var total  = 0;
			var status = "";
			var err    = "";
			var done   = false;

			try
			{
				mutex.acquire();
				pct    = s.pct;
				lib    = s.lib;
				file   = s.file;
				cur    = s.cur;
				total  = s.total;
				status = s.status;
				err    = s.err;
				done   = s.done;
				mutex.release();
			}
			catch (_:Dynamic) {}

			smooth += (pct - smooth) * 0.10;
			if (pct >= 1.0) smooth = 1.0;

			try
			{
				barFill.graphics.clear();
				if (smooth > 0.001)
				{
					var t:Float = smooth;
					var r = Std.int(0x00 + (0x22 - 0x00) * (1 - t));
					var g = Std.int(0x88 + (0xFF - 0x88) * t);
					var b = Std.int(0xFF + (0x44 - 0xFF) * t);
					barFill.graphics.beginFill((r << 16) | (g << 8) | b);
					barFill.graphics.drawRoundRect(barX, barY, barW * smooth, barH, 9, 9);
					barFill.graphics.endFill();
				}
			}
			catch (_:Dynamic) {}

			try
			{
				pctTF.text      = total > 0 ? Std.int(smooth * 100) + "%" : "";
				libTF.text      = err.length > 0 ? "Error — continuing" : lib;
				fileTF.text     = file.length > 62 ? '...${file.substr(file.length - 59)}' : file;
				countTF.text    = cur > 0 ? '${cur} / ${total} files' : "";
				totalScanTF.text = Storage.totalFiles > 0 ? '${Storage.totalFiles} total assets detected' : "";
			}
			catch (_:Dynamic) {}

			try
			{
				if (err.length > 0)
				{
					statusTF.text    = err.length > 70 ? err.substr(0, 70) + "…" : err;
					statusTF.visible = true;
				}
				else if (status.length > 0)
				{
					statusTF.text    = status;
					statusTF.visible = true;
				}
			}
			catch (_:Dynamic) {}

			if (done)
			{
				try { stage.removeEventListener(Event.ENTER_FRAME, onFrame); } catch (_:Dynamic) {}
				haxe.Timer.delay(function()
				{
					for (c in [totalScanTF, statusTF, countTF, fileTF, libTF, pctTF, barFill, barBg, subTF, titleTF, bg])
						try { removeChild(c); } catch (_:Dynamic) {}
					finishSetup();
				}, 350);
			}
		};

		try { stage.addEventListener(Event.ENTER_FRAME, onFrame); }
		catch (e:Dynamic)
		{
			writeCrashLog("ENTER_FRAME\n" + e);
			finishSetup();
		}
	}
	#end

	private function finishSetup():Void
	{
		try
		{
			#if !debug
			initialState = TitleState;
			#end
		}
		catch (_:Dynamic) {}

		#if desktop
		try { Paths.getModFolders(); } catch (_:Dynamic) {}
		#end

		try
		{
			addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));
		}
		catch (e:Dynamic)
		{
			writeCrashLog("FlxGame\n" + e);
			showCrashScreen("Failed to start:\n" + Std.string(e));
			return;
		}

		#if !mobile
		try
		{
			fpsVar = new FPS(10, 3, 0xFFFFFF);
			addChild(fpsVar);
			if (fpsVar != null) fpsVar.visible = ClientPrefs.showFPS;
		}
		catch (_:Dynamic) {}
		#end

		#if (html5 || mobile)
		try { FlxG.autoPause     = false; } catch (_:Dynamic) {}
		try { FlxG.mouse.visible = false; } catch (_:Dynamic) {}
		#end

		#if android
		try { lime.system.System.allowScreenTimeout = false; } catch (_:Dynamic) {}
		#end

		#if mobile
		try { stage.addEventListener(Event.RESIZE, onStageResize); } catch (_:Dynamic) {}
		#end
	}

	#if mobile
	private function onStageResize(_:Event):Void
	{
		try { FlxG.resizeGame(stage.stageWidth, stage.stageHeight); } catch (_:Dynamic) {}
	}
	#end
}

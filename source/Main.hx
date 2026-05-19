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
		try { Lib.current.addChild(new Main()); }
		catch (e:Dynamic) {}
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
		catch (e:Dynamic) { safeExit(); }
	}

	private function init(?E:Event):Void
	{
		try
		{
			if (hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE, init);
		}
		catch (e:Dynamic) {}

		setupCrashHandler();
		setupGame();
	}

	private function setupCrashHandler():Void
	{
		try
		{
			Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
				UncaughtErrorEvent.UNCAUGHT_ERROR,
				onUncaughtError,
				false, 100
			);
		}
		catch (e:Dynamic) {}
	}

	private function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		try { e.preventDefault(); e.stopImmediatePropagation(); }
		catch (_:Dynamic) {}

		var msg:String = "Unknown error";
		try
		{
			if (e.error != null)
				msg = Std.string(e.error);
		}
		catch (_:Dynamic) {}

		writeCrashLog(msg);
		showCrashScreen(msg);
	}

	private function writeCrashLog(msg:String):Void
	{
		var timestamp = "";
		try { timestamp = Date.now().toString(); } catch (_:Dynamic) {}

		var content = '=== Psych Engine 0.4.2 Crash ===\nTime: $timestamp\n\n$msg\n\n';

		#if android
		try
		{
			var base = (Storage.storagePath != null && Storage.storagePath.length > 0)
				? Storage.storagePath
				: "/sdcard/Android/data/com.shadowmario.psychengine042/files";

			if (!FileSystem.exists(base))
				FileSystem.createDirectory(base);

			var path = '$base/crash_log.txt';
			var prev = FileSystem.exists(path) ? File.getContent(path) : "";
			File.saveContent(path, content + prev);
		}
		catch (_:Dynamic) {}
		#end

		#if (sys && !android)
		try
		{
			var path = "crash_log.txt";
			var prev = SysFS.exists(path) ? SysFile.getContent(path) : "";
			SysFile.saveContent(path, content + prev);
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

			inline function tf(text:String, size:Int, col:UInt, yPos:Float, bold:Bool = false):Void
			{
				var t = new TextField();
				t.defaultTextFormat = new TextFormat("_sans", size, col, bold);
				t.autoSize   = TextFieldAutoSize.CENTER;
				t.selectable = false;
				t.wordWrap   = false;
				t.width      = sw;
				t.x          = 0;
				t.y          = yPos;
				t.text       = text;
				panel.addChild(t);
			}

			tf("CRASH!", 52, 0xFF2222, sh * 0.06, true);
			tf("The game encountered an unrecoverable error.", 19, 0xBBBBBB, sh * 0.21);

			var errBox = new TextField();
			errBox.defaultTextFormat = new TextFormat("_typewriter", 15, 0xFFAA66);
			errBox.width       = sw * 0.86;
			errBox.height      = sh * 0.28;
			errBox.x           = sw * 0.07;
			errBox.y           = sh * 0.28;
			errBox.wordWrap    = true;
			errBox.multiline   = true;
			errBox.selectable  = true;
			errBox.border      = true;
			errBox.borderColor = 0x440000;
			errBox.background  = true;
			errBox.backgroundColor = 0x1A0000;
			errBox.text        = msg;
			panel.addChild(errBox);

			#if android
			var logPath = (Storage.storagePath != null && Storage.storagePath.length > 0)
				? '${Storage.storagePath}/crash_log.txt'
				: '/sdcard/Android/data/com.shadowmario.psychengine042/files/crash_log.txt';
			tf('Log saved to: $logPath', 14, 0x666666, sh * 0.64);
			tf("Tap anywhere to close.", 20, 0x999999, sh * 0.78);
			#else
			tf("Log saved to: crash_log.txt", 14, 0x666666, sh * 0.64);
			tf("Click anywhere to close.", 20, 0x999999, sh * 0.78);
			#end

			panel.addEventListener(openfl.events.MouseEvent.CLICK,  function(_) safeExit());
			panel.addEventListener(openfl.events.TouchEvent.TOUCH_TAP, function(_) safeExit());

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
		var sw:Float = 0;
		var sh:Float = 0;
		try { sw = stage.stageWidth; sh = stage.stageHeight; }
		catch (_:Dynamic) { sw = 1280; sh = 720; }

		var bg = new Shape();
		bg.graphics.beginFill(0x000000);
		bg.graphics.drawRect(0, 0, sw, sh);
		bg.graphics.endFill();
		addChild(bg);

		inline function makeTF(size:Int, col:UInt, bold:Bool = false):TextField
		{
			var t = new TextField();
			t.defaultTextFormat = new TextFormat("_sans", size, col, bold);
			t.autoSize   = TextFieldAutoSize.CENTER;
			t.selectable = false;
			t.width      = sw;
			t.x          = 0;
			return t;
		}

		var titleTF = makeTF(34, 0xFFFFFF, true);
		titleTF.text = "FNF: Psych Engine 0.4.2";
		titleTF.y    = sh * 0.19;
		addChild(titleTF);

		var subTF = makeTF(16, 0x777777);
		subTF.text = "Initializing...";
		subTF.y    = titleTF.y + 52;
		addChild(subTF);

		var barW:Float = sw * 0.68;
		var barH:Float = 20;
		var barX:Float = (sw - barW) / 2;
		var barY:Float = sh * 0.46;

		var barBg = new Shape();
		barBg.graphics.beginFill(0x111111);
		barBg.graphics.drawRoundRect(barX, barY, barW, barH, 10, 10);
		barBg.graphics.endFill();
		addChild(barBg);

		var barFill = new Shape();
		addChild(barFill);

		var pctTF = makeTF(13, 0x444444);
		pctTF.text = "";
		pctTF.y    = barY - 22;
		addChild(pctTF);

		var libTF = makeTF(17, 0xDDDDDD);
		libTF.text = "";
		libTF.y    = barY + barH + 14;
		addChild(libTF);

		var fileTF = makeTF(13, 0x555555);
		fileTF.text = "";
		fileTF.y    = libTF.y + 26;
		addChild(fileTF);

		var countTF = makeTF(13, 0x3A3A3A);
		countTF.text = "";
		countTF.y    = fileTF.y + 20;
		addChild(countTF);

		var statusTF = makeTF(15, 0x44CC66);
		statusTF.text    = "";
		statusTF.visible = false;
		statusTF.y       = sh * 0.74;
		addChild(statusTF);

		var mutex = new Mutex();
		var s = { pct: 0.0, lib: "", file: "", cur: 0, total: 0, status: "", err: "", done: false };

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
				s.status = '${Storage.extractedFiles} new files  ·  ${Storage.skippedFiles} unchanged';
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

		var prevPct:Float = 0;
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

			prevPct += (pct - prevPct) * 0.12;
			if (pct >= 1.0) prevPct = 1.0;

			try
			{
				barFill.graphics.clear();
				if (prevPct > 0)
				{
					var t:Float = prevPct;
					var r:Int   = Std.int(0x22 * (1 - t) + 0x00 * t);
					var g:Int   = Std.int(0x66 * (1 - t) + 0xDD * t);
					var b:Int   = Std.int(0xFF * (1 - t) + 0x66 * t);
					var hex:Int = (r << 16) | (g << 8) | b;
					barFill.graphics.beginFill(hex);
					barFill.graphics.drawRoundRect(barX, barY, barW * prevPct, barH, 10, 10);
					barFill.graphics.endFill();
				}
			}
			catch (_:Dynamic) {}

			try
			{
				var p = Std.int(prevPct * 100);
				pctTF.text   = total > 0 ? '$p%' : "";
				libTF.text   = lib;
				fileTF.text  = file.length > 60 ? '...${file.substr(file.length - 57)}' : file;
				countTF.text = total > 0 ? '$cur / $total files' : "";
			}
			catch (_:Dynamic) {}

			try
			{
				if (err.length > 0)
				{
					libTF.text       = "Error — continuing anyway";
					fileTF.text      = err.length > 72 ? err.substr(0, 72) + "…" : err;
					statusTF.text    = "Some files may be missing.";
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
					for (child in [barFill, barBg, countTF, fileTF, libTF, statusTF, pctTF, subTF, titleTF, bg])
						try { removeChild(child); } catch (_:Dynamic) {}
					finishSetup();
				}, 380);
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
			showCrashScreen("Failed to initialize game engine:\n" + Std.string(e));
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
	private function onStageResize(E:Event):Void
	{
		try { FlxG.resizeGame(stage.stageWidth, stage.stageHeight); }
		catch (_:Dynamic) {}
	}
	#end
}

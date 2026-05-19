package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.sound.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int    = 0;
	private static var curDifficulty:Int  = 1;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int      = 0;
	var lerpRating:Float   = 0;
	var intendedScore:Int  = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	#if mobile
	static inline final SWIPE_THRESHOLD:Float = 60;
	var _touchStartX:Float = 0;
	var _touchStartY:Float = 0;

	static inline final BTN_W:Float = 90;
	static inline final BTN_H:Float = 66;
	var _backBtnX:Float = 0;
	var _backBtnY:Float = 0;
	#end

	override function create()
	{
		try
		{
			#if MODS_ALLOWED
			Paths.destroyLoadedImages();
			#end
			WeekData.reloadWeekFiles(false);
		}
		catch (e:Dynamic) {}

		#if desktop
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length)
		{
			try
			{
				var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
				WeekData.setDirectoryFromWeek(leWeek);
				for (song in leWeek.songs)
				{
					var colors:Array<Int> = song[2];
					if (colors == null || colors.length < 3) colors = [146, 113, 253];
					addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				}
			}
			catch (e:Dynamic) {}
		}

		try { WeekData.setDirectoryFromWeek(); } catch (e:Dynamic) {}

		try
		{
			var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
			for (i in 0...initSonglist.length)
			{
				if (initSonglist[i] != null && initSonglist[i].length > 0)
				{
					var songArray:Array<String> = initSonglist[i].split(":");
					if (songArray.length >= 3)
						addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
				}
			}
		}
		catch (e:Dynamic) {}

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			try
			{
				var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
				songText.isMenuItem = true;
				songText.targetY    = i;
				grpSongs.add(songText);

				Paths.currentModDirectory = songs[i].folder;
				var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
				icon.sprTracker = songText;
				iconArray.push(icon);
				add(icon);
			}
			catch (e:Dynamic) {}
		}

		try { WeekData.setDirectoryFromWeek(); } catch (e:Dynamic) {}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);
		add(scoreText);

		if (songs.length > 0)
		{
			if (curSelected >= songs.length) curSelected = 0;
			bg.color      = songs[curSelected].color;
			intendedColor = bg.color;
			changeSelection();
			changeDiff();
		}

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to this Song / Press RESET to Reset your Score and Accuracy.";
		#else
		var leText:String = "Press RESET to Reset your Score and Accuracy.";
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, 18);
		text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		#if mobile
		_backBtnX = FlxG.width  - BTN_W - 10;
		_backBtnY = FlxG.height - BTN_H - 10;

		var backBtnBG:FlxSprite = new FlxSprite(_backBtnX, _backBtnY);
		backBtnBG.makeGraphic(Std.int(BTN_W), Std.int(BTN_H), 0x88000000);
		backBtnBG.scrollFactor.set();
		add(backBtnBG);

		var backBtnLabel:FlxText = new FlxText(_backBtnX, _backBtnY, BTN_W, "B", 36);
		backBtnLabel.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		backBtnLabel.scrollFactor.set();
		backBtnLabel.borderSize = 2;
		backBtnLabel.y += (BTN_H - backBtnLabel.height) / 2;
		add(backBtnLabel);
		#end

		super.create();
	}

	override function closeSubState()
	{
		changeSelection();
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	var instPlaying:Int = -1;
	private static var vocals:FlxSound = null;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		lerpScore  = Math.floor(FlxMath.lerp(lerpScore,  intendedScore,  CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore  - intendedScore)  <= 10)   lerpScore  = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + Math.floor(lerpRating * 100) + '%)';
		positionHighscore();

		if (songs.length == 0)
		{
			if (controls.BACK) MusicBeatState.switchState(new MainMenuState());
			super.update(elapsed);
			return;
		}

		var upP:Bool      = controls.UI_UP_P;
		var downP:Bool    = controls.UI_DOWN_P;
		var accepted:Bool = controls.ACCEPT;
		var back:Bool     = controls.BACK;
		var leftP:Bool    = controls.UI_LEFT_P;
		var rightP:Bool   = controls.UI_RIGHT_P;

		#if android
		if (FlxG.android.justReleased.BACK) back = true;
		#end

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				_touchStartX = touch.viewX;
				_touchStartY = touch.viewY;
			}

			if (touch.justReleased)
			{
				var dx:Float = touch.viewX - _touchStartX;
				var dy:Float = touch.viewY - _touchStartY;

				var onBackBtn:Bool =
					touch.viewX >= _backBtnX && touch.viewX <= _backBtnX + BTN_W &&
					touch.viewY >= _backBtnY && touch.viewY <= _backBtnY + BTN_H;

				if (onBackBtn)
				{
					back = true;
				}
				else if (Math.abs(dy) >= SWIPE_THRESHOLD && Math.abs(dy) > Math.abs(dx))
				{
					if (dy < 0) upP   = true;
					else         downP = true;
				}
				else if (Math.abs(dx) >= SWIPE_THRESHOLD && Math.abs(dx) > Math.abs(dy))
				{
					if (dx > 0) rightP = true;
					else         back   = true;
				}
				else
				{
					accepted = true;
				}
			}
		}
		#end

		var shiftMult:Int = 1;
		#if !mobile
		if (FlxG.keys.pressed.SHIFT) shiftMult = 3;
		#end

		if (upP)   changeSelection(-shiftMult);
		if (downP) changeSelection(shiftMult);

		if (leftP)  changeDiff(-1);
		if (rightP) changeDiff(1);

		if (back)
		{
			if (colorTween != null) colorTween.cancel();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		#if PRELOAD_ALL
		var space:Bool = FlxG.keys.justPressed.SPACE;
		if (space && instPlaying != curSelected)
		{
			try
			{
				destroyFreeplayVocals();
				Paths.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
				{
					var vf:Any = Paths.voices(PlayState.SONG.song);
					vocals = Std.isOfType(vf, openfl.media.Sound)
						? new FlxSound().loadEmbedded(cast(vf, openfl.media.Sound))
						: new FlxSound().loadEmbedded(openfl.Assets.getSound(cast(vf, String)));
				}
				else vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped  = true;
				vocals.volume  = 0.7;
				instPlaying = curSelected;
			}
			catch (e:Dynamic) {}
		}
		else
		#end
		if (accepted)
		{
			try
			{
				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

				#if MODS_ALLOWED
				if (!sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop)))
				#else
				if (!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop)))
				#end
				{
					poop = songLowercase;
					curDifficulty = 1;
				}

				PlayState.SONG            = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode     = false;
				PlayState.storyDifficulty = curDifficulty;
				PlayState.storyWeek       = songs[curSelected].week;

				if (colorTween != null) colorTween.cancel();
				LoadingState.loadAndSwitchState(new PlayState());

				FlxG.sound.music.volume = 0;
				destroyFreeplayVocals();
			}
			catch (e:Dynamic) {}
		}
		else if (controls.RESET)
		{
			try
			{
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			catch (e:Dynamic) {}
		}

		super.update(elapsed);
	}

	public static function destroyFreeplayVocals()
	{
		if (vocals != null)
		{
			try { vocals.stop(); vocals.destroy(); } catch (e:Dynamic) {}
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		if (songs.length == 0) return;

		curDifficulty += change;
		if (curDifficulty < 0)                               curDifficulty = CoolUtil.difficultyStuff.length - 1;
		if (curDifficulty >= CoolUtil.difficultyStuff.length) curDifficulty = 0;

		#if !switch
		try
		{
			intendedScore  = Highscore.getScore(songs[curSelected].songName, curDifficulty);
			intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		}
		catch (e:Dynamic) {}
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		positionHighscore();
	}

	function changeSelection(change:Int = 0)
	{
		if (songs.length == 0) return;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;
		if (curSelected < 0)            curSelected = songs.length - 1;
		if (curSelected >= songs.length) curSelected = 0;

		var newColor:Int = songs[curSelected].color;
		if (newColor != intendedColor)
		{
			if (colorTween != null) colorTween.cancel();
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) { colorTween = null; }
			});
		}

		#if !switch
		try
		{
			intendedScore  = Highscore.getScore(songs[curSelected].songName, curDifficulty);
			intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		}
		catch (e:Dynamic) {}
		#end

		for (i in 0...iconArray.length)
			iconArray[i].alpha = (i == curSelected) ? 1 : 0.6;

		var bullShit:Int = 0;
		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = (item.targetY == 0) ? 1 : 0.6;
		}

		changeDiff();
		try { Paths.currentModDirectory = songs[curSelected].folder; } catch (e:Dynamic) {}
	}

	private function positionHighscore()
	{
		scoreText.x     = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x       = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x      = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x     -= diffText.width / 2;
	}
}

class SongMetadata
{
	public var songName:String      = "";
	public var week:Int             = 0;
	public var songCharacter:String = "";
	public var color:Int            = -7179779;
	public var folder:String        = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName      = song;
		this.week          = week;
		this.songCharacter = songCharacter;
		this.color         = color;
		this.folder        = Paths.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}
}

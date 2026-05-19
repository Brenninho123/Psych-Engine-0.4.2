package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import WeekData;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;

	private static var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;

	private static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficultyGroup:FlxTypedGroup<FlxSprite>;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

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
			WeekData.reloadWeekFiles(true);
			if (curWeek >= WeekData.weeksList.length) curWeek = 0;
		}
		catch (e:Dynamic) { curWeek = 0; }

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex    = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = ClientPrefs.globalAntialiasing;

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		grpLocks          = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		#if desktop
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length)
		{
			try
			{
				WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, WeekData.weeksList[i]);
				weekThing.y += ((weekThing.height + 20) * i);
				weekThing.targetY = i;
				grpWeekText.add(weekThing);
				weekThing.screenCenter(X);
				weekThing.antialiasing = ClientPrefs.globalAntialiasing;

				if (weekIsLocked(i))
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = i;
					lock.antialiasing = ClientPrefs.globalAntialiasing;
					grpLocks.add(lock);
				}
			}
			catch (e:Dynamic) {}
		}

		try
		{
			WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[0]));
			var charArray:Array<String> = WeekData.weeksLoaded.get(WeekData.weeksList[0]).weekCharacters;
			for (char in 0...3)
			{
				var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
				weekCharacterThing.y += 70;
				grpWeekCharacters.add(weekCharacterThing);
			}
		}
		catch (e:Dynamic) {}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(leftArrow);

		sprDifficultyGroup = new FlxTypedGroup<FlxSprite>();
		add(sprDifficultyGroup);

		for (i in 0...CoolUtil.difficultyStuff.length)
		{
			try
			{
				var sprDifficulty:FlxSprite = new FlxSprite(leftArrow.x + 60, leftArrow.y)
					.loadGraphic(Paths.image('menudifficulties/' + CoolUtil.difficultyStuff[i][0].toLowerCase()));
				sprDifficulty.x  += (308 - sprDifficulty.width) / 2;
				sprDifficulty.ID  = i;
				sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
				sprDifficultyGroup.add(sprDifficulty);
			}
			catch (e:Dynamic) {}
		}
		changeDifficulty();

		difficultySelectors.add(sprDifficultyGroup);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(rightArrow);

		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 425)
			.loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.globalAntialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font  = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);

		add(scoreText);
		add(txtWeekTitle);

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

		changeWeek();
		super.create();
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
		scoreText.text = "WEEK SCORE:" + lerpScore;

		difficultySelectors.visible = !weekIsLocked(curWeek);

		if (!movedBack && !selectedWeek)
		{
			var _up:Bool     = controls.UI_UP_P;
			var _down:Bool   = controls.UI_DOWN_P;
			var _left:Bool   = controls.UI_LEFT_P;
			var _right:Bool  = controls.UI_RIGHT_P;
			var _accept:Bool = controls.ACCEPT;
			var _back:Bool   = controls.BACK;

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
						_back = true;
					}
					else if (Math.abs(dy) >= SWIPE_THRESHOLD && Math.abs(dy) > Math.abs(dx))
					{
						if (dy < 0) _up   = true;
						else         _down = true;
					}
					else if (Math.abs(dx) >= SWIPE_THRESHOLD && Math.abs(dx) > Math.abs(dy))
					{
						if (dx > 0) _right = true;
						else         _back  = true;
					}
					else
					{
						_back   = false;
						_accept = true;
					}
				}
			}
			#if android
			if (FlxG.android.justReleased.BACK) _back = true;
			#end
			#end

			if (_up)   { changeWeek(-1); FlxG.sound.play(Paths.sound('scrollMenu')); }
			if (_down) { changeWeek(1);  FlxG.sound.play(Paths.sound('scrollMenu')); }

			if (controls.UI_RIGHT) rightArrow.animation.play('press'); else rightArrow.animation.play('idle');
			if (controls.UI_LEFT)  leftArrow.animation.play('press');  else leftArrow.animation.play('idle');

			if (_right) changeDifficulty(1);
			if (_left)  changeDifficulty(-1);

			if (_accept) selectWeek();
			else if (controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (_back)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		super.update(elapsed);

		grpLocks.forEach(function(lock:FlxSprite)
		{
			if (lock != null && lock.ID < grpWeekText.members.length && grpWeekText.members[lock.ID] != null)
				lock.y = grpWeekText.members[lock.ID].y;
		});
	}

	var movedBack:Bool    = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (weekIsLocked(curWeek)) { FlxG.sound.play(Paths.sound('cancelMenu')); return; }

		try
		{
			if (!stopspamming)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				grpWeekText.members[curWeek].startFlashing();
				if (grpWeekCharacters.members[1] != null && grpWeekCharacters.members[1].character != '')
					grpWeekCharacters.members[1].animation.play('confirm');
				stopspamming = true;
			}

			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic>   = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).songs;
			for (i in 0...leWeek.length) songArray.push(leWeek[i][0]);

			PlayState.storyPlaylist   = songArray;
			PlayState.isStoryMode     = true;
			selectedWeek              = true;

			var diffic = CoolUtil.difficultyStuff[curDifficulty][1];
			if (diffic == null) diffic = '';

			PlayState.storyDifficulty = curDifficulty;
			PlayState.SONG            = Song.loadFromJson(
				PlayState.storyPlaylist[0].toLowerCase() + diffic,
				PlayState.storyPlaylist[0].toLowerCase()
			);
			PlayState.storyWeek      = curWeek;
			PlayState.campaignScore  = 0;
			PlayState.campaignMisses = 0;

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});
		}
		catch (e:Dynamic)
		{
			stopspamming = false;
			selectedWeek = false;
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;
		if (curDifficulty < 0)                               curDifficulty = CoolUtil.difficultyStuff.length - 1;
		if (curDifficulty >= CoolUtil.difficultyStuff.length) curDifficulty = 0;

		sprDifficultyGroup.forEach(function(spr:FlxSprite)
		{
			spr.visible = false;
			if (curDifficulty == spr.ID)
			{
				spr.visible = true;
				spr.alpha   = 0;
				spr.y       = leftArrow.y - 15;
				FlxTween.tween(spr, {y: leftArrow.y + 15, alpha: 1}, 0.07);
			}
		});

		#if !switch
		try { intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], curDifficulty); }
		catch (e:Dynamic) {}
		#end
	}

	var lerpScore:Int     = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;
		if (curWeek >= WeekData.weeksList.length) curWeek = 0;
		if (curWeek < 0)                          curWeek = WeekData.weeksList.length - 1;

		try
		{
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);
			WeekData.setDirectoryFromWeek(leWeek);

			txtWeekTitle.text = leWeek.storyName.toUpperCase();
			txtWeekTitle.x    = FlxG.width - (txtWeekTitle.width + 10);

			var bullShit:Int = 0;
			for (item in grpWeekText.members)
			{
				item.targetY = bullShit - curWeek;
				item.alpha   = (item.targetY == 0 && !weekIsLocked(curWeek)) ? 1 : 0.6;
				bullShit++;
			}

			bgSprite.visible = true;
			var assetName:String = leWeek.weekBackground;
			if (assetName == null || assetName.length < 1)
			{
				bgSprite.visible = false;
			}
			else
			{
				try { bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName)); }
				catch (e:Dynamic) { bgSprite.visible = false; }
			}

			updateText();
		}
		catch (e:Dynamic) {}
	}

	function weekIsLocked(weekNum:Int):Bool
	{
		try
		{
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[weekNum]);
			if (leWeek == null) return false;
			return !leWeek.startUnlocked
				&& leWeek.weekBefore.length > 0
				&& (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore));
		}
		catch (e:Dynamic) {}
		return false;
	}

	function updateText()
	{
		try
		{
			var weekArray:Array<String> = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).weekCharacters;
			for (i in 0...grpWeekCharacters.length)
			{
				if (i < weekArray.length && grpWeekCharacters.members[i] != null)
					grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
			}

			var leWeek:WeekData         = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);
			var stringThing:Array<String> = [];
			for (i in 0...leWeek.songs.length) stringThing.push(leWeek.songs[i][0]);

			txtTracklist.text = stringThing.join('\n').toUpperCase();
			txtTracklist.screenCenter(X);
			txtTracklist.x -= FlxG.width * 0.35;

			#if !switch
			intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], curDifficulty);
			#end
		}
		catch (e:Dynamic) {}
	}
}

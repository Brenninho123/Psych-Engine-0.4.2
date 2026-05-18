package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import Achievements;

using StringTools;

class AchievementsMenuState extends MusicBeatState
{
	var options:Array<String> = [];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	private var achievementArray:Array<AttachedAchievement> = [];
	private var achievementIndex:Array<Int> = [];
	private var descText:FlxText;

	#if mobile
	static inline final SWIPE_THRESHOLD:Float = 60;
	var _touchStartX:Float = 0;
	var _touchStartY:Float = 0;

	var _backBtnX:Float = 0;
	var _backBtnY:Float = 0;
	var _backBtnW:Float = 100;
	var _backBtnH:Float = 80;
	#end

	override function create()
	{
		#if desktop
		DiscordClient.changePresence("Achievements Menu", null);
		#end

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = ClientPrefs.globalAntialiasing;
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...Achievements.achievementsStuff.length)
		{
			if (!Achievements.achievementsStuff[i][2] || Achievements.achievementsUnlocked[i][1])
			{
				options.push(Achievements.achievementsStuff[i]);
				achievementIndex.push(i);
			}
		}

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, (100 * i) + 210,
				Achievements.achievementsUnlocked[achievementIndex[i]][1]
					? Achievements.achievementsStuff[achievementIndex[i]][0]
					: '?',
				false, false);
			optionText.isMenuItem = true;
			optionText.x    += 280;
			optionText.xAdd  = 200;
			optionText.targetY = i;
			grpOptions.add(optionText);

			var icon:AttachedAchievement = new AttachedAchievement(optionText.x - 105, optionText.y, achievementIndex[i]);
			icon.sprTracker = optionText;
			achievementArray.push(icon);
			add(icon);
		}

		descText = new FlxText(150, 600, 980, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		#if mobile
		var backBtnBG:FlxSprite = new FlxSprite(FlxG.width - _backBtnW - 10, FlxG.height - _backBtnH - 10);
		backBtnBG.makeGraphic(Std.int(_backBtnW), Std.int(_backBtnH), 0x88000000);
		backBtnBG.scrollFactor.set();
		add(backBtnBG);
		_backBtnX = backBtnBG.x;
		_backBtnY = backBtnBG.y;

		var backBtnLabel:FlxText = new FlxText(_backBtnX, _backBtnY, _backBtnW, "B", 36);
		backBtnLabel.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		backBtnLabel.scrollFactor.set();
		backBtnLabel.borderSize = 2;
		backBtnLabel.y += (_backBtnH - backBtnLabel.height) / 2;
		add(backBtnLabel);
		#end

		changeSelection();

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var _up:Bool   = controls.UI_UP_P;
		var _down:Bool = controls.UI_DOWN_P;
		var _back:Bool = controls.BACK;

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
					touch.viewX >= _backBtnX && touch.viewX <= _backBtnX + _backBtnW &&
					touch.viewY >= _backBtnY && touch.viewY <= _backBtnY + _backBtnH;

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
					if (dx < 0) _back = true;
				}
			}
		}

		#if android
		if (FlxG.android.justReleased.BACK) _back = true;
		#end
		#end

		if (_up)   changeSelection(-1);
		if (_down) changeSelection(1);

		if (_back)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)                curSelected = options.length - 1;
		if (curSelected >= options.length)  curSelected = 0;

		var bullShit:Int = 0;
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = (item.targetY == 0) ? 1 : 0.6;
		}

		for (i in 0...achievementArray.length)
			achievementArray[i].alpha = (i == curSelected) ? 1 : 0.6;

		descText.text = Achievements.achievementsStuff[achievementIndex[curSelected]][1];
	}
}

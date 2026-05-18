package;

#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
#if sys
import sys.FileSystem;
#end
#if mobile
import mobile.Hitbox;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2],
		['Shit', 0.4],
		['Bad', 0.5],
		['Bruh', 0.6],
		['Meh', 0.69],
		['Nice', 0.7],
		['Good', 0.8],
		['Great', 0.9],
		['Sick!', 1],
		['Perfect!!', 1]
	];

	#if (haxe >= "4.0.0")
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	#else
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, Dynamic>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	#end

	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;

	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;
	private static var resetSpriteCache:Bool = false;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = false;
	public static var practiceMode:Bool = false;
	public static var usedPractice:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var cpuControlled:Bool = false;

	var botplaySine:Float = 0;
	var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:ModchartSprite;
	var blammedLightsBlackTween:FlxTween;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;
	var trainSound:FlxSound;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var ghostMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;
	var songLength:Float = 0;

	#if desktop
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	private var luaArray:Array<FunkinLua> = [];

	var keysPressed:Array<Bool> = [false, false, false, false];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	#if mobile
	var hitbox:Hitbox;
	#end

	override public function create()
	{
		#if MODS_ALLOWED
		Paths.destroyLoadedImages(resetSpriteCache);
		#end
		resetSpriteCache = false;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		practiceMode = false;

		camGame  = new FlxCamera();
		camHUD   = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha   = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw   = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = '' + CoolUtil.difficultyStuff[storyDifficulty][0];
		detailsText = isStoryMode ? "Story Mode: " + WeekData.getCurrentWeek().weekName : "Freeplay";
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = PlayState.SONG.stage;

		if (PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1)
		{
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':      curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice': curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':     curStage = 'limo';
				case 'cocoa' | 'eggnog':                     curStage = 'mall';
				case 'winter-horrorland':                    curStage = 'mallEvil';
				case 'senpai' | 'roses':                     curStage = 'school';
				case 'thorns':                               curStage = 'schoolEvil';
				default:                                     curStage = 'stage';
			}
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100]
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage   = stageData.isPixelStage;
		BF_X  = stageData.boyfriend[0];
		BF_Y  = stageData.boyfriend[1];
		GF_X  = stageData.girlfriend[0];
		GF_Y  = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup       = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup        = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage':
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);

					var stageLight2:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight2.setGraphicSize(Std.int(stageLight2.width * 1.1));
					stageLight2.updateHitbox();
					stageLight2.flipX = true;
					add(stageLight2);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'spooky':
				if (!ClientPrefs.lowQuality)
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				else
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				CoolUtil.precacheSound('thunder_1');
				CoolUtil.precacheSound('thunder_2');

			case 'philly':
				if (!ClientPrefs.lowQuality)
				{
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyCityLights = new FlxTypedGroup<BGSprite>();
				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:BGSprite = new BGSprite('philly/win' + i, city.x, city.y, 0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					phillyCityLights.add(light);
				}

				if (!ClientPrefs.lowQuality)
				{
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(openfl.Assets.getSound(Paths.sound('train_passes')));
				CoolUtil.precacheSound('train_passes');
				FlxG.sound.list.add(trainSound);

				var street:BGSprite = new BGSprite('philly/street', -40, 50);
				add(street);

			case 'limo':
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if (!ClientPrefs.lowQuality)
				{
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					CoolUtil.precacheSound('dancerdeath');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall':
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if (!ClientPrefs.lowQuality)
				{
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				CoolUtil.precacheSound('Lights_Shut_off');

			case 'mallEvil':
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school':
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName  = 'gameOver-pixel';
				GameOverSubstate.endSoundName   = 'gameOverEnd-pixel';
				GameOverSubstate.characterName  = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if (!ClientPrefs.lowQuality)
				{
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if (!ClientPrefs.lowQuality)
				{
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if (!ClientPrefs.lowQuality)
				{
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);
					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil':
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName  = 'gameOver-pixel';
				GameOverSubstate.endSoundName   = 'gameOverEnd-pixel';
				GameOverSubstate.characterName  = 'bf-pixel-dead';

				var posX = 400;
				var posY = 200;
				if (!ClientPrefs.lowQuality)
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				}
				else
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}
		}

		if (isPixelStage)
			introSoundsSuffix = '-pixel';

		add(gfGroup);

		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(boyfriendGroup);

		if (curStage == 'spooky')
			add(halloweenWhite);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush  = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
				doPush = true;
		}

		if (curStage == 'philly')
		{
			phillyCityLightsEvent = new FlxTypedGroup<BGSprite>();
			for (i in 0...5)
			{
				var light:BGSprite = new BGSprite('philly/win' + i, -10, 0, 0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				phillyCityLightsEvent.add(light);
			}
		}

		if (doPush)
			luaArray.push(new FunkinLua(luaFile));

		if (!modchartSprites.exists('blammedLightsBlack'))
		{
			blammedLightsBlack = new ModchartSprite(FlxG.width * -0.5, FlxG.height * -0.5);
			blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
			var position:Int = members.indexOf(gfGroup);
			if (members.indexOf(boyfriendGroup) < position)
				position = members.indexOf(boyfriendGroup);
			else if (members.indexOf(dadGroup) < position)
				position = members.indexOf(dadGroup);
			insert(position, blammedLightsBlack);

			blammedLightsBlack.wasAdded = true;
			modchartSprites.set('blammedLightsBlack', blammedLightsBlack);
		}
		if (curStage == 'philly') insert(members.indexOf(blammedLightsBlack) + 1, phillyCityLightsEvent);
		blammedLightsBlack       = modchartSprites.get('blammedLightsBlack');
		blammedLightsBlack.alpha = 0.0;
		#end

		var gfVersion:String = SONG.player3;
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':                 gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':   gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil': gfVersion = 'gf-pixel';
				default:                     gfVersion = 'gf';
			}
			SONG.player3 = gfVersion;
		}

		gf = new Character(0, 0, gfVersion);
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			gf.visible = false;
		}

		switch (curStage)
		{
			case 'limo':
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				insert(members.indexOf(dadGroup) - 1, evilTrail);
		}

		var file:String = Paths.json(songName + '/dialogue');
		if (OpenFlAssets.exists(file))
			dialogueJson = DialogueBoxPsych.parseDialogue(file);

		var file2:String = Paths.txt(songName + '/' + songName + 'Dialogue');
		if (OpenFlAssets.exists(file2))
			dialogue = CoolUtil.coolTextFile(file2);

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		doof.scrollFactor.set();
		doof.finishThing       = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 20, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha      = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible    = !ClientPrefs.hideTime;
		if (ClientPrefs.downScroll) timeTxt.y = FlxG.height - 45;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha   = 0;
		timeBarBG.visible = !ClientPrefs.hideTime;
		timeBarBG.color   = FlxColor.BLACK;
		timeBarBG.xAdd    = -4;
		timeBarBG.yAdd    = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this, 'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800;
		timeBar.alpha        = 0;
		timeBar.visible      = !ClientPrefs.hideTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums   = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if (FileSystem.exists(luaToLoad))
				luaArray.push(new FunkinLua(luaToLoad));
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if (FileSystem.exists(luaToLoad))
				luaArray.push(new FunkinLua(luaToLoad));
		}
		#end

		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		camFollow    = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow    = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos    = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd    = -4;
		healthBarBG.yAdd    = -4;
		add(healthBarBG);
		if (ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this, 'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y       = healthBar.y - (iconP1.height / 2);
		iconP1.visible = !ClientPrefs.hideHud;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y       = healthBar.y - (iconP2.height / 2);
		iconP2.visible = !ClientPrefs.hideHud;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible    = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible    = cpuControlled;
		add(botplayTxt);
		if (ClientPrefs.downScroll)
			botplayTxt.y = timeBarBG.y - 78;

		strumLineNotes.cameras  = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras           = [camHUD];
		healthBar.cameras       = [camHUD];
		healthBarBG.cameras     = [camHUD];
		iconP1.cameras          = [camHUD];
		iconP2.cameras          = [camHUD];
		scoreTxt.cameras        = [camHUD];
		botplayTxt.cameras      = [camHUD];
		timeBar.cameras         = [camHUD];
		timeBarBG.cameras       = [camHUD];
		timeTxt.cameras         = [camHUD];
		doof.cameras            = [camHUD];

		startingSong = true;
		updateTime   = true;

		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush2:Bool = false;
		var luaFile2:String = 'data/' + Paths.formatToSongPath(SONG.song) + '/script.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile2)))
		{
			luaFile2 = Paths.modFolders(luaFile2);
			doPush2  = true;
		}
		else
		{
			luaFile2 = Paths.getPreloadPath(luaFile2);
			if (FileSystem.exists(luaFile2))
				doPush2 = true;
		}
		if (doPush2)
			luaArray.push(new FunkinLua(luaFile2));
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend   = ADD;
					camHUD.visible      = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene     = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) { remove(blackScreen); }
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) { startCountdown(); }
						});
					});

				case 'senpai' | 'roses' | 'thorns':
					if (daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}

		RecalculateRating();

		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		#if desktop
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		#if mobile
		hitbox = new Hitbox();
		hitbox.cameras = [camHUD];
		add(hitbox);
		#end

		super.create();
	}

	public function addTextToDebug(text:String)
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) { spr.y += 20; });
		luaDebugGroup.add(new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors()
	{
		healthBar.createFilledBar(
			FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2])
		);
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha         = 0.00001;
					newBoyfriend.alreadyLoaded = false;
				}
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha         = 0.00001;
					newDad.alreadyLoaded = false;
				}
			case 2:
				if (!gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha         = 0.00001;
					newGf.alreadyLoaded = false;
				}
		}
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void
	{
		#if VIDEOS_ALLOWED
		var foundFile:Bool  = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if (FileSystem.exists(fileName)) foundFile = true;
		#end

		if (!foundFile)
		{
			fileName = Paths.video(name);
			#if sys
			if (FileSystem.exists(fileName))
			#else
			if (OpenFlAssets.exists(fileName))
			#end
				foundFile = true;
		}

		if (foundFile)
		{
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function()
			{
				remove(bg);
				if (endingSong) endSong(); else startCountdown();
			};
			return;
		}
		#end
		if (endingSong) endSong(); else startCountdown();
	}

	var dialogueCount:Int = 0;

	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
			doof.scrollFactor.set();
			doof.finishThing       = endingSong ? endSong : startCountdown;
			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;
			doof.cameras           = [camHUD];
			add(doof);
		}
		else
		{
			if (endingSong) endSong(); else startCountdown();
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var sName:String = Paths.formatToSongPath(SONG.song);
		if (sName == 'roses' || sName == 'thorns')
		{
			remove(black);
			if (sName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;
			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
				{
					startCountdown();
				}
				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;
	public var countDownSprites:Array<FlxSprite> = [];

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if (ret != FunkinLua.Function_Stop)
		{
			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length)
			{
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length)
			{
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				if (ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown     = true;
			Conductor.songPosition  = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);

			var swagCounter:Int = 0;

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (tmr.loopsLeft % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
					gf.dance();

				if (tmr.loopsLeft % 2 == 0)
				{
					if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
						boyfriend.dance();
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
						dad.dance();
				}
				else if (dad.danceIdle && dad.animation.curAnim != null && !dad.stunned && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing"))
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel',   ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if (isPixelStage)
				{
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				if (curStage == 'mall')
				{
					if (!ClientPrefs.lowQuality) upperBoppers.dance(true);
					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						ready.scrollFactor.set();
						ready.updateHitbox();
						if (PlayState.isPixelStage) ready.setGraphicSize(Std.int(ready.width * daPixelZoom));
						ready.screenCenter();
						ready.antialiasing = antialias;
						add(ready);
						countDownSprites.push(ready);
						FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(ready);
								remove(ready);
								ready.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						set.scrollFactor.set();
						if (PlayState.isPixelStage) set.setGraphicSize(Std.int(set.width * daPixelZoom));
						set.screenCenter();
						set.antialiasing = antialias;
						add(set);
						countDownSprites.push(set);
						FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(set);
								remove(set);
								set.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						go.scrollFactor.set();
						if (PlayState.isPixelStage) go.setGraphicSize(Std.int(go.width * daPixelZoom));
						go.updateHitbox();
						go.screenCenter();
						go.antialiasing = antialias;
						add(go);
						countDownSprites.push(go);
						FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(go);
								remove(go);
								go.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
				}

				notes.forEachAlive(function(note:Note)
				{
					note.copyAlpha = false;
					note.alpha = 1 * note.multAlpha;
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				if (generatedMusic)
					notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

				swagCounter += 1;
			}, 5);
		}
	}

	function startNextDialogue() { dialogueCount++; callOnLuas('onNextDialogue', [dialogueCount]); }
	function skipDialogue()      { callOnLuas('onSkipDialogue', [dialogueCount]); }

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;
		previousFrameTime         = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool>  = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		curSong = songData.song;

		if (SONG.needsVoices)
		{
			var vf:Any = Paths.voices(PlayState.SONG.song);
			vocals = Std.isOfType(vf, openfl.media.Sound)
				? new FlxSound().loadEmbedded(cast(vf, openfl.media.Sound))
				: new FlxSound().loadEmbedded(openfl.Assets.getSound(cast(vf, String)));
		}
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		var iFile:Any    = Paths.inst(PlayState.SONG.song);
		var iSound:openfl.media.Sound = Std.isOfType(iFile, openfl.media.Sound)
			? cast(iFile, openfl.media.Sound)
			: openfl.Assets.getSound(cast(iFile, String));
		FlxG.sound.list.add(new FlxSound().loadEmbedded(iSound));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection> = songData.notes;
		var playerCounter:Int = 0;
		var daBeats:Int = 0;

		var sName:String = Paths.formatToSongPath(SONG.song);
		var evFile:String = Paths.json(sName + '/events');
		#if (sys && MODS_ALLOWED)
		if (FileSystem.exists(Paths.modsJson(sName + '/events')) || FileSystem.exists(evFile))
		{
		#elseif sys
		if (FileSystem.exists(evFile))
		{
		#else
		if (OpenFlAssets.exists(evFile))
		{
		#end
			var eventsData:Array<SwagSection> = Song.loadFromJson('events', sName).notes;
			for (section in eventsData)
			{
				for (songNotes in section.sectionNotes)
				{
					if (songNotes[1] < 0)
					{
						eventNotes.push([songNotes[0], songNotes[1], songNotes[2], songNotes[3], songNotes[4]]);
						eventPushed(songNotes);
					}
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if (songNotes[1] > -1)
				{
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int    = Std.int(songNotes[1] % 4);
					var gottaHitNote:Bool = section.mustHitSection;
					if (songNotes[1] > 3) gottaHitNote = !section.mustHitSection;

					var oldNote:Note = unspawnNotes.length > 0 ? unspawnNotes[Std.int(unspawnNotes.length - 1)] : null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress    = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.noteType     = songNotes[3];
					if (!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]];
					swagNote.scrollFactor.set();

					var susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					var floorSus:Int = Math.floor(susLength);
					if (floorSus > 0)
					{
						for (susNote in 0...floorSus + 1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(SONG.speed, 2)), daNoteData, oldNote, true);
							sustainNote.mustPress  = gottaHitNote;
							sustainNote.noteType   = swagNote.noteType;
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);
							if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2;
						}
					}

					if (swagNote.mustPress) swagNote.x += FlxG.width / 2;

					if (!noteTypeMap.exists(swagNote.noteType))
						noteTypeMap.set(swagNote.noteType, true);
				}
				else
				{
					eventNotes.push([songNotes[0], songNotes[1], songNotes[2], songNotes[3], songNotes[4]]);
					eventPushed(songNotes);
				}
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1)
			eventNotes.sort(sortByTime);

		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>)
	{
		switch (event[2])
		{
			case 'Change Character':
				var charType:Int = 0;
				switch (event[3].toLowerCase())
				{
					case 'gf' | 'girlfriend': charType = 2;
					case 'dad' | 'opponent':  charType = 1;
					default:
						charType = Std.parseInt(event[3]);
						if (Math.isNaN(charType)) charType = 0;
				}
				addCharacterToList(event[4], charType);
		}
		if (!eventPushedMap.exists(event[2]))
			eventPushedMap.set(event[2], true);
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float
	{
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event[2]]);
		if (returnedValue != 0) return returnedValue;
		switch (event[2])
		{
			case 'Kill Henchmen': return 280;
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0] - eventNoteEarlyTrigger(Obj1), Obj2[0] - eventNoteEarlyTrigger(Obj2));
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			if (!isStoryMode)
			{
				babyArrow.y     -= 10;
				babyArrow.alpha  = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			if (player == 1) playerStrums.add(babyArrow); else opponentStrums.add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished) startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished) finishTimer.active = false;

			if (blammedLightsBlackTween != null)   blammedLightsBlackTween.active   = false;
			if (phillyCityLightsEventTween != null) phillyCityLightsEventTween.active = false;
			if (carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length)
			{
				if (chars[i].colorTween != null)
					chars[i].colorTween.active = false;
			}
			for (tween in modchartTweens) tween.active = false;
			for (timer in modchartTimers) timer.active = false;
		}
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong) resyncVocals();

			if (!startTimer.finished) startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished) finishTimer.active = true;

			if (blammedLightsBlackTween != null)   blammedLightsBlackTween.active   = true;
			if (phillyCityLightsEventTween != null) phillyCityLightsEventTween.active = true;
			if (carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length)
			{
				if (chars[i].colorTween != null)
					chars[i].colorTween.active = true;
			}
			for (tween in modchartTweens) tween.active = true;
			for (timer in modchartTimers) timer.active = true;

			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			#end
		}
		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (finishTimer != null) return;
		vocals.pause();
		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'schoolEvil':
				if (!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished)
					bgGhouls.visible = false;
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;
					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
			case 'limo':
				if (!ClientPrefs.lowQuality)
				{
					grpLimoParticles.forEach(function(spr:BGSprite)
					{
						if (spr.animation.curAnim.finished)
						{
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch (limoKillingState)
					{
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x      = limoMetalPole.x - 180;
							limoCorpse.x     = limoLight.x - 50;
							limoCorpseTwo.x  = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length)
							{
								if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130)
								{
									switch (i)
									{
										case 0 | 3:
											if (i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);
											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var p1:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(p1);
											var p2:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(p2);
											var p3:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(p3);
											var p4:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											p4.flipX = true;
											p4.angle  = -57.5;
											grpLimoParticles.add(p4);
										case 1: limoCorpse.visible    = true;
										case 2: limoCorpseTwo.visible  = true;
									}
									dancers[i].x += FlxG.width * 2;
								}
							}
							if (limoMetalPole.x > FlxG.width * 2)
							{
								resetLimoKill();
								limoSpeed       = 800;
								limoKillingState = 2;
							}
						case 2:
							limoSpeed  -= 4000 * elapsed;
							bgLimo.x   -= limoSpeed * elapsed;
							if (bgLimo.x > FlxG.width * 1.5)
							{
								limoSpeed       = 3000;
								limoKillingState = 3;
							}
						case 3:
							limoSpeed -= 2000 * elapsed;
							if (limoSpeed < 1000) limoSpeed = 1000;
							bgLimo.x -= limoSpeed * elapsed;
							if (bgLimo.x < -275)
							{
								limoKillingState = 4;
								limoSpeed        = 800;
							}
						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if (Math.round(bgLimo.x) == -150)
							{
								bgLimo.x        = -150;
								limoKillingState = 0;
							}
					}

					if (limoKillingState > 2)
					{
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length)
							dancers[i].x = (370 * i) + bgLimo.x + 280;
					}
				}
			case 'mall':
				if (heyTimer > 0)
				{
					heyTimer -= elapsed;
					if (heyTimer <= 0)
					{
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if (!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15) boyfriendIdled = true;
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if (ratingString == '?')
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingString;
		else
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingString + ' (' + Math.floor(ratingPercent * 100) + '%)';

		if (cpuControlled)
		{
			botplaySine    += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
		botplayTxt.visible = cpuControlled;

		var pausePressed:Bool = FlxG.keys.justPressed.ENTER;
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed && touch.viewY < 50)
			{
				pausePressed = true;
				break;
			}
		}
		#end

		if (pausePressed && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if (ret != FunkinLua.Function_Stop)
			{
				persistentUpdate = false;
				persistentDraw   = true;
				paused           = true;

				if (FlxG.random.bool(0.1))
				{
					cancelFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					MusicBeatState.switchState(new GitarooPause());
				}
				else
				{
					if (FlxG.sound.music != null)
					{
						FlxG.sound.music.pause();
						vocals.pause();
					}
					PauseSubState.transCamera = camOther;
					openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				}

				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		#if !mobile
		if (FlxG.keys.justPressed.SEVEN && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused           = true;
			cancelFadeTween();
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new ChartingState());
			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		if (FlxG.keys.justPressed.EIGHT && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused           = true;
			cancelFadeTween();
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}
		#end

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, CoolUtil.boundTo(1 - (elapsed * 30), 0, 1))));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, CoolUtil.boundTo(1 - (elapsed * 30), 0, 1))));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;
		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2) health = 2;

		iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0;
		iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0;

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0) startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime         += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime               = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos  = Conductor.songPosition;
				}

				if (updateTime)
				{
					var curTime:Float = FlxG.sound.music.time - ClientPrefs.noteOffset;
					if (curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var secondsTotal:Int = Math.floor((songLength - curTime) / 1000);
					if (secondsTotal < 0) secondsTotal = 0;

					var minutesRemaining:Int = Math.floor(secondsTotal / 60);
					var secondsRemaining:String = '' + secondsTotal % 60;
					if (secondsRemaining.length < 2) secondsRemaining = '0' + secondsRemaining;
					timeTxt.text = minutesRemaining + ':' + secondsRemaining;
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom      = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			doDeathCheck();
		}
		doDeathCheck();

		var roundedSpeed:Float = FlxMath.roundDecimal(SONG.speed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if (roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				if (!daNote.mustPress && ClientPrefs.middleScroll)
				{
					daNote.active  = true;
					daNote.visible = false;
				}
				else if (daNote.y > FlxG.height)
				{
					daNote.active  = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active  = true;
				}

				var strumX:Float = 0, strumY:Float = 0, strumAngle:Float = 0, strumAlpha:Float = 0;
				if (daNote.mustPress)
				{
					strumX     = playerStrums.members[daNote.noteData].x;
					strumY     = playerStrums.members[daNote.noteData].y;
					strumAngle = playerStrums.members[daNote.noteData].angle;
					strumAlpha = playerStrums.members[daNote.noteData].alpha;
				}
				else
				{
					strumX     = opponentStrums.members[daNote.noteData].x;
					strumY     = opponentStrums.members[daNote.noteData].y;
					strumAngle = opponentStrums.members[daNote.noteData].angle;
					strumAlpha = opponentStrums.members[daNote.noteData].alpha;
				}

				strumX     += daNote.offsetX;
				strumY     += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;
				var center:Float = strumY + Note.swagWidth / 2;

				if (daNote.copyX)     daNote.x     = strumX;
				if (daNote.copyAngle) daNote.angle  = strumAngle;
				if (daNote.copyAlpha) daNote.alpha  = strumAlpha;

				if (daNote.copyY)
				{
					if (ClientPrefs.downScroll)
					{
						daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (daNote.isSustainNote)
						{
							if (daNote.animation.curAnim.name.endsWith('end'))
							{
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
								if (PlayState.isPixelStage) daNote.y += 8; else daNote.y -= 19;
							}
							daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1);

							if (daNote.mustPress || !daNote.ignoreNote)
							{
								if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
								&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y      = daNote.frameHeight - swagRect.height;
									daNote.clipRect = swagRect;
								}
							}
						}
					}
					else
					{
						daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (daNote.mustPress || !daNote.ignoreNote)
						{
							if (daNote.isSustainNote && daNote.y + daNote.offset.y * daNote.scale.y <= center
							&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y      = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;
								daNote.clipRect  = swagRect;
							}
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					if (Paths.formatToSongPath(SONG.song) != 'tutorial') camZooming = true;

					if (daNote.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
					{
						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer    = 0.6;
					}
					else if (!daNote.noAnimation)
					{
						var altAnim:String = '';
						if (SONG.notes[Math.floor(curStep / 16)] != null)
						{
							if (SONG.notes[Math.floor(curStep / 16)].altAnim || daNote.noteType == 'Alt Animation')
								altAnim = '-alt';
						}
						var animToPlay:String = switch (Math.abs(daNote.noteData))
						{
							case 0: 'singLEFT';
							case 1: 'singDOWN';
							case 2: 'singUP';
							case 3: 'singRIGHT';
							default: '';
						};
						if (daNote.noteType == 'GF Sing') { gf.playAnim(animToPlay + altAnim, true); gf.holdTimer = 0; }
						else                               { dad.playAnim(animToPlay + altAnim, true); dad.holdTimer = 0; }
					}

					if (SONG.needsVoices) vocals.volume = 1;

					var time:Float = 0.15;
					if (daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) time += 0.15;
					StrumPlayAnim(true, Std.int(Math.abs(daNote.noteData)) % 4, time);
					daNote.hitByOpponent = true;

					callOnLuas('opponentNoteHit', [notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);

					if (!daNote.isSustainNote)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}

				if (daNote.mustPress && cpuControlled)
				{
					if (daNote.isSustainNote)
					{
						if (daNote.canBeHit) goodNoteHit(daNote);
					}
					else if (daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress))
					{
						goodNoteHit(daNote);
					}
				}

				var doKill:Bool = ClientPrefs.downScroll ? daNote.y > FlxG.height : daNote.y < -daNote.height;
				if (doKill)
				{
					if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
						noteMiss(daNote);

					daNote.active  = false;
					daNote.visible = false;
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		checkEventNote();

		if (!inCutscene)
		{
			if (!cpuControlled)
				keyShit();
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
			&& boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}

		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime + 800 < Conductor.songPosition)
					{
						daNote.active = false; daNote.visible = false;
						daNote.kill(); notes.remove(daNote, true); daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length)
				{
					var daNote:Note = unspawnNotes[0];
					if (daNote.strumTime + 800 >= Conductor.songPosition) break;
					daNote.active = false; daNote.visible = false;
					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}
				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();
				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', PlayState.cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		#end
	}

	var isDead:Bool = false;

	function doDeathCheck()
	{
		if (health <= 0 && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if (ret != FunkinLua.Function_Stop)
			{
				boyfriend.stunned = true;
				deathCounter++;
				persistentUpdate = false;
				persistentDraw   = false;
				paused           = true;

				vocals.stop();
				FlxG.sound.music.stop();

				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollowPos.x, camFollowPos.y, this));
				for (tween in modchartTweens) tween.active = true;
				for (timer in modchartTimers) timer.active = true;

				#if desktop
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var early:Float      = eventNoteEarlyTrigger(eventNotes[0]);
			var leStrumTime:Float = eventNotes[0][0];
			if (Conductor.songPosition < leStrumTime - early) break;

			var value1:String = eventNotes[0][3] != null ? eventNotes[0][3] : '';
			var value2:String = eventNotes[0][4] != null ? eventNotes[0][4] : '';

			triggerEventNote(eventNotes[0][2], value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		return Reflect.getProperty(controls, key);
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0': value = 0;
					case 'gf' | 'girlfriend' | '1': value = 1;
				}
				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0) time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer    = time;
					}
					else
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer    = time;
					}
					if (curStage == 'mall')
					{
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer    = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value)) value = 1;
				gfSpeed = value;

			case 'Blammed Lights':
				var lightId:Int = Std.parseInt(value1);
				if (Math.isNaN(lightId)) lightId = 0;

				if (lightId > 0 && curLightEvent != lightId)
				{
					if (lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);
					var color:Int = switch (lightId)
					{
						case 1: 0xff31a2fd;
						case 2: 0xff31fd8c;
						case 3: 0xfff794f7;
						case 4: 0xfff96d63;
						case 5: 0xfffba633;
						default: 0xffffffff;
					};
					curLightEvent = lightId;

					if (blammedLightsBlack.alpha == 0)
					{
						if (blammedLightsBlackTween != null) blammedLightsBlackTween.cancel();
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) { blammedLightsBlackTween = null; }});

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length)
						{
							if (chars[i].colorTween != null) chars[i].colorTween.cancel();
							chars[i].colorTween = FlxTween.color(chars[i], 1, FlxColor.WHITE, color, {onComplete: function(twn:FlxTween) { chars[i].colorTween = null; }, ease: FlxEase.quadInOut});
						}
					}
					else
					{
						if (blammedLightsBlackTween != null) blammedLightsBlackTween.cancel();
						blammedLightsBlackTween    = null;
						blammedLightsBlack.alpha   = 1;
						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length)
						{
							if (chars[i].colorTween != null) chars[i].colorTween.cancel();
							chars[i].colorTween = null;
						}
						dad.color      = color;
						boyfriend.color = color;
						gf.color        = color;
					}

					if (curStage == 'philly' && phillyCityLightsEvent != null)
					{
						phillyCityLightsEvent.forEach(function(spr:BGSprite) { spr.visible = false; });
						phillyCityLightsEvent.members[lightId - 1].visible = true;
						phillyCityLightsEvent.members[lightId - 1].alpha   = 1;
					}
				}
				else
				{
					if (blammedLightsBlack.alpha != 0)
					{
						if (blammedLightsBlackTween != null) blammedLightsBlackTween.cancel();
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) { blammedLightsBlackTween = null; }});
					}

					if (curStage == 'philly')
					{
						phillyCityLights.forEach(function(spr:BGSprite) { spr.visible = false; });
						phillyCityLightsEvent.forEach(function(spr:BGSprite) { spr.visible = false; });
						var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
						if (memb != null)
						{
							memb.visible = true;
							memb.alpha   = 1;
							if (phillyCityLightsEventTween != null) phillyCityLightsEventTween.cancel();
							phillyCityLightsEventTween = FlxTween.tween(memb, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) { phillyCityLightsEventTween = null; }, ease: FlxEase.quadInOut});
						}
					}

					var chars:Array<Character> = [boyfriend, gf, dad];
					for (i in 0...chars.length)
					{
						if (chars[i].colorTween != null) chars[i].colorTween.cancel();
						chars[i].colorTween = FlxTween.color(chars[i], 1, chars[i].color, FlxColor.WHITE, {onComplete: function(twn:FlxTween) { chars[i].colorTween = null; }, ease: FlxEase.quadInOut});
					}
					curLight      = 0;
					curLightEvent = 0;
				}

			case 'Kill Henchmen': killHenchmen();

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;
					FlxG.camera.zoom += camZoom;
					camHUD.zoom      += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if (curStage == 'schoolEvil' && !ClientPrefs.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend': char = boyfriend;
					case 'gf' | 'girlfriend': char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2)) val2 = 0;
						switch (val2) { case 1: char = boyfriend; case 2: char = gf; }
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 0;
				if (Math.isNaN(val2)) val2 = 0;
				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x         = val1;
					camFollow.y         = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend': char = gf;
					case 'boyfriend' | 'bf':  char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val)) val = 0;
						switch (val) { case 1: char = boyfriend; case 2: char = gf; }
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String>   = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var dur:Float = Std.parseFloat(split[0].trim());
					var int:Float = Std.parseFloat(split[1].trim());
					if (Math.isNaN(dur)) dur = 0;
					if (Math.isNaN(int)) int = 0;
					if (dur > 0 && int != 0) targetsArray[i].shake(int, dur);
				}

			case 'Change Character':
				var charType:Int = Std.parseInt(value1);
				if (Math.isNaN(charType)) charType = 0;
				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2)) addCharacterToList(value2, charType);
							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							if (!boyfriend.alreadyLoaded) { boyfriend.alpha = 1; boyfriend.alreadyLoaded = true; }
							boyfriend.visible = true;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2)) addCharacterToList(value2, charType);
							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							dad.visible = false;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf')) { if (wasGf) gf.visible = true; } else { gf.visible = false; }
							if (!dad.alreadyLoaded) { dad.alpha = 1; dad.alreadyLoaded = true; }
							dad.visible = true;
							iconP2.changeIcon(dad.healthIcon);
						}
					case 2:
						if (gf.curCharacter != value2)
						{
							if (!gfMap.exists(value2)) addCharacterToList(value2, charType);
							gf.visible = false;
							gf = gfMap.get(value2);
							if (!gf.alreadyLoaded) { gf.alpha = 1; gf.alreadyLoaded = true; }
						}
				}
				reloadHealthBarColors();

			case 'BG Freaks Expression':
				if (bgGirls != null) bgGirls.swapDanceType();
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void
	{
		if (SONG.notes[id] == null) return;
		if (!SONG.notes[id].mustHitSection) { moveCamera(true);  callOnLuas('onMoveCamera', ['dad']); }
		else                                 { moveCamera(false); callOnLuas('onMoveCamera', ['boyfriend']); }
	}

	var cameraTwn:FlxTween;

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			switch (curStage)
			{
				case 'limo':              camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':              camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil': camFollow.x = boyfriend.getMidpoint().x - 200; camFollow.y = boyfriend.getMidpoint().y - 200;
			}
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween) { cameraTwn = null; }
				});
			}
		}
	}

	function tweenCamIn()
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween) { cameraTwn = null; }
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume           = 0;
		vocals.pause();
		if (ClientPrefs.noteOffset <= 0)
			endSong();
		else
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) { endSong(); });
	}

	var transitioning = false;

	public function endSong():Void
	{
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) health -= 0.0475;
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) health -= 0.0475;
			}
			if (doDeathCheck()) return;
		}

		timeBarBG.visible = false;
		timeBar.visible   = false;
		timeTxt.visible   = false;
		canPause          = false;
		endingSong        = true;
		camZooming        = false;
		inCutscene        = false;
		updateTime        = false;
		deathCounter      = 0;
		seenCutscene      = false;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null) return;
		var achieve:Int = checkForAchievement([1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15]);
		if (achieve > -1) { startAchievement(achieve); return; }
		#end

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if (ret != FunkinLua.Function_Stop && !transitioning)
		{
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (isStoryMode)
			{
				campaignScore  += songScore;
				campaignMisses += songMisses;
				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					cancelFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					if (FlxTransitionableState.skipNextTransIn) CustomFadeTransition.nextCamera = null;
					MusicBeatState.switchState(new StoryMenuState());

					if (!usedPractice)
					{
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						if (SONG.validScore) Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					usedPractice      = false;
					changedDifficulty = false;
					cpuControlled     = false;
				}
				else
				{
					var difficulty:String = '' + CoolUtil.difficultyStuff[storyDifficulty][1];
					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");

					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom)
							.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;
						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn  = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow    = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if (winterHorrorlandNext)
						new FlxTimer().start(1.5, function(tmr:FlxTimer) { cancelFadeTween(); LoadingState.loadAndSwitchState(new PlayState()); });
					else
					{
						cancelFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				cancelFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				if (FlxTransitionableState.skipNextTransIn) CustomFadeTransition.nextCamera = null;
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				usedPractice      = false;
				changedDifficulty = false;
				cpuControlled     = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;

	function startAchievement(achieve:Int)
	{
		achievementObj          = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
	}

	function achievementEnd():Void
	{
		achievementObj = null;
		if (endingSong && !inCutscene) endSong();
	}
	#end

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active  = false;
			daNote.visible = false;
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes   = [];
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + 8);
		vocals.volume = 1;

		var placement:String = Std.string(combo);
		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;

		var rating:FlxSprite = new FlxSprite();
		var score:Int        = 350;
		var daRating:String  = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.75)      { daRating = 'shit'; score = 50; }
		else if (noteDiff > Conductor.safeZoneOffset * 0.5)  { daRating = 'bad';  score = 100; }
		else if (noteDiff > Conductor.safeZoneOffset * 0.25) { daRating = 'good'; score = 200; }

		if (daRating == 'sick' && !note.noteSplashDisabled) spawnNoteSplashOnNote(note);

		if (!practiceMode && !cpuControlled)
		{
			songScore += score;
			songHits++;
			RecalculateRating();
			if (scoreTxtTween != null) scoreTxtTween.cancel();
			scoreTxt.scale.x = 1.1;
			scoreTxt.scale.y = 1.1;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {onComplete: function(twn:FlxTween) { scoreTxtTween = null; }});
		}

		var pixelShitPart1:String = PlayState.isPixelStage ? 'pixelUI/' : "";
		var pixelShitPart2:String = PlayState.isPixelStage ? '-pixel'   : '';

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.screenCenter();
		rating.x             = coolText.x - 40;
		rating.y            -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y   -= FlxG.random.int(140, 175);
		rating.velocity.x   -= FlxG.random.int(0, 10);
		rating.visible       = !ClientPrefs.hideHud;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x             = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y   -= 150;
		comboSpr.visible       = !ClientPrefs.hideHud;
		comboSpr.velocity.x   += FlxG.random.int(1, 10);

		add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing   = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width   * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];
		if (combo >= 1000) seperatedScore.push(Math.floor(combo / 1000) % 10);
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10)  % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y    -= FlxG.random.int(140, 160);
			numScore.velocity.x     = FlxG.random.float(-5, 5);
			numScore.visible        = !ClientPrefs.hideHud;

			if (combo >= 10 || combo == 0) add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween) { numScore.destroy(); },
				startDelay: Conductor.crochet * 0.002
			});
			daLoop++;
		}

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {startDelay: Conductor.crochet * 0.001});
		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween) { coolText.destroy(); comboSpr.destroy(); rating.destroy(); },
			startDelay: Conductor.crochet * 0.001
		});
		add(comboSpr);
	}

	private function keyShit():Void
	{
		var up    = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down  = controls.NOTE_DOWN;
		var left  = controls.NOTE_LEFT;

		var upP    = controls.NOTE_UP_P;
		var rightP = controls.NOTE_RIGHT_P;
		var downP  = controls.NOTE_DOWN_P;
		var leftP  = controls.NOTE_LEFT_P;

		var upR    = controls.NOTE_UP_R;
		var rightR = controls.NOTE_RIGHT_R;
		var downR  = controls.NOTE_DOWN_R;
		var leftR  = controls.NOTE_LEFT_R;

		#if mobile
		if (hitbox.LEFT)   left   = true;
		if (hitbox.DOWN)   down   = true;
		if (hitbox.UP)     up     = true;
		if (hitbox.RIGHT)  right  = true;
		if (hitbox.LEFT_P) leftP  = true;
		if (hitbox.DOWN_P) downP  = true;
		if (hitbox.UP_P)   upP    = true;
		if (hitbox.RIGHT_P) rightP = true;
		if (hitbox.LEFT_R) leftR  = true;
		if (hitbox.DOWN_R) downR  = true;
		if (hitbox.UP_R)   upR    = true;
		if (hitbox.RIGHT_R) rightR = true;
		#end

		var controlArray:Array<Bool>        = [leftP, downP, upP, rightP];
		var controlReleaseArray:Array<Bool> = [leftR,  downR,  upR,  rightR];
		var controlHoldArray:Array<Bool>    = [left,   down,   up,   right];

		if (!boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
					goodNoteHit(daNote);
			});

			if ((controlHoldArray.contains(true) || controlArray.contains(true)) && !endingSong)
			{
				var canMiss:Bool = !ClientPrefs.ghostTapping;
				if (controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						var pressNotes:Array<Note>  = [];
						var notesDatas:Array<Int>   = [];
						var notesStopped:Bool       = false;
						var sortedNotesList:Array<Note> = [];

						notes.forEachAlive(function(daNote:Note)
						{
							if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate
							&& !daNote.wasGoodHit && daNote.noteData == i)
							{
								sortedNotesList.push(daNote);
								notesDatas.push(daNote.noteData);
								canMiss = true;
							}
						});
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						if (sortedNotesList.length > 0)
						{
							for (epicNote in sortedNotesList)
							{
								for (doubleNote in pressNotes)
								{
									if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 10)
									{
										doubleNote.kill();
										notes.remove(doubleNote, true);
										doubleNote.destroy();
									}
									else notesStopped = true;
								}
								if (controlArray[epicNote.noteData] && !notesStopped)
								{
									goodNoteHit(epicNote);
									pressNotes.push(epicNote);
								}
							}
						}
						else if (canMiss)
							ghostMiss(controlArray[i], i, true);

						if (!keysPressed[i] && controlArray[i]) keysPressed[i] = true;
					}
				}

				#if ACHIEVEMENTS_ALLOWED
				var achieve:Int = checkForAchievement([11]);
				if (achieve > -1) startAchievement(achieve);
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
			&& boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}

		playerStrums.forEach(function(spr:StrumNote)
		{
			if (controlArray[spr.ID] && spr.animation.curAnim.name != 'confirm') { spr.playAnim('pressed'); spr.resetAnim = 0; }
			if (controlReleaseArray[spr.ID])                                      { spr.playAnim('static');  spr.resetAnim = 0; }
		});
	}

	function ghostMiss(statement:Bool = false, direction:Int = 0, ?ghostMiss:Bool = false)
	{
		if (statement) { noteMissPress(direction, ghostMiss); callOnLuas('noteMissPress', [direction]); }
	}

	function noteMiss(daNote:Note):Void
	{
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData
			&& daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10)
			{
				note.kill(); notes.remove(note, true); note.destroy();
			}
		});

		health      -= daNote.missHealth;
		songMisses++;
		vocals.volume = 0;
		RecalculateRating();

		var animToPlay:String = switch (Math.abs(daNote.noteData) % 4)
		{
			case 0: 'singLEFTmiss';
			case 1: 'singDOWNmiss';
			case 2: 'singUPmiss';
			case 3: 'singRIGHTmiss';
			default: '';
		};

		if (daNote.noteType == 'GF Sing') gf.playAnim(animToPlay, true);
		else
		{
			var daAlt = daNote.noteType == 'Alt Animation' ? '-alt' : '';
			boyfriend.playAnim(animToPlay + daAlt, true);
		}
		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1, ?ghostMiss:Bool = false):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.04;
			if (combo > 5 && gf.animOffsets.exists('sad')) { gf.playAnim('sad'); }
			combo = 0;

			if (!practiceMode) songScore -= 10;
			if (!endingSong)
			{
				if (ghostMiss) ghostMisses++;
				songMisses++;
			}
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			switch (direction)
			{
				case 0: boyfriend.playAnim('singLEFTmiss',  true);
				case 1: boyfriend.playAnim('singDOWNmiss',  true);
				case 2: boyfriend.playAnim('singUPmiss',    true);
				case 3: boyfriend.playAnim('singRIGHTmiss', true);
			}
			vocals.volume = 0;
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (note.hitCausesMiss)
			{
				noteMiss(note);
				if (!note.noteSplashDisabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
				switch (note.noteType)
				{
					case 'Hurt Note':
						if (boyfriend.animation.getByName('hurt') != null) { boyfriend.playAnim('hurt', true); boyfriend.specialAnim = true; }
				}
				note.wasGoodHit = true;
				if (!note.isSustainNote) { note.kill(); notes.remove(note, true); note.destroy(); }
				return;
			}

			if (!note.isSustainNote) { popUpScore(note); combo += 1; if (combo > 9999) combo = 9999; }
			health += note.hitHealth;

			if (!note.noAnimation)
			{
				var daAlt:String = note.noteType == 'Alt Animation' ? '-alt' : '';
				var animToPlay:String = switch (Std.int(Math.abs(note.noteData)))
				{
					case 0: 'singLEFT';
					case 1: 'singDOWN';
					case 2: 'singUP';
					case 3: 'singRIGHT';
					default: '';
				};

				if (note.noteType == 'GF Sing') { gf.playAnim(animToPlay + daAlt, true); gf.holdTimer = 0; }
				else                             { boyfriend.playAnim(animToPlay + daAlt, true); boyfriend.holdTimer = 0; }

				if (note.noteType == 'Hey!')
				{
					if (boyfriend.animOffsets.exists('hey')) { boyfriend.playAnim('hey', true); boyfriend.specialAnim = true; boyfriend.heyTimer = 0.6; }
					if (gf.animOffsets.exists('cheer'))      { gf.playAnim('cheer', true);      gf.specialAnim        = true; gf.heyTimer        = 0.6; }
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) time += 0.15;
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			}
			else
			{
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID) spr.playAnim('confirm', true);
				});
			}

			note.wasGoodHit = true;
			vocals.volume   = 1;

			var isSus:Bool   = note.isSustainNote;
			var leData:Int   = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote) { note.kill(); notes.remove(note, true); note.destroy(); }
		}
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null) spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if (note != null) { skin = note.noteSplashTexture; hue = note.noteSplashHue; sat = note.noteSplashSat; brt = note.noteSplashBrt; }

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x           = -12600;
		fastCar.y           = FlxG.random.int(140, 250);
		fastCar.velocity.x  = 0;
		fastCarCanDrive     = true;
	}

	var carTimer:FlxTimer;

	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);
		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive    = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer) { resetFastCar(); carTimer = null; });
	}

	var trainMoving:Bool     = false;
	var trainFrameTiming:Float = 0;
	var trainCars:Int        = 8;
	var trainFinishing:Bool  = false;
	var trainCooldown:Int    = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing) trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
			gf.specialAnim = true;
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;
			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars    -= 1;
				if (trainCars <= 0) trainFinishing = true;
			}
			if (phillyTrain.x < -4000 && trainFinishing) trainReset();
		}
	}

	function trainReset():Void
	{
		gf.danced       = false;
		gf.playAnim('hairFall');
		gf.specialAnim  = true;
		phillyTrain.x   = FlxG.width + 200;
		trainMoving     = false;
		trainCars       = 8;
		trainFinishing  = false;
		startedMoving   = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if (!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset     = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared')) boyfriend.playAnim('scared', true);
		if (gf.animOffsets.exists('scared'))        gf.playAnim('scared', true);

		if (ClientPrefs.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom      += 0.03;
			if (!camZooming) { FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5); FlxTween.tween(camHUD, {zoom: 1}, 0.5); }
		}

		if (ClientPrefs.flashing)
		{
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if (!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo')
		{
			if (limoKillingState < 1)
			{
				limoMetalPole.x      = -400;
				limoMetalPole.visible = true;
				limoLight.visible    = true;
				limoCorpse.visible   = false;
				limoCorpseTwo.visible = false;
				limoKillingState     = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				var achieve:Int = checkForAchievement([10]);
				if (achieve > -1)
				{
					startAchievement(achieve);
				}
				else
				{
					FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
					FlxG.save.flush();
				}
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if (curStage == 'limo')
		{
			limoMetalPole.x      = -500; limoMetalPole.visible  = false;
			limoLight.x          = -500; limoLight.visible      = false;
			limoCorpse.x         = -500; limoCorpse.visible     = false;
			limoCorpseTwo.x      = -500; limoCorpseTwo.visible  = false;
		}
	}

	private var preventLuaRemove:Bool = false;

	override function destroy()
	{
		preventLuaRemove = true;
		for (i in 0...luaArray.length) { luaArray[i].call('onDestroy', []); luaArray[i].stop(); }
		luaArray = [];

		#if mobile
		if (hitbox != null) { hitbox.destroy(); hitbox = null; }
		#end

		super.destroy();
	}

	public function cancelFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null) FlxG.sound.music.fadeTween.cancel();
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua)
	{
		if (luaArray != null && !preventLuaRemove) luaArray.remove(lua);
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
			resyncVocals();

		if (curStep == lastStepHit) return;
		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int     = 8;
	var lastBeatHit:Int         = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat) return;

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				setOnLuas('curBpm',      Conductor.bpm);
				setOnLuas('crochet',     Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
			moveCameraSection(Std.int(curStep / 16));

		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom      += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30)); iconP1.updateHitbox();
		iconP2.setGraphicSize(Std.int(iconP2.width + 30)); iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
			gf.dance();

		if (curBeat % 2 == 0)
		{
			if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith('sing')) boyfriend.dance();
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned) dad.dance();
		}
		else if (dad.danceIdle && dad.animation.curAnim.name != null && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			dad.dance();

		switch (curStage)
		{
			case 'school':
				if (!ClientPrefs.lowQuality) bgGirls.dance();
			case 'mall':
				if (!ClientPrefs.lowQuality) upperBoppers.dance(true);
				if (heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);
			case 'limo':
				if (!ClientPrefs.lowQuality)
					grpLimoDancers.forEach(function(dancer:BackgroundDancer) { dancer.dance(); });
				if (FlxG.random.bool(10) && fastCarCanDrive) fastCarDrive();
			case "philly":
				if (!trainMoving) trainCooldown += 1;
				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:BGSprite) { light.visible = false; });
					curLight = FlxG.random.int(0, phillyCityLights.length - 1, [curLight]);
					phillyCityLights.members[curLight].visible = true;
					phillyCityLights.members[curLight].alpha   = 1;
				}
				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
			lightningStrikeShit();

		lastBeatHit = curBeat;
		setOnLuas('curBeat', curBeat);
		callOnLuas('onBeatHit', []);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			var ret:Dynamic = luaArray[i].call(event, args);
			if (ret != FunkinLua.Function_Continue) returnVal = ret;
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) luaArray[i].set(variable, arg);
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = isDad ? strumLineNotes.members[id] : playerStrums.members[id];
		if (spr != null) { spr.playAnim('confirm', true); spr.resetAnim = time; }
	}

	public var ratingString:String;
	public var ratingPercent:Float;

	public function RecalculateRating()
	{
		setOnLuas('score',       songScore);
		setOnLuas('misses',      songMisses);
		setOnLuas('ghostMisses', songMisses);
		setOnLuas('hits',        songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if (ret != FunkinLua.Function_Stop)
		{
			ratingPercent = songScore / ((songHits + songMisses - ghostMisses) * 350);
			if (!Math.isNaN(ratingPercent) && ratingPercent < 0) ratingPercent = 0;

			if (Math.isNaN(ratingPercent))
			{
				ratingString = '?';
			}
			else if (ratingPercent >= 1)
			{
				ratingPercent = 1;
				ratingString  = ratingStuff[ratingStuff.length - 1][0];
			}
			else
			{
				for (i in 0...ratingStuff.length - 1)
				{
					if (ratingPercent < ratingStuff[i][1]) { ratingString = ratingStuff[i][0]; break; }
				}
			}

			setOnLuas('rating',     ratingPercent);
			setOnLuas('ratingName', ratingString);
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(arrayIDs:Array<Int>):Int
	{
		for (i in 0...arrayIDs.length)
		{
			if (!Achievements.achievementsUnlocked[arrayIDs[i]][1])
			{
				switch (arrayIDs[i])
				{
					case 1 | 2 | 3 | 4 | 5 | 6 | 7:
						if (isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1 && WeekData.getWeekFileName() == ('week' + arrayIDs[i]) && !changedDifficulty && !usedPractice)
						{ Achievements.unlockAchievement(arrayIDs[i]); return arrayIDs[i]; }
					case 8:
						if (ratingPercent < 0.2 && !practiceMode && !cpuControlled)
						{ Achievements.unlockAchievement(arrayIDs[i]); return arrayIDs[i]; }
					case 9:
						if (ratingPercent >= 1 && !usedPractice && !cpuControlled)
						{ Achievements.unlockAchievement(arrayIDs[i]); return arrayIDs[i]; }
					case 10:
						if (Achievements.henchmenDeath >= 100)
						{ Achievements.unlockAchievement(arrayIDs[i]); return arrayIDs[i]; }
					case 11:
						if (boyfriend.holdTimer >= 20 && !usedPractice)
						{ Achievements.unlockAchievement(arrayIDs[i]); return arrayIDs[i]; }
					case 12:
						if (!boyfriendIdled && !usedPractice)
						{ Achievements.unlockAchievement(arrayIDs[i]); return arrayIDs[i]; }
					case 13:
						if (!usedPractice)
						{
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) if (keysPressed[j]) howManyPresses++;
							if (howManyPresses <= 2) { Achievements.unlockAchievement(arrayIDs[i]); return arrayIDs[i]; }
						}
					case 14:
						if (ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist)
						{ Achievements.unlockAchievement(arrayIDs[i]); return arrayIDs[i]; }
					case 15:
						if (Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice)
						{ Achievements.unlockAchievement(arrayIDs[i]); return arrayIDs[i]; }
				}
			}
		}
		return -1;
	}
	#end

	var curLight:Int      = 0;
	var curLightEvent:Int = 0;
}

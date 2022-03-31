package states;

import ui.InfinityDialogueBox;
import util.WeekShit;
import mods.Mods;
import game.Stage;
import options.UISkinList;
import options.OptionsHandler;
import game.Highscore;
import util.CoolUtil;
import game.Song;
import game.Conductor;
import ui.DialogueBox;
#if desktop
import util.Discord.DiscordClient;
#end
import game.Section.SwagSection;
import game.Song.SwagSong;
import util.WiggleEffect.WiggleEffectType;
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
import flixel.system.FlxSound;
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
import background.BackgroundDancer;
import background.BackgroundGirls;
import util.Cache;
import game.Character;
import game.Boyfriend;
import game.StrumNote;
import game.Note;
import ui.HealthIcon;
import util.WiggleEffect;
import eastereggs.GitarooPause;
import flixel.input.FlxInput.FlxInputState;
import substates.PauseSubState;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;

	public static var storyWeek:Null<Int> = 0;
	public static var storyWeekName:Null<String> = "tutorial";

	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public static var instance:PlayState;
	public static var songMultiplier:Float = 1;

	public var keyCount:Int = 4;
	public var isPixelStage:Bool = false;

	private var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public static var curUISkin:String = "default";

	private var strumLineNotes:FlxTypedGroup<StrumNote>;
	private var opponentStrums:FlxTypedGroup<StrumNote>;
	private var playerStrums:FlxTypedGroup<StrumNote>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;

	private var camOther:FlxCamera;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	public var stage:Stage;

	public var singAnimations:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

	var talking:Bool = true;
	var songScore:Int = 0;
	var scoreTxt:FlxText;

	var ratingTxt:FlxText;

	public var accuracy:Float = 0;
	public var accuracyNum:Float = 0;

	var funnyHitStuffsLmao:Float = 0.0;
	var totalNoteStuffs:Int = 0;

	var rating1:String = "N/A";
	var rating2:String = "N/A";

	public var marvelous:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	public var songMisses:Int = 0;

	public var speed:Float = 1;

	public var usedPractice:Bool = false;

	var letterRatings:Array<String> = [
		"S++",
		"S+",
		"S",
		"A",
		"B",
		"C",
		"D",
		"E",
		"F",
	];

	var swagRatings:Array<String> = [
		'Clear',
		'SDCB',
		'FC',
		'GFC',
		'SFC'
	];

	public var hits:Float = 0;

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var inCutscene:Bool = false;

	public static var previousScrollSpeedLmao:Float = 0;

	public var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	override public function new(?skipTransition:Bool = false)
	{
		super();

		transIn = FlxTransitionableState.defaultTransIn;
        transOut = FlxTransitionableState.defaultTransOut;

		FlxTransitionableState.skipNextTransIn = skipTransition;
		FlxTransitionableState.skipNextTransOut = skipTransition;

		instance = this;
	}

	override public function create()
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		UISkinList.init();

		var songToCache = Paths.formatToSongPath(PlayState.SONG.song);

		// stupid way of caching but i think it works so uh lmao L skill issue +99999 ratio
		FlxG.sound.playMusic(Paths.voices(Paths.formatToSongPath(PlayState.SONG.song)), 0, false);
		FlxG.sound.playMusic(Paths.inst(Paths.formatToSongPath(PlayState.SONG.song)), 0, false);

		// i have to cache the inst AFTER for songs without vocals otherwise the song just instantly ends
		// :thumbs_up:

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();

		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if(Options.getData('botplay'))
			usedPractice = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		#if !sys
		songMultiplier = 1;
		#end

		if(songMultiplier < 0.25)
			songMultiplier = 0.25;

		if(SONG.timescale == null)
			SONG.timescale = [4, 4];

		Conductor.timeScale = SONG.timescale;

		Conductor.mapBPMChanges(SONG, songMultiplier);
		Conductor.changeBPM(SONG.bpm, songMultiplier);

		previousScrollSpeedLmao = SONG.speed;

		speed = SONG.speed;

		SONG.speed /= songMultiplier;

		if(SONG.speed < 0.1 && songMultiplier > 1)
			SONG.speed = 0.1;

		if(Options.getData('scroll-speed') > 0)
			speed = Options.getData('scroll-speed') / songMultiplier;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		Conductor.recalculateStuff(songMultiplier);
		Conductor.safeZoneOffset *= songMultiplier;

		switch (SONG.song.toLowerCase())
		{
			case 'tutorial':
				dialogue = ["Hey you're pretty cute.", 'Use the arrow keys to keep up \nwith me singing.'];
			case 'bopeebo':
				dialogue = [
					'HEY!',
					"You think you can just sing\nwith my daughter like that?",
					"If you want to date her...",
					"You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = ["Not too shabby boy.", ""];
			case 'dadbattle':
				dialogue = [
					"gah you think you're hot stuff?",
					"If you can beat me here...",
					"Only then I will even CONSIDER letting you\ndate my daughter!"
				];
			case 'senpai':
				dialogue = CoolUtil.coolTextFile(Paths.txt('data/senpai/senpaiDialogue'));
			case 'roses':
				dialogue = CoolUtil.coolTextFile(Paths.txt('data/roses/rosesDialogue'));
			case 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.txt('data/thorns/thornsDialogue'));
		}

		#if desktop
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty)
		{
			case 0:
				storyDifficultyText = "Easy";
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
		}

		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode: Week " + storyWeek;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end

		curStage = SONG.stage;

		switch (Paths.formatToSongPath(SONG.song.toLowerCase()))
		{
			default:
				curStage = 'stage';
			case 'spookeez' | 'south' | 'monster': 
				curStage = 'spooky';
			case 'pico' | 'philly nice' | 'blammed': 
				curStage = 'philly';
			case 'satin-panties' | 'high' | 'm.i.l.f': 
				curStage = 'limo';
			case 'cocoa' | 'eggnog': 
				curStage = 'mall';
			case 'winter horrorland':
				curStage = 'mallEvil';
			case 'senpai' | 'roses': 
				curStage = 'school';
			case 'thorns': 
				curStage = 'schoolEvil';
		}

		if(SONG.ui_Skin == null)
			SONG.ui_Skin = "default";

		curUISkin = SONG.ui_Skin;

		if(Options.getData("ui-skin") != "default")
			curUISkin = Options.getData("ui-skin");

		switch(Paths.formatToSongPath(SONG.song.toLowerCase())) // song skin
		{
			case "senpai" | "roses" | "thorns":
				if(UISkinList.skins.contains(curUISkin + '-pixel'))
					curUISkin = curUISkin + '-pixel';
		}

		var gfVersion:String = 'gf';

		if(SONG.gf != null)
			gfVersion = SONG.gf;

		if(SONG.player3 != null)
			gfVersion = SONG.player3;

		switch (curStage)
		{
			case 'stage' | 'spooky' | 'philly':
				gfVersion = 'gf';
			case 'limo':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school':
				gfVersion = 'gf-pixel';
			case 'schoolEvil':
				gfVersion = 'gf-pixel';
		}

		if(Options.getData('optimization'))
		{
			curStage = '';
			SONG.player2 = '';
			SONG.player1 = '';
			gfVersion = '';
		}

		var stageJson:StageData;

		if(curStage == '')
			stageJson = Paths.parseJson('stages/stage');
		else
			stageJson = Paths.parseJson('stages/$curStage');

		if(stageJson == null)
			stageJson = Paths.parseJson('stages/stage');

		defaultCamZoom = stageJson.defaultZoom;
		isPixelStage = stageJson.isPixelStage;

		gf = new Character(stageJson.girlfriend[0], stageJson.girlfriend[1], gfVersion, false);

		for(char in gf.members)
		{
			char.scrollFactor.set(0.95, 0.95);
		}

		dad = new Character(stageJson.opponent[0], stageJson.opponent[1], SONG.player2, false);
		boyfriend = new Boyfriend(stageJson.boyfriend[0], stageJson.boyfriend[1], SONG.player1, true);

		stage = new Stage();
		stage.changeStage(curStage);
		add(stage);

		var camPos:FlxPoint = new FlxPoint(0, 0);

		if(gfVersion == SONG.player2)
		{
			var real_i:Int = 0;
			for(char in dad.members)
			{
				char.setPosition(gf.members[real_i].x, gf.members[real_i].y);
				real_i++;
			}

			gf.loadCharacter(0, 0, ''); // we do this for less lag :thumbs_up:
		}

		if(dad.members[0] != null)
			camPos = new FlxPoint(dad.members[0].getMidpoint().x, dad.members[0].getMidpoint().y);

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad.members[0], null, 4, 24, 0.3, 0.069);
				add(evilTrail);
		}

		if(dad.members[0] != null)
		{
			camPos.set(dad.members[0].getMidpoint().x + 150, dad.members[0].getMidpoint().y - 100);

			camPos.x += dad.cameraPosition[0];
			camPos.y += dad.cameraPosition[1];
		}
		else
			camPos.set(0, 0);

		add(gf);
		add(stage.infrontOfGFSprites);

		// Shitty layering but whatev it works LOL
		/*if (curStage == 'limo')
			stage.add(limo);*/

		add(dad);
		add(boyfriend);

		add(stage.foregroundSprites);

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (Options.getData('downscroll'))
			strumLine.y = FlxG.height - 150;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		var healthBarPosY = FlxG.height * 0.9;

		if(FlxG.save.data.downscroll)
			healthBarPosY = 60;

		healthBarBG = new FlxSprite(0, healthBarPosY).loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();

		var healthColor1:Int = 0xFFA1A1A1;
		var healthColor2:Int = 0xFFA1A1A1;

		var healthIcon1:String = 'placeholder';
		var healthIcon2:String = 'placeholder';

		if(dad.members[0] != null && dad.active)
		{
			healthIcon1 = dad.healthIcon;
			healthColor1 = FlxColor.fromRGB(dad.healthColor[0], dad.healthColor[1], dad.healthColor[2]);
		}

		if(boyfriend.members[0] != null && boyfriend.active)
		{
			healthIcon2 = boyfriend.healthIcon;
			healthColor2 = FlxColor.fromRGB(boyfriend.healthColor[0], boyfriend.healthColor[1], boyfriend.healthColor[2]);
		}
			
		healthBar.createFilledBar(healthColor1, healthColor2);
		// healthBar
		add(healthBar);

		iconP1 = new HealthIcon(healthIcon2, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(healthIcon1, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 40, 0, "", 16);
		scoreTxt.setFormat(Paths.font("vcr"), 16, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		scoreTxt.borderSize = 2;
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		ratingTxt = new FlxText(10, 10, 0, "", 16);
		ratingTxt.setFormat(Paths.font("vcr"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		ratingTxt.borderSize = 2;
		ratingTxt.scrollFactor.set();
		add(ratingTxt);

		if(isStoryMode)
		{
			healthBarBG.visible = false;
			healthBar.visible = false;
			scoreTxt.visible = false;
			ratingTxt.visible = false;

			iconP2.visible = false;
			iconP1.visible = false;
		}

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		ratingTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode)
		{
			switch (curSong.toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai':
					schoolIntro(doof);
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'thorns':
					schoolIntro(doof);
				default:
					infinityDialogue();
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		}

		super.create();
	}

	function infinityDialogue()
	{
		var dialogueJson:DialogueData = Paths.parseJson('data/' + Paths.formatToSongPath(SONG.song) + '/dialogue');

		if(dialogueJson == null)
			startCountdown();
		else
		{
			var doof:InfinityDialogueBox = new InfinityDialogueBox(dialogueJson);
			doof.cameras = [camHUD];
			doof.finishThing = startCountdown;
			add(doof);

			inCutscene = true;
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
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

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
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
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns')
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
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	public var introSoundsSuffix:String = "";

	function startCountdown():Void
	{
		inCutscene = false;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start((Conductor.crochet / 1000) / songMultiplier, function(tmr:FlxTimer)
		{
			dad.dance();
			gf.dance();
			boyfriend.dance();

			introSoundsSuffix = '';
			
			if(curUISkin.split('-')[1] != null)
				introSoundsSuffix = '-' + curUISkin.split('-')[1];

			trace("INTRO SOUNDS SUFFIX: " + introSoundsSuffix);

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);

					healthBarBG.visible = true;
					healthBar.visible = true;
					scoreTxt.visible = true;
					ratingTxt.visible = true;
			
					iconP2.visible = true;
					iconP1.visible = true;
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui-skins/$curUISkin/ready'));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (curUISkin.endsWith('-pixel'))
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {alpha: 0}, (Conductor.crochet / 1000) / songMultiplier, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui-skins/$curUISkin/set'));
					set.scrollFactor.set();

					if (curUISkin.endsWith('-pixel'))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {alpha: 0}, (Conductor.crochet / 1000) / songMultiplier, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui-skins/$curUISkin/go'));
					go.scrollFactor.set();

					if (curUISkin.endsWith('-pixel'))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {alpha: 0}, (Conductor.crochet / 1000) / songMultiplier, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			FlxG.sound.playMusic(Paths.inst(Paths.formatToSongPath(PlayState.SONG.song)), 1, false);
		
		//FlxG.sound.music.onComplete = endSong;
		vocals.play();

		vocals.volume = 1;

		#if cpp
		@:privateAccess
		{
			lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);

			if (vocals.playing)
				lime.media.openal.AL.sourcef(vocals._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
		}
		#end

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		#if desktop
		Conductor.recalculateStuff(songMultiplier);

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength / songMultiplier);
		#end
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm, songMultiplier);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(Paths.formatToSongPath(PlayState.SONG.song)));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			Conductor.recalculateStuff(songMultiplier);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0] + (Options.getData('note-offset') * songMultiplier);
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, curUISkin);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, curUISkin);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else {}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:StrumNote = new StrumNote(0, strumLine.y, i, curUISkin);
			babyArrow.scrollFactor.set();

			switch (i)
			{
				case 0:
					babyArrow.x += Note.swagWidth * 0;
				case 1:
					babyArrow.x += Note.swagWidth * 1;
				case 2:
					babyArrow.x += Note.swagWidth * 2;
				case 3:
					babyArrow.x += Note.swagWidth * 3;
			}

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				opponentStrums.add(babyArrow);
			}

			babyArrow.playAnim('static');
			babyArrow.x += 95;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function tweenCamOut():Void
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
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

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, ((songLength - Conductor.songPosition) / songMultiplier >= 1 ? (songLength - Conductor.songPosition) / songMultiplier : 1));
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
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
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, ((songLength - Conductor.songPosition) / songMultiplier >= 1 ? (songLength - Conductor.songPosition) / songMultiplier : 1));
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = Conductor.songPosition;
		vocals.time = Conductor.songPosition;
		
		FlxG.sound.music.play();
		vocals.play();

		#if cpp
		@:privateAccess
		{
			lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);

			if (vocals.playing)
				lime.media.openal.AL.sourcef(vocals._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
		}
		#end
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	var cameraTwn:FlxTween;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		FlxG.camera.followLerp = 0.04 * (60 / Main.display.currentFPS);

		/*if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}*/

		if(!startingSong && (FlxG.sound.music != null && !FlxG.sound.music.playing) && !endingSong)
		{
			FlxG.sound.music.play();
			vocals.play();
			resyncVocals();
		}

		super.update(elapsed);

		if (generatedMusic)
		{
			if (startedCountdown && canPause && !endingSong)
			{
				// Song ends abruptly on slow rate even with second condition being deleted, 
				// and if it's deleted on songs like cocoa then it would end without finishing instrumental fully,
				// so no reason to delete it at all
				if (FlxG.sound.music.length - Conductor.songPosition <= 20)
				{
					endSong();
				}
			}
		}

		calculateAccuracy();
		accuracyNum = FlxMath.roundDecimal(accuracy * 100, 2);

		updateAccuracyStuff();

		scoreTxt.text = "Score:" + songScore + " | Misses: " + songMisses + " | Accuracy: " + accuracyNum + "% | Rating: " + rating1 + " [" + rating2 + "]";
		scoreTxt.screenCenter(X);

		ratingTxt.text = 'Marvelous: $marvelous\nSicks: $sicks\nGoods: $goods\nBads: $bads\nShits: $shits\nMisses: $songMisses\n';
		ratingTxt.screenCenter(Y);

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				// gitaroo man easter egg
				FlxG.switchState(new GitarooPause());
			}
			else
			{
				openSubState(new PauseSubState());
			}
		
			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);
		
		var multX:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 15), 0, 1));
		var multY:Float = FlxMath.lerp(1, iconP1.scale.y, CoolUtil.boundTo(1 - (elapsed * 15), 0, 1));

		iconP1.scale.set(multX, multY);
		iconP1.updateHitbox();

		var multX:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 15), 0, 1));
		var multY:Float = FlxMath.lerp(1, iconP2.scale.y, CoolUtil.boundTo(1 - (elapsed * 15), 0, 1));

		iconP2.scale.set(multX, multY);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		#if debug
		if (FlxG.keys.justPressed.EIGHT)
			//FlxG.switchState(new AnimationDebug(SONG.player2));
		#end

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += (FlxG.elapsed * 1000) * songMultiplier;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += (FlxG.elapsed * 1000) * songMultiplier;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if(dad.members[0] != null)
			{
				if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
				{
					camFollow.setPosition(dad.members[0].getMidpoint().x + 150, dad.members[0].getMidpoint().y - 100);

					camFollow.x += dad.cameraPosition[0];
					camFollow.y += dad.cameraPosition[1];

					if (SONG.song.toLowerCase() == 'tutorial')
						tweenCamIn();
				}
			}
			
			if(boyfriend.members[0] != null)
			{
				if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
				{
					camFollow.setPosition(boyfriend.members[0].getMidpoint().x - 100, boyfriend.members[0].getMidpoint().y - 100);

					camFollow.x += boyfriend.cameraPosition[0];
					camFollow.y += boyfriend.cameraPosition[1];

					if (SONG.song.toLowerCase() == 'tutorial')
						tweenCamOut();
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		// RESET = Quick Game Over Screen
		if (controls.RESET && !inCutscene)
		{
			health = 0;
			trace("RESET = True");
		}

		if (health <= 0)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			if(boyfriend.members[0] != null)
				openSubState(new substates.GameOverSubstate(boyfriend.members[0].getScreenPosition().x, boyfriend.members[0].getScreenPosition().y));
			else
				openSubState(new substates.GameOverSubstate(700, 500));

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			
			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (unspawnNotes[0] != null)
		{
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < (3500 * songMultiplier))
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		opponentStrums.forEachAlive(function(spr:StrumNote)
		{
			if(spr.animation.curAnim != null)
			{
				if (spr.animation.curAnim.name == 'confirm' && spr.animation.curAnim.finished)
				{
					spr.playAnim('static');
				}
			}
		});

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				if(Options.getData('downscroll'))
				{
					daNote.y = strumLine.y - (-0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(speed, 2));
				}
				else
				{
					daNote.y = strumLine.y - (0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(speed, 2));
				}
					
				if(Options.getData('downscroll') && daNote.isSustainNote)
				{
					var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
					if (daNote.animation.curAnim.name.endsWith('end')) {
						daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * speed + (46 * (speed - 1));
						daNote.y -= 46 * (1 - (fakeCrochet / 600)) * speed;

						if(PlayState.curUISkin.endsWith('-pixel'))
							daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
					} 
					daNote.y += (Note.swagWidth / 2) - (60.5 * (speed - 1));
					daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (speed - 1);
				}

				// i am so fucking sorry for this if condition

				// OLD CLIP RECT SHIT
				/*if (daNote.isSustainNote
					&& daNote.y + daNote.offset.y <= strumLine.y + Note.swagWidth / 2
					&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					var swagRect = new FlxRect(0, strumLine.y + Note.swagWidth / 2 - daNote.y, daNote.width * 2, daNote.height * 2);
					swagRect.y /= daNote.scale.y;
					swagRect.height -= swagRect.y;

					daNote.clipRect = swagRect;
				}*/

				// NEW CLIP RECT SHIT

				var center:Float = strumLineNotes.members[daNote.noteData].y + Note.swagWidth / 2;

				if((daNote.isSustainNote && (daNote.mustPress) &&
				(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))) || (!daNote.mustPress && daNote.isSustainNote))
				{
					if (Options.getData('downscroll'))
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					for(char in dad.members)
					{
						if(!char.specialAnim)
						{
							switch (Math.abs(daNote.noteData))
							{
								case 0:
									dad.playAnim(singAnimations[0] + altAnim, true);
								case 1:
									dad.playAnim(singAnimations[1] + altAnim, true);
								case 2:
									dad.playAnim(singAnimations[2] + altAnim, true);
								case 3:
									dad.playAnim(singAnimations[3] + altAnim, true);
							}
						}
					}

					for(char in dad.members)
					{
						char.holdTimer = 0;
					}

					if (SONG.needsVoices)
						vocals.volume = 1;

					opponentStrums.forEach(function(spr:StrumNote)
					{
						if (Math.abs(daNote.noteData) == spr.ID)
						{
							spr.playAnim('confirm', true);
						}
					});

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				/*var doKill:Bool = daNote.y < -daNote.height;
				if(Options.getData('downscroll')) doKill = daNote.y > FlxG.height;*/

				// even better way of calculating misses!!! i think!!! lol!!!

				if ((Conductor.songPosition > daNote.strumTime + (Conductor.safeZoneOffset * 1.2)) && (daNote.mustPress || Options.getData('botplay')))
				{
					if (daNote.tooLate || !daNote.wasGoodHit)
					{
						noteMiss(Math.floor(Math.abs(daNote.noteData)), daNote);
						vocals.volume = 0;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if (!inCutscene)
			keyShit();

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}

	function calculateAccuracy()
	{
		if(hits > 0)
		{
			if(!Options.getData('botplay'))
				accuracy = funnyHitStuffsLmao / totalNoteStuffs;
			else
				accuracy = 1;
		}
	}


	function updateAccuracyStuff()
		{
			if(hits > 0)
			{
				if(Options.getData('botplay') || rating1 == "N/A")
					accuracyNum == 100;
				
				if(accuracyNum == 100)
					rating1 = letterRatings[0];
				
				else if(accuracyNum >= 90)	
					rating1 = letterRatings[1];
	
				else if(accuracyNum >= 80)	
					rating1 = letterRatings[2];
	
				else if(accuracyNum >= 70)	
					rating1 = letterRatings[3];
	
				else if(accuracyNum >= 60)	
					rating1 = letterRatings[4];
	
				else if(accuracyNum >= 50)	
					rating1 = letterRatings[5];
	
				else if(accuracyNum >= 40)	
					rating1 = letterRatings[6];
	
				else if(accuracyNum >= 30)	
					rating1 = letterRatings[7];
	
				else if(accuracyNum >= 20)	
					rating1 = letterRatings[8];
	
				rating2 = swagRatings[0]; // just in case the shit below doesn't work
				if (songMisses == 0 && goods == 0 && bads == 0 && shits == 0)
				{
					rating2 = swagRatings[4];
				}
				else if (songMisses == 0 && goods >= 1 && bads == 0 && shits == 0)
				{
					rating2 = swagRatings[3];
				}
				else if (songMisses == 0)
				{
					rating2 = swagRatings[2];
				}
				else if (songMisses < 10)
				{
					rating2 = swagRatings[1];
				}
				else
				{
					rating2 = swagRatings[0];
				}
			}
		}

	function endSong():Void
	{
		trace("END SONG FUNCTION SUCCESS");
		
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;

		if (SONG.validScore)
		{
			if(!usedPractice && songMultiplier >= 1)
				Highscore.saveScore(SONG.song, songScore, storyDifficulty);
		}

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				FlxG.switchState(new StoryMenuState());

				//StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;
				WeekShit.setCompletedWeek(storyWeekName, true);

				if (SONG.validScore)
				{
					if(!usedPractice && songMultiplier >= 1)
						Highscore.saveWeekScore(storyWeekName, campaignScore, storyDifficulty);
				}

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = CoolUtil.getDifficultyFilePath();

				trace('LOADING NEXT SONG');
				trace(Paths.formatToSongPath(PlayState.storyPlaylist[0].toLowerCase()) + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				PlayState.SONG = Song.loadFromJson(Paths.formatToSongPath(PlayState.storyPlaylist[0].toLowerCase()) + difficulty, Paths.formatToSongPath(PlayState.storyPlaylist[0]));
				FlxG.sound.music.stop();

				LoadingState.loadAndSwitchState(new PlayState(true));
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var judgementTimings:Array<Float> = [
			22.5, // sick
			45, // good
			85, // bad
			100 // shit
		];

		var funnyAccMult:Float = 1;
		var daRating:String = "marvelous";

		var noteMs:Float = (Conductor.songPosition - strumtime) / songMultiplier;

		if(Math.abs(noteMs) > judgementTimings[0])
		{
			daRating = "sick";
			funnyAccMult = 1;
			score = 350;
		}

		if(Math.abs(noteMs) > judgementTimings[1])
		{
			daRating = "good";
			funnyAccMult = 0.8;
			score = 200;
		}

		if(Math.abs(noteMs) > judgementTimings[2])
		{
			daRating = "bad";
			funnyAccMult = 0.4;
			score = 100;
		}

		if(Math.abs(noteMs) > judgementTimings[3])
		{
			daRating = "shit";
			funnyAccMult = 0.1;
			score = 50;
			if(Options.getData('anti-mash')) health -= 0.175;
		}

		switch(daRating)
		{
			case 'marvelous':
				marvelous++;
			case 'sick':
				sicks++;
			case 'good':
				goods++;
			case 'bad':
				bads++;
			case 'shit':
				shits++;
		}
	
		songScore += score;
		funnyHitStuffsLmao += funnyAccMult;

		rating.loadGraphic(Paths.image('ui-skins/$curUISkin/ratings/' + daRating));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui-skins/$curUISkin/ratings/combo/combo'));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);

		rating.cameras = [camHUD];
		comboSpr.cameras = [camHUD];

		add(rating);

		if (!curUISkin.endsWith('-pixel'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui-skins/$curUISkin/combo/num' + Std.int(i)));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (!curUISkin.endsWith('-pixel'))
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			numScore.cameras = [camHUD];

			//if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	var justPressedArray:Array<Bool> = [];
	var releasedArray:Array<Bool> = [];
	var justReleasedArray:Array<Bool> = [];
	var heldArray:Array<Bool> = [];
	var previousReleased:Array<Bool> = [];

	private function keyShit():Void
	{
		var binds:Array<String> = Options.getData('keybinds')[keyCount - 1];
		var bindsAlt:Array<String> = Options.getData('alt-keybinds')[keyCount - 1];

		if(generatedMusic && startedCountdown)
		{
			if(!Options.getData("botplay"))
			{
				justPressedArray = [];
				justReleasedArray = [];
		
				previousReleased = releasedArray;

				releasedArray = [];
				heldArray = [];

				for(i in 0...binds.length)
				{
					justPressedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.JUST_PRESSED);
					releasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.RELEASED);
					justReleasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.JUST_RELEASED);
					heldArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.PRESSED);
	
					if(releasedArray[i] == true && keyCount == 4)
					{
						justPressedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bindsAlt[i]), FlxInputState.JUST_PRESSED);
						releasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bindsAlt[i]), FlxInputState.RELEASED);
						justReleasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bindsAlt[i]), FlxInputState.JUST_RELEASED);
						heldArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bindsAlt[i]), FlxInputState.PRESSED);
					}
				}

				// WHEN I IMPLEMENT LUA THIS WILL BE USED LOL!!!

				/*for (i in 0...justPressedArray.length) {
					if (justPressedArray[i] == true)
						executeALuaState("keyPressed", [i]);
				};
				
				for (i in 0...releasedArray.length) {
					if (releasedArray[i] == true)
						executeALuaState("keyReleased", [i]);
				};*/
				
				if(justPressedArray.contains(true) && generatedMusic)
				{
					// variables
					var possibleNotes:Array<Note> = [];
					var dontHit:Array<Note> = [];
					
					// notes you can hit lol
					notes.forEachAlive(function(note:Note) {
						note.calculateCanBeHit();

						if(note.canBeHit && note.mustPress && !note.tooLate && !note.isSustainNote)
							possibleNotes.push(note);
					});
	
					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
		
					var noteDataPossibles:Array<Bool> = [];
					var rythmArray:Array<Bool> = [];
					var noteDataTimes:Array<Float> = [];
	
					for(i in 0...keyCount)
					{
						noteDataPossibles.push(false);
						noteDataTimes.push(-1);
	
						rythmArray.push(false);
					}
		
					// if there is actual notes to hit
					if (possibleNotes.length > 0)
					{
						for(i in 0...possibleNotes.length)
						{	
							if(justPressedArray[possibleNotes[i].noteData] && !noteDataPossibles[possibleNotes[i].noteData])
							{
								noteDataPossibles[possibleNotes[i].noteData] = true;
								noteDataTimes[possibleNotes[i].noteData] = possibleNotes[i].strumTime;
	
								for(char in boyfriend.members)
								{
									char.holdTimer = 0;
								}
	
								goodNoteHit(possibleNotes[i]);
	
								if(dontHit.contains(possibleNotes[i]))
								{
									noteMiss(possibleNotes[i].noteData);
									rythmArray[i] = true;
								}
							}
						}
					}
	
					if(possibleNotes.length > 0)
					{
						for(i in 0...possibleNotes.length)
						{
							if(possibleNotes[i].strumTime == noteDataTimes[possibleNotes[i].noteData])
								goodNoteHit(possibleNotes[i]);
						}
					}
	
					if(!Options.getData("ghost-tapping"))
					{
						for(i in 0...justPressedArray.length)
						{
							if(justPressedArray[i] && !noteDataPossibles[i] && !rythmArray[i])
								noteMiss(i);
						}
					}
				}
		
				if (heldArray.contains(true) && generatedMusic)
				{
					notes.forEachAlive(function(daNote:Note)
					{
						if(heldArray[daNote.noteData] && daNote.isSustainNote && daNote.mustPress)
						{
							if(daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
							{
								for(char in boyfriend.members)
								{
									char.holdTimer = 0;
								}
	
								goodNoteHit(daNote);
							}
						}
					});
				}
		
				for(char in boyfriend.members)
				{
					if(char.animation.curAnim != null)
						if (char.holdTimer > Conductor.stepCrochet * boyfriend.json.sing_duration * 0.001 && !heldArray.contains(true))
							if (char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.name.endsWith('miss'))
								char.dance();
				}
		
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (justPressedArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
					{
						spr.playAnim('pressed');
					}

					if (releasedArray[spr.ID])
					{
						spr.playAnim('static');
					}
				});
			}
			else
			{
				notes.forEachAlive(function(note:Note) {
					if(note.shouldHit)
					{
						if(note.mustPress && note.strumTime <= Conductor.songPosition)
						{
							for(char in boyfriend.members)
							{
								char.holdTimer = 0;
							}
		
							goodNoteHit(note);
						}
					}
				});
	
				playerStrums.forEach(function(spr:StrumNote)
				{
					if(spr.animation.finished)
					{
						spr.playAnim("static");
					}
				});
	
				for(char in boyfriend.members)
				{
					if(char.animation.curAnim != null)
						if (char.holdTimer > Conductor.stepCrochet * boyfriend.json.sing_duration * 0.001)
							if (char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.name.endsWith('miss'))
								char.dance();
				}
			}
		}
	}

	function noteMiss(direction:Int = 1, ?note:Note = null):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.0475;

			if(!note.isSustainNote || note == null)
				songMisses++;

			totalNoteStuffs++;
			vocals.volume = 0;

			for(char in gf.members)
			{
				if (combo > 5 && char.animOffsets.exists('sad'))
				{
					char.playAnim('sad');
				}
			}

			combo = 0;

			songScore -= 10;

			if(!note.isSustainNote || note == null)
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			// bro fuck the stunned bull shit

			for(char in dad.members)
			{
				if(!char.specialAnim)
				{
					switch (direction)
					{
						case 0:
							boyfriend.playAnim(singAnimations[0] + 'miss', true);
						case 1:
							boyfriend.playAnim(singAnimations[1] + 'miss', true);
						case 2:
							boyfriend.playAnim(singAnimations[2] + 'miss', true);
						case 3:
							boyfriend.playAnim(singAnimations[3] + 'miss', true);
					}
				}
			}
		}
	}

	function badNoteCheck()
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!

		var binds:Array<String> = Options.getData('keybinds')[keyCount - 1];
		var bindsAlt:Array<String> = Options.getData('alt-keybinds')[keyCount - 1];

		var upP = FlxG.keys.checkStatus(FlxKey.fromString(binds[2]), FlxInputState.JUST_PRESSED) || FlxG.keys.checkStatus(FlxKey.fromString(bindsAlt[2]), FlxInputState.JUST_PRESSED);
		var rightP = FlxG.keys.checkStatus(FlxKey.fromString(binds[3]), FlxInputState.JUST_PRESSED) || FlxG.keys.checkStatus(FlxKey.fromString(bindsAlt[3]), FlxInputState.JUST_PRESSED);
		var downP = FlxG.keys.checkStatus(FlxKey.fromString(binds[1]), FlxInputState.JUST_PRESSED) || FlxG.keys.checkStatus(FlxKey.fromString(bindsAlt[1]), FlxInputState.JUST_PRESSED);
		var leftP = FlxG.keys.checkStatus(FlxKey.fromString(binds[0]), FlxInputState.JUST_PRESSED) || FlxG.keys.checkStatus(FlxKey.fromString(bindsAlt[0]), FlxInputState.JUST_PRESSED);

		if (leftP)
			noteMiss(0);
		if (downP)
			noteMiss(1);
		if (upP)
			noteMiss(2);
		if (rightP)
			noteMiss(3);
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		if (keyP)
			goodNoteHit(note);
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				popUpScore(note.strumTime);
				totalNoteStuffs++;
				combo += 1;
				hits += 1;
			}

			if (note.noteData >= 0)
				health += 0.023;
			else
				health += 0.004;

			for(char in dad.members)
			{
				if(!char.specialAnim)
				{
					switch (note.noteData)
					{
						case 0:
							boyfriend.playAnim(singAnimations[0], true);
						case 1:
							boyfriend.playAnim(singAnimations[1], true);
						case 2:
							boyfriend.playAnim(singAnimations[2], true);
						case 3:
							boyfriend.playAnim(singAnimations[3], true);
					}
				}
			}

			playerStrums.forEach(function(spr:StrumNote)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.playAnim('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();

		var gamerValue = 20 * songMultiplier;

		if(FlxG.sound.music != null)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > gamerValue
				|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > gamerValue))
			{
				resyncVocals();
			}
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;

		stage.stepHit(curStep);
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, Options.getData('downscroll') ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm, songMultiplier);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
				dad.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		// HARDCODING FOR M.I.L.F ZOOMS!
		if (curSong.toLowerCase() == 'm.i.l.f' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0)
		{
			gf.dance();
		}

		for(char in boyfriend.members)
		{
			if (!char.animation.curAnim.name.startsWith("sing"))
			{
				char.playAnim('idle');
			}
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);

			for(char in boyfriend.members)
			{
				char.specialAnim = true;
				char.heyTimer = 0.6;
			}
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		stage.beatHit(curBeat);
	}
}

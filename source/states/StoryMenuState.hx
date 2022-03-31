package states;

import util.WeekShit;
import openfl.display.BitmapData;
import mods.Mods;
import options.OptionsHandler;
import util.CoolUtil;
import util.Cache;
import game.Song;
import game.Highscore;
import ui.MenuCharacter;
import ui.MenuItem;
#if desktop
import util.Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
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

// REMEMBER TO MAKE STORY MODE WORK CORRECTLY WITH NEW MOD SYSTEM!!!
// CUZ IT'S KINDA BROKEN!!! LOL!!!

using StringTools;

class StoryMenuState extends MusicBeatState
{
	var scoreText:FlxText;

	var curDifficulty:Int = 1;

	public static var weekUnlocked:Array<Bool> = [];

	var jsonDirs:Array<String> = [];
	var jsons:Array<String> = [];

	var txtWeekTitle:FlxText;

	var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var coloredBG:FlxSprite;

	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		Cache.clearCache();
		WeekShit.init();

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat(Paths.font("vcr"), 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("vcr"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		coloredBG = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, FlxColor.WHITE);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		trace("Line 70");
		
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		loadWeeks();

		trace("Line 96");

		for (char in 0...3)
		{
			var json:WeekData = Paths.parseJson('weeks/' + jsons[curWeek]);

			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, 70, json.characters[char]);
			grpWeekCharacters.add(weekCharacterThing);
		}

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

		if(grpWeekText.members[curWeek].json.difficulties != null && grpWeekText.members[curWeek].json.difficulties.length > 0)
		{
			// go through all difficulties and add them to the list
			var diffs:Array<String> = [];

			for(diff in grpWeekText.members[curWeek].json.difficulties)
			{
				diffs.push(diff);
			}

			CoolUtil.difficulties = diffs;
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		trace("Line 124");

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y);
		sprDifficulty.frames = ui_tex;
		sprDifficulty.animation.addByPrefix('easy', 'EASY');
		sprDifficulty.animation.addByPrefix('normal', 'NORMAL');
		sprDifficulty.animation.addByPrefix('hard', 'HARD');
		sprDifficulty.animation.play('easy');

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		changeDifficulty();

		trace("Line 150");

		add(coloredBG);
		add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, coloredBG.x + coloredBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		updateText();

		trace("Line 165");

		super.create();
		currentModText = new FlxText(FlxG.width, 5, 0, "among us?", 24);
		currentModText.setFormat(Paths.font("vcr"), 24, FlxColor.WHITE, RIGHT);
		currentModText.alignment = RIGHT;

		currentModBG = new FlxSprite(currentModText.x - 6, 0).makeGraphic(1, 1, 0xFF000000);
		currentModBG.alpha = 0.6;

		var bitmapData:BitmapData = null;

        #if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

        if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/_mod_icon.png'))
        {
            bitmapData = BitmapData.fromFile(Sys.getCwd() + 'mods/$mod/_mod_icon.png');
			currentModIcon = new FlxSprite().loadGraphic(bitmapData);
		}
		else
		{
			currentModIcon = new FlxSprite().loadGraphic(Paths.image('unknown_mod', 'shared'));
		}
		#else
		currentModIcon = new FlxSprite().loadGraphic(Paths.image('unknown_mod', 'shared'));
		#end

		add(currentModBG);
		add(currentModText);
		add(currentModIcon);

		positionCurrentMod();

		var switchWarn:FlxText = new FlxText(0, currentModBG.y - (currentModBG.height + 6), 0, "[CTRL + LEFT/RIGHT to switch mods]");
		switchWarn.setFormat(Paths.font("vcr"), 16, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		switchWarn.borderSize = 2;
		add(switchWarn);

		switchWarn.x = FlxG.width - (switchWarn.width + 8);

		changeWeek();
	}
	
	// CURRENT MOD SHIT
	var currentModBG:FlxSprite;
	var currentModText:FlxText;

	var currentModIcon:FlxSprite;

	function positionCurrentMod()
	{
		currentModText.text = Paths.currentMod;
		currentModText.setPosition(FlxG.width - (currentModText.width + 6), FlxG.height - (currentModText.height + 6));

		currentModBG.makeGraphic(Math.floor(currentModText.width + 8), Math.floor(currentModText.height + 8), 0xFF000000);
		currentModBG.setPosition(FlxG.width - currentModBG.width, FlxG.height - currentModBG.height);

		var bitmapData:BitmapData = null;

        #if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

        if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/_mod_icon.png'))
        {
            bitmapData = BitmapData.fromFile(Sys.getCwd() + 'mods/$mod/_mod_icon.png');
			currentModIcon.loadGraphic(bitmapData);
		}
		else
		{
			currentModIcon.loadGraphic(Paths.image('unknown_mod', 'shared'));
		}
		#else
		currentModIcon.loadGraphic(Paths.image('unknown_mod', 'shared'));
		#end

		currentModIcon.setGraphicSize(Math.floor(currentModBG.height));
		currentModIcon.updateHitbox();

		currentModIcon.setPosition(currentModBG.x - (currentModIcon.width), currentModBG.y);
	}

	function changeMod(?change:Int = 0)
	{
		var index:Int = Mods.activeMods.indexOf(Paths.currentMod);

		index += change;

		if(index < 0)
			index = Mods.activeMods.length - 1;

		if(index > Mods.activeMods.length - 1)
			index = 0;

		Paths.currentMod = Mods.activeMods[index];

		positionCurrentMod();
		loadWeeks();

		curWeek = 0;
		changeWeek();
	}

	function loadWeeks()
	{
		for(fuck in grpWeekText.members)
		{
			fuck.kill();
			fuck.destroy();
		}

		for(fuck in grpLocks.members)
		{
			fuck.kill();
			fuck.destroy();
		}

		grpWeekText.clear();
		grpLocks.clear();
		
		jsons = [];

		#if (MODS_ALLOWED && sys)
		if(Paths.currentMod == "Friday Night Funkin'")
		{
			#if sys
			jsonDirs = sys.FileSystem.readDirectory(Sys.getCwd() + "assets/weeks/");
			#else
			jsonDirs = ["tutorial.json", "week1.json", "week2.json", "week3.json", "week4.json", "week5.json", "week6.json"];
			#end
		}
		else
			jsonDirs = [];
		#else
		#if sys
		jsonDirs = sys.FileSystem.readDirectory(Sys.getCwd() + "assets/weeks/");
		#else
		jsonDirs = ["tutorial.json", "week1.json", "week2.json", "week3.json", "week4.json", "week5.json", "week6.json"];
		#end
		#end
		
        #if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/weeks/'))
		{
			var funnyArray = sys.FileSystem.readDirectory(Sys.getCwd() + 'mods/$mod/weeks/');
			
			if(funnyArray.length > 0)
			{
				for(jsonThingy in funnyArray)
				{
					jsonDirs.push(jsonThingy);
				}
			}	
			else
			{
				#if sys
				jsonDirs = sys.FileSystem.readDirectory(Sys.getCwd() + "assets/weeks/");
				#else
				jsonDirs = ["tutorial.json", "week1.json", "week2.json", "week3.json", "week4.json", "week5.json", "week6.json"];
				#end
			}
		}
		else
		{
			#if sys
			jsonDirs = sys.FileSystem.readDirectory(Sys.getCwd() + "assets/weeks/");
			#else
			jsonDirs = ["tutorial.json", "week1.json", "week2.json", "week3.json", "week4.json", "week5.json", "week6.json"];
			#end
		}
        #end

        for(dir in jsonDirs)
        {
            if(dir.endsWith(".json"))
                jsons.push(dir.split(".json")[0]);
        }

		var weekListFile:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/weekList'));
		trace("WEEK LIST FROM TXT: " + weekListFile);

		for(week in weekListFile)
		{
			if(jsons.contains(week))
			{
				jsons.remove(week);
				jsons.insert(weekListFile.indexOf(week), week);
			}
		}

		weekUnlocked = [];
		for (i in 0...jsons.length)
		{
			var json:WeekData = Paths.parseJson('weeks/' + jsons[i]);
			
			var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

			var weekThing:MenuItem = new MenuItem(0, coloredBG.y + coloredBG.height + 10, json.texture);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);
			weekThing.antialiasing = Options.getData('anti-aliasing');
			// weekThing.updateHitbox();

			// Needs an offset thingie
			trace("COMPLETED " + json.locked_before + "??? " + WeekShit.getCompletedWeek(json.locked_before));

			var shitToPush:Bool = true;

			if (json.locked_before != null && json.locked_before.length > 0)
			{
				if(WeekShit.getCompletedWeek(json.locked_before) == true)
					shitToPush = true;
				else
					shitToPush = false;
			}

			weekUnlocked.push(shitToPush);

			if (!weekUnlocked[i])
			{
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = Options.getData('anti-aliasing');
				grpLocks.add(lock);
			}
		}
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + lerpScore;

		// FlxG.watch.addQuick('font', scoreText.font);

		difficultySelectors.visible = weekUnlocked[curWeek];

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				var ctrl = FlxG.keys.pressed.CONTROL;

				if (controls.UI_UP_P)
				{
					changeWeek(-1);
				}

				if (controls.UI_DOWN_P)
				{
					changeWeek(1);
				}

				if(ctrl && controls.UI_LEFT_P)
					changeMod(-1);
				if(ctrl && controls.UI_RIGHT_P)
					changeMod(1);

				if (controls.UI_RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.UI_LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if(!ctrl)
				{
					if (controls.UI_RIGHT_P)
						changeDifficulty(1);
					if (controls.UI_LEFT_P)
						changeDifficulty(-1);
				}
			}

			if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (weekUnlocked[curWeek])
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				grpWeekCharacters.members[1].animation.play('confirm');
				stopspamming = true;
			}

			var json:WeekData = Paths.parseJson('weeks/' + jsons[curWeek]);

			PlayState.songMultiplier = 1;
			PlayState.storyPlaylist = json.songs;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

			if(json.difficulties != null && json.difficulties.length > 0)
			{
				// go through all difficulties and add them to the list
				var diffs:Array<String> = [];

				for(diff in json.difficulties)
				{
					diffs.push(diff);
				}

				CoolUtil.difficulties = diffs;
			}

			PlayState.storyDifficulty = curDifficulty;

			var diffic = CoolUtil.getDifficultyFilePath();

			PlayState.SONG = Song.loadFromJson(Paths.formatToSongPath(PlayState.storyPlaylist[0].toLowerCase()) + diffic, Paths.formatToSongPath(PlayState.storyPlaylist[0].toLowerCase()));
			PlayState.storyWeek = curWeek;
			PlayState.storyWeekName = jsons[curWeek];

			PlayState.campaignScore = 0;

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		//sprDifficulty.offset.x = 0;

		switch (curDifficulty)
		{
			case 0:
				sprDifficulty.animation.play('easy');
				//sprDifficulty.offset.x = 20;
			case 1:
				sprDifficulty.animation.play('normal');
				//sprDifficulty.offset.x = 70;
			case 2:
				sprDifficulty.animation.play('hard');
				//sprDifficulty.offset.x = 20;
		}

		sprDifficulty.updateHitbox();

		sprDifficulty.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		sprDifficulty.y = leftArrow.y - 15;
		intendedScore = Highscore.getWeekScore(jsons[curWeek], curDifficulty);

		positionDiff();

		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function positionDiff()
	{
		leftArrow.x = grpWeekText.members[0].x + grpWeekText.members[0].width + 10;
		sprDifficulty.x = leftArrow.x + 60;
		rightArrow.x = sprDifficulty.x + sprDifficulty.width + 10;
	}

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= jsons.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = jsons.length - 1;

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && weekUnlocked[curWeek])
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		updateText();

		var json:WeekData = Paths.parseJson('weeks/' + jsons[curWeek]);
		txtWeekTitle.text = json.description.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		coloredBG.color = FlxColor.fromString(Paths.getHexCode(json.background_color));

		positionDiff();
	}

	function updateText()
	{
		var json:WeekData = Paths.parseJson('weeks/' + jsons[curWeek]);

		grpWeekCharacters.members[0].loadCharacter(json.characters[0]);
		grpWeekCharacters.members[1].loadCharacter(json.characters[1]);
		grpWeekCharacters.members[2].loadCharacter(json.characters[2]);

		txtTracklist.text = "Tracks\n";

		var stringThing:Array<String> = json.songs;

		for (i in stringThing)
		{
			txtTracklist.text += "\n" + i;
		}

		txtTracklist.text = txtTracklist.text.toUpperCase() + "\n";

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(jsons[curWeek], curDifficulty);
		#end
	}
}

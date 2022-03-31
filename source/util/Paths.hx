package util;

import lime.utils.Assets;
import openfl.media.Sound;
import flixel.system.FlxSound;
import haxe.Json;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.BitmapData;
import mods.Mods;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	public static var currentMod = "Friday Night Funkin'";

	static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static public function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static public function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static public function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		#if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/$file'))
		{
			return Sys.getCwd() + 'mods/$mod/$file';
		}
		#end

		return getPath(file, type, library);
	}

 	static public function txt(key:String, ?library:String)
	{
		#if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/$key.txt'))
		{
			return Sys.getCwd() + 'mods/$mod/$key.txt';
		}
		#end

		return getPath('$key.txt', TEXT, library);
	}

	static public function xml(key:String, ?library:String)
	{
		return getPath('$key.xml', TEXT, library);
	}

	static public function json(key:String, ?library:String)
	{
		#if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/$key.json'))
			return Sys.getCwd() + 'mods/$mod/$key.json';
		#end

		return getPath('$key.json', TEXT, library);
	}

	static public function getText(key:String)
	{
		#if (MODS_ALLOWED && sys)
		if(sys.FileSystem.exists(key))
			return sys.io.File.getContent(key);
		#end

		return Assets.getText('$key');
	}

	static public function sound(key:String, ?library:String, ?customPath:Bool = false):Dynamic
	{
		#if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		var basePath = "";

		if(!customPath)
			basePath = "sounds/";
		else
			basePath = "";

		var fullPath = basePath + key + SOUND_EXT;

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/$fullPath'))
		{
			if(Cache.getFromCache(fullPath, "sound") == null)
			{
				var sound:Sound = null;

				var modFoundFirst:String = "";
		
				var mod = Paths.currentMod;

				if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/' + fullPath))
					modFoundFirst = mod;
		
				if(modFoundFirst != "")
				{
					sound = Sound.fromFile('mods/$modFoundFirst/' + fullPath);
					Cache.addToCache(fullPath, sound, "sound");
				}
			}

			return Cache.getFromCache(fullPath, "sound");
		}
		#end

		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	static public function soundRandom(key:String, min:Int, max:Int, ?library:String):Dynamic
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	static public function music(key:String, ?library:String, ?customPath:Bool = false):Dynamic
	{
		#if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		var basePath = "";

		if(!customPath)
			basePath = "music/";
		else
			basePath = "";

		var fullPath = basePath + key + SOUND_EXT;

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/$fullPath'))
		{
			if(Cache.getFromCache(fullPath, "music") == null)
			{
				var sound:Sound = null;

				var modFoundFirst:String = "";
		
				var mod = Paths.currentMod;

				if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/' + fullPath))
					modFoundFirst = mod;
		
				if(modFoundFirst != "")
				{
					sound = Sound.fromFile('mods/$modFoundFirst/' + fullPath);
					Cache.addToCache(fullPath, sound, "music");
				}
			}

			return Cache.getFromCache(fullPath, "music");
		}
		#end

		if(customPath)
			return getPath('$key.$SOUND_EXT', MUSIC, library);

		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	static public function voices(song:String):Dynamic
	{
		#if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		var basePath = 'songs/';
		var fullPath = basePath + ${song.toLowerCase()} + '/Voices.' + SOUND_EXT;

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/$fullPath'))
		{
			if(Cache.getFromCache(fullPath, "song") == null)
			{
				var sound:Sound = null;

				var modFoundFirst:String = "";
		
				var mod = Paths.currentMod;

				if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/' + fullPath))
					modFoundFirst = mod;
		
				if(modFoundFirst != "")
				{
					sound = Sound.fromFile('mods/$modFoundFirst/' + fullPath);
					Cache.addToCache(fullPath, sound, "song");
				}
			}

			return Cache.getFromCache(fullPath, "song");
		}
		#end

		return 'songs:assets/songs/${song.toLowerCase()}/Voices.$SOUND_EXT';
	}

	static public function inst(song:String):Dynamic
	{
		#if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		var basePath = 'songs/';
		var fullPath = basePath + ${song.toLowerCase()} + '/Inst.' + SOUND_EXT;

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/$fullPath'))
		{
			if(Cache.getFromCache(fullPath, "song") == null)
			{
				var sound:Sound = null;

				var modFoundFirst:String = "";
		
				for(mod in Mods.activeMods)
				{
					if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/' + fullPath))
						modFoundFirst = mod;
				}
		
				if(modFoundFirst != "")
				{
					sound = Sound.fromFile('mods/$modFoundFirst/' + fullPath);
					Cache.addToCache(fullPath, sound, "song");
				}
			}

			return Cache.getFromCache(fullPath, "song");
		}
		#end

		return 'songs:assets/songs/${song.toLowerCase()}/Inst.$SOUND_EXT';
	}

	static public function image(key:String, ?library:String, ?customPath:Bool = false):Dynamic
	{
		#if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		var modPng = key;

		if (!customPath)
			modPng = "mods/" + mod + "/images/" + modPng;
		else
			modPng = "mods/" + mod + "/" + modPng;

		if(sys.FileSystem.exists(Sys.getCwd() + modPng + ".png"))
		{
			if(Cache.getFromCache(modPng, "image") == null)
			{
				var graphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(Sys.getCwd() + modPng + ".png"), false, modPng, false);
				graphic.destroyOnNoUse = false;

				Cache.addToCache(modPng, graphic, "image");
			}
			
			return Cache.getFromCache(modPng, "image");
		}
		#end

		if(customPath)
			return getPath('$key.png', IMAGE, library);

		return getPath('images/$key.png', IMAGE, library);
	}

	static public function font(key:String)
	{
		#if (MODS_ALLOWED && sys)
		var mod = Paths.currentMod;

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/fonts/$key.ttf'))
			return Sys.getCwd() + 'mods/$mod/fonts/$key.ttf';

		if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/fonts/$key.otf'))
			return Sys.getCwd() + 'mods/$mod/fonts/$key.otf';
		#end

		if(Assets.exists('assets/fonts/$key.ttf'))
			return 'assets/fonts/$key.ttf';

		if(Assets.exists('assets/fonts/$key.otf'))
			return 'assets/fonts/$key.otf';

		return null;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String, ?customPath:Bool = false)
	{
		var xmlData:Dynamic = null;

		if(!customPath)
			xmlData = getText(file('images/$key.xml', library));
		else
			xmlData = getText(file('$key.xml', library));

		if(customPath)
		{
			return FlxAtlasFrames.fromSparrow(image(key, library, customPath), xmlData);
		}

		return FlxAtlasFrames.fromSparrow(image(key, library), xmlData);
	}

	inline static public function getPackerAtlas(key:String, ?library:String, ?customPath:Bool = false)
	{
		var txtData:Dynamic = null;

		if(!customPath)
			txtData = getText(file('images/$key.txt', library));
		else
			txtData = getText(file('$key.txt', library));

		if(customPath)
			return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, customPath), txtData);

		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), txtData);
	}

	static public function parseJson(key:String, ?customPath:Bool = false):Dynamic
	{
		var json:Dynamic = null;

		#if (MODS_ALLOWED && sys)
		if(!customPath)
		{
			var mod = Paths.currentMod;

			if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$mod/$key.json'))
				return Json.parse(sys.io.File.getContent(Sys.getCwd() + 'mods/$mod/$key.json'));
		}
		else
		{
			if(sys.FileSystem.exists(Sys.getCwd() + 'mods/$key.json'))
				return Json.parse(sys.io.File.getContent(Sys.getCwd() + 'mods/$key.json'));
		}
		#end
		
		if(Assets.exists('assets/$key.json'))
			return Json.parse(Assets.getText('assets/$key.json'));

		return null;
	}

	inline static public function getHexCode(code:String)
	{
		if(!code.contains("#"))
			return "#" + code;

		return code;
	}

	inline static public function formatToSongPath(path:String) {
		return path.toLowerCase();//.replace(' ', '-');
	}

	inline public static function openURL(url:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [url, "&"]);
		#else
		FlxG.openURL(url);
		#end
	}
}

package options;

import flixel.FlxSprite;
import substates.MusicBeatSubstate;

class GraphicsSubstate extends BaseOptionsMenu
{
    override public function create()
    {
        var option:Option = new Option(
            "Anti-Aliasing",
            "Disabling anti-aliasing to get a performance boost, at the cost of sharper looking graphics.",
            "anti-aliasing",
            "bool"
        );
        addOption(option);

        var option:Option = new Option(
            "Optimization",
            "Enabling optimization will cause every background and character to disappear.\nThis will improve performance and loading times.",
            "optimization",
            "bool"
        );
        addOption(option);

        var option:Option = new Option(
            "FPS Cap",
            "Adjust how high or low your FPS can go and see how it feels!",
            "fps-cap",
            "int",
            [10, 1000],
            1
        );
        addOption(option);

        var option:Option = new Option(
            "Note Splashes",
            "Disabling this will prevent the notes from making a firework-like effect\nwhen hitting a note and getting a \"SiCK!!\"",
            "note-splashes",
            "bool"
        );
        addOption(option);

        var option:Option = new Option(
            "Camera Zooms",
            "Disabling this will prevent the camera from zooming to the beat.",
            "camera-zooms",
            "bool"
        );
        addOption(option);

        var option:Option = new Option(
            "UI Skin",
            "Change the skin of your notes and ratings.",
            "ui-skin",
            "string",
            UISkinList.skins
        );
        addOption(option);

		super.create();
    }
}
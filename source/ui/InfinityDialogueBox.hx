package ui;

import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;

using StringTools;

typedef DialogueData = {
    var box_skin:String;
    var font:String;
    var font_size:Int;
    var dialogue:Array<DialogueContent>;
};

typedef DialogueContent = {
    var character:String;
    var text:String;
    var speed:Float;
};

typedef DialogueBoxData = {
    var open_anim:Array<Dynamic>;
    var idle_anim:Array<Dynamic>;
    var angry_open_anim:Array<Dynamic>;
    var angry_idle_anim:Array<Dynamic>;
    var position:Array<Float>;
    var scale:Float;
};

class InfinityDialogueBox extends FlxSpriteGroup
{
    public var finishThing:Void->Void;

    public var dialogueJson:DialogueData;
    public var dialogueBoxJson:DialogueBoxData;

    public var box:FlxSprite;
    public var skin:String = "default";

    public var alphabet:Alphabet;

    public var cover:FlxSprite;

    public var dialogueOpened:Bool = false;

    public var dialogue:Array<DialogueContent> = [];

    public function new(json:DialogueData, ?skin:String = "default")
    {
        super();

        this.dialogueJson = json;
        this.skin = skin;

        cover = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
        cover.alpha = 0;
        add(cover);

        dialogueBoxJson = Paths.parseJson('images/dialogue/boxes/$skin/config');
        trace("we got the json");

        // dialogue box
        box = new FlxSprite();
        trace("we make the box");

        box.frames = Paths.getSparrowAtlas('dialogue/boxes/$skin/assets');
        trace("we got the box's frames");
        addBoxAnims();
        trace("we add the box's anims");
        box.animation.play('idle');

        box.scale.set(dialogueBoxJson.scale, dialogueBoxJson.scale);
        box.updateHitbox();

        box.screenCenter(X);
        box.y = FlxG.height - (box.height * 1.1);
        trace("pos the box");
        box.x += dialogueBoxJson.position[0];
        box.y += dialogueBoxJson.position[1];
        trace("pos the box again");
        box.visible = false;
        add(box);

        dialogue = [];
        dialogue = dialogueJson.dialogue;
        trace(dialogue);

        trace("FIRST LINE OF DIALOGUE:" + dialogue[0].text);
        renderDialogue("");
        alphabet.visible = false;
        trace("ALPHABET BULLSHIT EXISTS!");

        FlxTween.tween(cover, {alpha: 0.7}, 1, {
            ease: FlxEase.cubeInOut,
            startDelay: 0.5
        });
        trace("fuck!");

        // REMEMBER TO FIX THIS!!! IT CRASHES FOR SOME REASON!

		new FlxTimer().start(1, function(tmr:FlxTimer){
            dialogueOpened = true;
            trace("fuck 2!");

            box.visible = true;
            trace("fuck 3!");
            box.animation.play('open');
            trace("fuck 4!");

            new FlxTimer().start(0.15, function(tmr:FlxTimer){
                alphabet.visible = true;
                alphabet.changeText(dialogue[0].text, dialogue[0].speed);
                trace("fuck 5!");
            });
        });
    }

    function addBoxAnims()
    {
        // standard version

        var anim = dialogueBoxJson.open_anim;
        trace(anim);
        box.animation.addByPrefix('open', anim[0], anim[1], anim[2]);

        var anim = dialogueBoxJson.idle_anim;
        trace(anim);
        box.animation.addByPrefix('idle', anim[0], anim[1], anim[2]);

        // angry version
        var anim = dialogueBoxJson.angry_open_anim;
        trace(anim);
        box.animation.addByPrefix('angry-open', anim[0], anim[1], anim[2]);

        var anim = dialogueBoxJson.angry_idle_anim;
        trace(anim);
        box.animation.addByPrefix('angry-idle', anim[0], anim[1], anim[2]);
    }

    var closing:Bool = false;

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if(box.animation.curAnim != null)
        {
            if(dialogueOpened)
            {
                if(box.animation.curAnim.name.contains('open') && box.animation.curAnim.finished)
                    box.animation.play('idle');
            }
            
            if(closing)
            {
                if(box.animation.curAnim.name.contains('open') && box.animation.curAnim.curFrame == 0)
                    box.visible = false;
            }
        }

        if(FlxG.keys.justPressed.ANY && !FlxG.keys.justPressed.SHIFT && dialogueOpened)
        {
            nextDialogue();
        }

        if(!closing && FlxG.keys.justPressed.SHIFT)
        {
            FlxG.sound.play(Paths.sound('clickText')); // will use actual sound when i get one
            endDialogue();
        }
    }

    function nextDialogue()
    {
        FlxG.sound.play(Paths.sound('clickText')); // will use actual sound when i get one

        if(dialogue[1] == null && dialogue[0] != null)
        {
            endDialogue();
        }
        else
        {
            dialogue.remove(dialogue[0]);

            alphabet.killTheTimer();
            alphabet.kill();
            alphabet.destroy();

            renderDialogue();
        }
    }

    function renderDialogue(?text:String)
    {
        if(text == null)
            text = dialogue[0].text;

        alphabet = new Alphabet(0, box.y + 60, text, false, true, dialogue[0].speed, 0.7);
        alphabet.x += box.x;
        add(alphabet);
    }

    function endDialogue()
    {
        dialogue = [];

        dialogueOpened = false;
        closing = true;
        alphabet.visible = false;

        box.animation.play('open', true, true);
        FlxTween.tween(cover, {alpha: 0}, 1, {
            ease: FlxEase.cubeInOut,
            onComplete: function(a){
                finishThing();
                kill();
            }
        });
    }
}
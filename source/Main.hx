package;

import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;

class Main extends Sprite
{
    public static var instance:Main;

    var gameWidth:Int = 1280;
    var gameHeight:Int = 720;
    var framerate:Int = 60;

    var initialState:Class<FlxState> = TitleState;

    public static function main()
    {
        Lib.current.addChild(new Main());
    }

    public function new()
    {
        super();
        instance = this;

        if (stage != null)
            init();
        else
            addEventListener(Event.ADDED_TO_STAGE, init);
    }

    function init(?e:Event)
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);

        CrashHandler.init();

        #if android
        LoadingScreen.start(this, finishSetup);
        #else
        finishSetup();
        #end
    }

    function finishSetup()
    {
        addChild(new FlxGame(
            gameWidth,
            gameHeight,
            initialState,
            framerate,
            framerate,
            true,
            false
        ));
    }
}
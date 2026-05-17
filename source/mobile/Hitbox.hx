package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class Hitbox extends FlxSpriteGroup
{
	public var buttonLeft:HitboxButton;
	public var buttonDown:HitboxButton;
	public var buttonUp:HitboxButton;
	public var buttonRight:HitboxButton;

	public var LEFT(get, never):Bool;
	public var DOWN(get, never):Bool;
	public var UP(get, never):Bool;
	public var RIGHT(get, never):Bool;

	public var LEFT_P(get, never):Bool;
	public var DOWN_P(get, never):Bool;
	public var UP_P(get, never):Bool;
	public var RIGHT_P(get, never):Bool;

	public var LEFT_R(get, never):Bool;
	public var DOWN_R(get, never):Bool;
	public var UP_R(get, never):Bool;
	public var RIGHT_R(get, never):Bool;

	public function new(alpha:Float = 0.6)
	{
		super();
		scrollFactor.set(0, 0);

		var bW:Int = Std.int(FlxG.width / 4);
		var bH:Int = Std.int(FlxG.height / 4);
		var bY:Int = FlxG.height - bH;

		buttonLeft  = new HitboxButton(0,        bY, bW, bH, FlxColor.fromRGB(194, 114, 255));
		buttonDown  = new HitboxButton(bW,       bY, bW, bH, FlxColor.fromRGB(0,   255, 255));
		buttonUp    = new HitboxButton(bW * 2,   bY, bW, bH, FlxColor.fromRGB(18,  250, 5));
		buttonRight = new HitboxButton(bW * 3,   bY, bW, bH, FlxColor.fromRGB(249, 57,  63));

		for (btn in [buttonLeft, buttonDown, buttonUp, buttonRight])
		{
			btn.alpha = alpha;
			add(btn);
		}
	}

	override public function update(elapsed:Float):Void
	{
		buttonLeft.updateState();
		buttonDown.updateState();
		buttonUp.updateState();
		buttonRight.updateState();
		super.update(elapsed);
	}

	inline function get_LEFT():Bool    return buttonLeft.pressed;
	inline function get_DOWN():Bool    return buttonDown.pressed;
	inline function get_UP():Bool      return buttonUp.pressed;
	inline function get_RIGHT():Bool   return buttonRight.pressed;

	inline function get_LEFT_P():Bool  return buttonLeft.justPressed;
	inline function get_DOWN_P():Bool  return buttonDown.justPressed;
	inline function get_UP_P():Bool    return buttonUp.justPressed;
	inline function get_RIGHT_P():Bool return buttonRight.justPressed;

	inline function get_LEFT_R():Bool  return buttonLeft.justReleased;
	inline function get_DOWN_R():Bool  return buttonDown.justReleased;
	inline function get_UP_R():Bool    return buttonUp.justReleased;
	inline function get_RIGHT_R():Bool return buttonRight.justReleased;
}

class HitboxButton extends FlxSprite
{
	public var pressed:Bool      = false;
	public var justPressed:Bool  = false;
	public var justReleased:Bool = false;

	var _prevPressed:Bool = false;
	var _pressAlpha:Float;
	var _idleAlpha:Float  = 0.6;

	public function new(x:Float, y:Float, w:Int, h:Int, color:FlxColor)
	{
		super(x, y);
		makeGraphic(w, h, color);
		scrollFactor.set(0, 0);
		_pressAlpha = 1.0;
	}

	public function updateState():Void
	{
		_prevPressed = pressed;
		pressed      = false;

		var pt:FlxPoint = FlxPoint.weak();
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed)
			{
				pt.set(touch.viewX, touch.viewY);
				if (overlapsPoint(pt, true))
				{
					pressed = true;
					break;
				}
			}
		}
		pt.putWeak();

		justPressed  = pressed  && !_prevPressed;
		justReleased = !pressed && _prevPressed;
		alpha        = pressed ? _pressAlpha : _idleAlpha;
	}

	public function setAlphas(idle:Float, press:Float):Void
	{
		_idleAlpha  = idle;
		_pressAlpha = press;
		alpha       = _idleAlpha;
	}
}

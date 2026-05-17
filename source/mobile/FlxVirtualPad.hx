package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;

class FlxVirtualPad extends FlxSpriteGroup
{
	public var buttonLeft:VirtualButton;
	public var buttonDown:VirtualButton;
	public var buttonUp:VirtualButton;
	public var buttonRight:VirtualButton;
	public var buttonA:VirtualButton;
	public var buttonB:VirtualButton;

	public var LEFT(get, never):Bool;
	public var DOWN(get, never):Bool;
	public var UP(get, never):Bool;
	public var RIGHT(get, never):Bool;
	public var A(get, never):Bool;
	public var B(get, never):Bool;

	public var LEFT_P(get, never):Bool;
	public var DOWN_P(get, never):Bool;
	public var UP_P(get, never):Bool;
	public var RIGHT_P(get, never):Bool;
	public var A_P(get, never):Bool;
	public var B_P(get, never):Bool;

	public var LEFT_R(get, never):Bool;
	public var DOWN_R(get, never):Bool;
	public var UP_R(get, never):Bool;
	public var RIGHT_R(get, never):Bool;

	public function new(alpha:Float = 0.75)
	{
		super();

		scrollFactor.set(0, 0);

		final sc:Float  = 0.5;
		final bW:Float  = 396 * sc;
		final bH:Float  = 127 * sc;
		final bY:Float  = FlxG.height - bH - 8;
		final sx:Float  = (FlxG.width - bW * 6) / 2;

		buttonB     = new VirtualButton(sx,          bY, 'b',     sc, alpha);
		buttonLeft  = new VirtualButton(sx + bW,     bY, 'left',  sc, alpha);
		buttonDown  = new VirtualButton(sx + bW * 2, bY, 'down',  sc, alpha);
		buttonUp    = new VirtualButton(sx + bW * 3, bY, 'up',    sc, alpha);
		buttonRight = new VirtualButton(sx + bW * 4, bY, 'right', sc, alpha);
		buttonA     = new VirtualButton(sx + bW * 5, bY, 'a',     sc, alpha);

		add(buttonB);
		add(buttonLeft);
		add(buttonDown);
		add(buttonUp);
		add(buttonRight);
		add(buttonA);
	}

	override public function update(elapsed:Float):Void
	{
		buttonLeft.updateState();
		buttonDown.updateState();
		buttonUp.updateState();
		buttonRight.updateState();
		buttonA.updateState();
		buttonB.updateState();
		super.update(elapsed);
	}

	inline function get_LEFT():Bool    return buttonLeft.pressed;
	inline function get_DOWN():Bool    return buttonDown.pressed;
	inline function get_UP():Bool      return buttonUp.pressed;
	inline function get_RIGHT():Bool   return buttonRight.pressed;
	inline function get_A():Bool       return buttonA.pressed;
	inline function get_B():Bool       return buttonB.pressed;

	inline function get_LEFT_P():Bool  return buttonLeft.justPressed;
	inline function get_DOWN_P():Bool  return buttonDown.justPressed;
	inline function get_UP_P():Bool    return buttonUp.justPressed;
	inline function get_RIGHT_P():Bool return buttonRight.justPressed;
	inline function get_A_P():Bool     return buttonA.justPressed;
	inline function get_B_P():Bool     return buttonB.justPressed;

	inline function get_LEFT_R():Bool  return buttonLeft.justReleased;
	inline function get_DOWN_R():Bool  return buttonDown.justReleased;
	inline function get_UP_R():Bool    return buttonUp.justReleased;
	inline function get_RIGHT_R():Bool return buttonRight.justReleased;
}

class VirtualButton extends FlxSprite
{
	public var pressed:Bool      = false;
	public var justPressed:Bool  = false;
	public var justReleased:Bool = false;

	var _prevPressed:Bool  = false;
	var _idleAlpha:Float;
	var _animName:String;

	static var _touchPoint:FlxPoint = FlxPoint.get();

	public function new(x:Float, y:Float, animName:String, sc:Float, idleAlpha:Float)
	{
		super(x, y);

		_animName  = animName;
		_idleAlpha = idleAlpha;

		frames = Paths.getSparrowAtlas('virtualPad', 'shared');
		animation.addByPrefix('idle', animName, 24, true);
		animation.play('idle');

		scale.set(sc, sc);
		updateHitbox();
		scrollFactor.set(0, 0);
		alpha = _idleAlpha;
	}

	public function updateState():Void
	{
		_prevPressed = pressed;
		pressed      = false;

		for (touch in FlxG.touches.list)
		{
			if (touch.pressed)
			{
				_touchPoint.set(touch.screenX, touch.screenY);
				if (overlapsPoint(_touchPoint, true))
				{
					pressed = true;
					break;
				}
			}
		}

		justPressed  = pressed  && !_prevPressed;
		justReleased = !pressed && _prevPressed;
		alpha        = pressed ? 1.0 : _idleAlpha;
	}

	override public function destroy():Void
	{
		_touchPoint = null;
		super.destroy();
	}
}

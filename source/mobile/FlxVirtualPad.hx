package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;

enum VirtualDPadMode
{
	FULL;
	UP_DOWN;
	LEFT_RIGHT;
	NONE;
}

enum VirtualActionMode
{
	A_B;
	A;
	NONE;
}

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

	static inline final SC:Float  = 0.5;
	static inline final BW:Float  = 396 * SC;
	static inline final BH:Float  = 127 * SC;
	static inline final PAD:Float = 8;

	public function new(dpad:VirtualDPadMode = FULL, action:VirtualActionMode = A_B, alpha:Float = 0.75)
	{
		super();
		scrollFactor.set(0, 0);

		switch (dpad)
		{
			case FULL:
				final sx:Float = (FlxG.width - BW * 4) / 2;
				final by:Float = FlxG.height - BH - PAD;
				buttonLeft  = _make(sx,          by, 'left',  alpha);
				buttonDown  = _make(sx + BW,     by, 'down',  alpha);
				buttonUp    = _make(sx + BW * 2, by, 'up',    alpha);
				buttonRight = _make(sx + BW * 3, by, 'right', alpha);

			case UP_DOWN:
				final bx:Float = PAD;
				buttonDown = _make(bx, FlxG.height - BH - PAD,          'down', alpha);
				buttonUp   = _make(bx, FlxG.height - BH * 2 - PAD * 2, 'up',   alpha);

			case LEFT_RIGHT:
				final by:Float = FlxG.height - BH - PAD;
				buttonLeft  = _make(PAD,          by, 'left',  alpha);
				buttonRight = _make(PAD + BW + 4, by, 'right', alpha);

			case NONE:
		}

		switch (action)
		{
			case A_B:
				final ax:Float = FlxG.width - BW - PAD;
				buttonA = _make(ax, FlxG.height - BH - PAD,          'a', alpha);
				buttonB = _make(ax, FlxG.height - BH * 2 - PAD * 2, 'b', alpha);

			case A:
				buttonA = _make(FlxG.width - BW - PAD, FlxG.height - BH - PAD, 'a', alpha);

			case NONE:
		}
	}

	function _make(x:Float, y:Float, anim:String, alpha:Float):VirtualButton
	{
		var btn = new VirtualButton(x, y, anim, SC, alpha);
		add(btn);
		return btn;
	}

	override public function update(elapsed:Float):Void
	{
		if (buttonLeft  != null) buttonLeft.updateState();
		if (buttonDown  != null) buttonDown.updateState();
		if (buttonUp    != null) buttonUp.updateState();
		if (buttonRight != null) buttonRight.updateState();
		if (buttonA     != null) buttonA.updateState();
		if (buttonB     != null) buttonB.updateState();
		super.update(elapsed);
	}

	inline function get_LEFT():Bool    return buttonLeft  != null && buttonLeft.pressed;
	inline function get_DOWN():Bool    return buttonDown  != null && buttonDown.pressed;
	inline function get_UP():Bool      return buttonUp    != null && buttonUp.pressed;
	inline function get_RIGHT():Bool   return buttonRight != null && buttonRight.pressed;
	inline function get_A():Bool       return buttonA     != null && buttonA.pressed;
	inline function get_B():Bool       return buttonB     != null && buttonB.pressed;

	inline function get_LEFT_P():Bool  return buttonLeft  != null && buttonLeft.justPressed;
	inline function get_DOWN_P():Bool  return buttonDown  != null && buttonDown.justPressed;
	inline function get_UP_P():Bool    return buttonUp    != null && buttonUp.justPressed;
	inline function get_RIGHT_P():Bool return buttonRight != null && buttonRight.justPressed;
	inline function get_A_P():Bool     return buttonA     != null && buttonA.justPressed;
	inline function get_B_P():Bool     return buttonB     != null && buttonB.justPressed;

	inline function get_LEFT_R():Bool  return buttonLeft  != null && buttonLeft.justReleased;
	inline function get_DOWN_R():Bool  return buttonDown  != null && buttonDown.justReleased;
	inline function get_UP_R():Bool    return buttonUp    != null && buttonUp.justReleased;
	inline function get_RIGHT_R():Bool return buttonRight != null && buttonRight.justReleased;
}

class VirtualButton extends FlxSprite
{
	public var pressed:Bool      = false;
	public var justPressed:Bool  = false;
	public var justReleased:Bool = false;

	var _prevPressed:Bool = false;
	var _idleAlpha:Float;

	static var _pt:FlxPoint = FlxPoint.get();

	public function new(x:Float, y:Float, animName:String, sc:Float, idleAlpha:Float)
	{
		super(x, y);
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
				_pt.set(touch.viewX, touch.viewY);
				if (overlapsPoint(_pt, true))
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
		_pt = null;
		super.destroy();
	}
}

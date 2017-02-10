package objects;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.system.debug.watch.Tracker;
import flixel.system.FlxSound;

class Player extends FlxSprite {
	private static inline var ACCELERATION:Int = 10;
	private static inline var VELOCITY:Int = 60;
	private static inline var DRAG:Int = 220;
	private static inline var GRAVITY:Int = 600;
	private static inline var JUMP_FORCE:Int = -280;
	private static inline var WALK_SPEED:Int = 140;
	private static inline var ROOT_SPEED:Int = 20;
	private static inline var BUFFER_SPEED:Int = 200;
	private static inline var MAX_SPEED:Int = 300;
	private static inline var BOUNCE_SPEED:Int = 250;
	private static inline var FALLING_SPEED:Int = 300;
	private static inline var SPRITE_WIDTH:Int = 300;
	private static inline var SPRITE_HEIGHT:Int = 164;
	private static inline var SLIME_WALK:FlxGraphicAsset = AssetPaths.slime_walk__png;
	private static inline var SLIME_ROOT:FlxGraphicAsset = AssetPaths.slime_root__png;

	private var slideSound:FlxSound;

	private var startHealth:Float = Reg.health;
	private var invincibility:Int = 0;
	private var justBounced:Bool = false;

	public var impactSpeed:FlxPoint = new FlxPoint();
	public var rootDuration:Int = 100;
	public var rootTime:Int = Reg.rootTime;
	public var rooted:Bool = false;
	public var wallJumping:Bool = false;
	public var noRoot = false;
	public var direction:Int = 1;
	public var stationary:Bool = false;
	public function new() {
		super();
		loadGraphic(SLIME_WALK, true, SPRITE_WIDTH, SPRITE_HEIGHT);

		//slideSound = FlxG.sound.load(AssetPaths.slide__wav);

		animation.add("idle", [0]);
		animation.add("walk", [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14], 16);
		animation.add("skid", [0]);
		animation.add("jump", [9]);
		animation.add("fall", [14]);
		animation.add("dead", [1]);
		animation.add("hurt", [1]);
		animation.add("rooted", [0], 3);
		animation.add("wall", [6]);

		setSize(28, 15);
		scale.set(0.2, 0.2);
		//updateHitbox();
		origin.set(80, 40);
		offset.set(75, 44);

		health = startHealth;
		drag.x = DRAG;
		acceleration.y = GRAVITY;
		maxVelocity.set(WALK_SPEED, FALLING_SPEED);

		FlxG.debugger.addTrackerProfile(new TrackerProfile(Player, ['rooted', 'rootTime', 'direction', 'velocity', 'impactSpeed'], []));
		FlxG.debugger.track(this, "player");
	}

	private function move() {
		acceleration.x = 0;
		acceleration.y = GRAVITY;

		if (FlxG.keys.pressed.LEFT && !rooted) {
			//offset.set(35, 34);
			flipX = true;
			direction = -1;
			velocity.x -= VELOCITY - ACCELERATION;
			acceleration.x -= ACCELERATION;
		} else if (FlxG.keys.pressed.RIGHT && !rooted) {
			//offset.set(74, 34);
			flipX = false;
			direction = 1;
			velocity.x += VELOCITY - ACCELERATION;
			acceleration.x += ACCELERATION;
		}

		if (velocity.x != 0) {
			if (isTouching(FlxObject.WALL)) {
				if (impactSpeed.x == 0) {
					impactSpeed.x = velocity.x;
					velocity.y -= Math.abs(velocity.x) * 3;
				}
			} else {
				impactSpeed.x = 0;
			}
		}

		if (velocity.y == 0) {
			// bouncing
			if (impactSpeed.y > BOUNCE_SPEED) {
				if (!justBounced) {
					velocity.y = -impactSpeed.y;
					impactSpeed.y = 0;
					justBounced = true;
				} else {
					justBounced = false;
				}
			}

			if (FlxG.keys.justPressed.C && (isTouching(FlxObject.FLOOR) || rooted)) {
				velocity.y = JUMP_FORCE;
				rooted = false;
			}

			if (FlxG.keys.pressed.X && maxVelocity.x < MAX_SPEED) {
				maxVelocity.x += ROOT_SPEED;
			}

			if (velocity.x < WALK_SPEED && maxVelocity.x > BUFFER_SPEED) {
				maxVelocity.x = WALK_SPEED;
			}
		} else { // if velocity.y != 0
			impactSpeed.y = velocity.y;
		}

		if ((velocity.y < 0) && (FlxG.keys.justReleased.C)) {
			// variable jump height
			velocity.y = velocity.y * 0.5;
		}

		if (FlxG.keys.pressed.X && isTouching(FlxObject.WALL)) {
			rootCharacter(FlxObject.WALL);
		}
		if (FlxG.keys.pressed.X && isTouching(FlxObject.ANY)) {
			rootCharacter();
		}

		if (rooted) {
			// wall jumping
			velocity.y = 0;
			acceleration.y = 0;
			if (FlxG.keys.pressed.DOWN) {
				rooted = false;
			}
			if (rootTime > 0) {
				rootTime--;
				Reg.rootTime = rootTime;
			} else {
				rooted = false;
				stationary = false;
			}

			if (velocity.x == 0) {
				stationary = true;
			} else {
				stationary = false;
			}
		} else {
			wallJumping = false;
			if (rootTime < 100) {
				rootTime++;
				Reg.rootTime = rootTime;
			}
		}

		if (x < 0)
			x = 0;

		Reg.playerX = x;
	}

	public function hit() {
		if (invincibility <= 0) {
			hurt(10);
			// velocity.y = -velocity.y * 2;
			velocity.y = JUMP_FORCE / 2;
			velocity.x = -velocity.x * 2;
			Reg.health -= 10;
			invincibility = 200;
		}
	}

	private function rootCharacter(wall:Int = 0) {
		if (!noRoot) {
			//slideSound.play();
			// trying out speeding up sliding
			velocity.x = velocity.x * 2;
			rooted = true;
		}
		if (wall == FlxObject.WALL) {
			wallJumping = true;
		}
	}

	private function animate() {
		if ((velocity.y <= 0) && (!isTouching(FlxObject.FLOOR))) {
			animation.play("jump");
		} else if (velocity.y > 0) {
			animation.play("fall");
		} else if (velocity.x == 0) {
			animation.play("idle");
		} else {
			if (FlxMath.signOf(velocity.x) != FlxMath.signOf(direction)) {
				animation.play("skid");
			} else {
				animation.play("walk");
			}
		}
		if (rooted) {
			if (wallJumping) {
				animation.play("wall");
			} else {
				animation.play("rooted");
				//scale.set(1, 0.5);
				// var rect = FlxRect.get();
				// rect.set(x, y, width*2, height);
				// clipRect(rect);
			}
		}
	}

	override public function update(elapsed:Float):Void {
		move();
		animate();

		if (invincibility > 0) {
			invincibility -= 1;

			if (invincibility % 7 == 0) {
				alpha = 0.2;
			} else {
				alpha = 1;
			}
		} else {
			alpha = 1;
		}

		super.update(elapsed);
	}
	
}
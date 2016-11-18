package utils;

import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.tile.FlxTilemap;
import flixel.tile.FlxTile;
import flixel.FlxObject;
import flixel.FlxG;
import objects.Enemy;
import objects.Player;
import objects.Door;
import objects.HiddenSpike;
import objects.FallingBlock;
import states.PlayState;


class LevelLoader {
	public static var levelState:PlayState;
	public static var levelName:String;
	private static inline var TILE_SIZE:Int = 32;
	public static function load(state:PlayState, level:String) {
		levelState = state;
		levelName = level;
		var tiledMap = new TiledMap("assets/data/" + level + ".tmx");
		var mainLayer:TiledTileLayer = cast tiledMap.getLayer("foreground");

		state.map = new FlxTilemap();
		state.map.loadMapFromArray(mainLayer.tileArray,
			tiledMap.width,
			tiledMap.height,
			AssetPaths.tinytiles__png,
			TILE_SIZE, TILE_SIZE, 1);

		state.map.setTileProperties(2, FlxObject.ANY, collideStone, Player, 10);
		state.map.setTileProperties(74, FlxObject.ANY, collideSpikes, Player, 3);

		var backLayer:TiledTileLayer = cast tiledMap.getLayer("background");

		var backMap = new FlxTilemap();
		backMap.loadMapFromArray(backLayer.tileArray,
			tiledMap.width,
			tiledMap.height,
			AssetPaths.tinytiles__png,
			TILE_SIZE, TILE_SIZE, 1);
		backMap.solid = false;

		state.add(backMap);
		state.add(state.map);

		for (enemy in getLevelObjects(tiledMap, "enemies"))
			state.enemies.add(new Enemy(enemy.x, enemy.y - 32));

		for (spike in getLevelObjects(tiledMap, "hidden_spikes"))
			state.spikes.add(new HiddenSpike(spike.x, spike.y - 32));

		for (block in getLevelObjects(tiledMap, "falling_blocks"))
			state.blocks.add(new FallingBlock(block.x, block.y - 32));
		
		var playerPos:TiledObject = getLevelObjects(tiledMap, "player")[0];
		state.player.setPosition(playerPos.x, playerPos.y - TILE_SIZE);


		for (door in getLevelObjects(tiledMap, "doors"))
			state.doors.add(new Door(door));
	}

	private static function collideStone(tile:FlxObject, player:FlxObject):Void {
		//Player.noRoot = true;
		levelState.player.noRoot = true;
	}

	private static function collideSpikes(tile:FlxObject, player:FlxObject):Void {
		// complicated logic to try and make spikes a little more fair
		if ((player.x + player.width > tile.x + tile.width && player.x + 20 < tile.x + tile.width) ||
			(player.x < tile.x && player.x + 4 > tile.x)) {
			levelState.player.hit();
		}
	}

	public static function getLevelObjects(map:TiledMap, layer:String):Array<TiledObject> {
		if ((map != null) && (map.getLayer(layer) != null)) {
			var objLayer:TiledObjectLayer = cast map.getLayer(layer);
			return objLayer.objects;
		} else {
			trace("Object layer " + layer + " not found!");
			return [];
		}
	}
}
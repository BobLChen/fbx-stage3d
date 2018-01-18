package {

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	import core.base.Cube;
	import core.base.Geometry3D;
	import core.base.Mesh3D;
	import core.loader.SceneLoader;
	import core.render.SkeletonRender;
	import core.scene.Scene3D;
	import core.shader.Shader3D;
	import core.shader.filter.ColorFilter;
	import core.shader.filter.Filter3D;
	import core.shader.filter.TextureMapFilter;
	import core.texture.Texture3D;
	import core.utils.Device3D;

	public class Samples extends Sprite {
		
		private var scene : Scene3D;
		
		public function Samples() {
			
			stage.scaleMode 	= StageScaleMode.NO_SCALE;
			stage.align		= StageAlign.TOP_LEFT;
			stage.frameRate	= 60;
			
			addChild(new L3DStats());
			
			scene = new Scene3D(this);
			scene.backgroundColor = 0x123456;
			scene.antialias = 4;
			scene.camera.z = -1500;
			scene.camera.y = 1500;
			scene.camera.lookAt(0, 0, 0);
			
			var test0 : SceneLoader = new SceneLoader(PathUtil.dirName(this.loaderInfo.url) + "/" + "test0/Test22.scene");
			test0.addEventListener("CameraEvent", onLoadCamera);
			test0.load();
			scene.addChild(test0);
			
			var test1 : SceneLoader = new SceneLoader(PathUtil.dirName(this.loaderInfo.url) + "/" + "test1/akali.scene");
			test1.addEventListener("MeshEvent", onSkeMeshComplete);
			test1.load();
			scene.addChild(test1);
			
			Device3D.debug = false; 
			
			scene.addEventListener(Event.CONTEXT3D_CREATE, onCreate);
		}
		
		private var weapon : Cube = new Cube("", 100, 10, 10, 1, new Shader3D("", [new ColorFilter(0xFF00FF)]));
		
		protected function onSkeMeshComplete(event:MeshEvent) : void {
			var mesh : Mesh3D = 	event.mesh;
			for each (var geo : Geometry3D in mesh.geometries) {
				var filter : Filter3D = geo.shader.getFilterByClass(TextureMapFilter);
				(filter as TextureMapFilter).texture = new Texture3D(PathUtil.dirName(this.loaderInfo.url) + "/" + "test1/Akali_Red_TX_CM.jpg");
			}
			
			var num  : int = 30;
			for (var i:int = 0; i < num; i++) {
				for (var j:int = 0; j < num; j++) {
					var clone : Mesh3D = mesh.clone();
					clone.frameSpeed = Math.random();
					clone.x = (i - num / 2) * 100;
					clone.z = (j - num / 2) * 100;
					scene.addChild(clone);
					clone.play();
				}
			}
			
			// 武器
			mesh.setScale(5, 5, 5);
			mesh.addChild(weapon);
			mesh.addEventListener("exitFrame", onSkeletonMeshexitFrame);
		}
		 
		protected function onSkeletonMeshexitFrame(event:Event) : void {
			var mesh : Mesh3D = event.target as Mesh3D;
			var render : SkeletonRender = mesh.render as SkeletonRender;
			weapon.transform.copyFrom(render.getMount("weapon_b", int(mesh.currentFrame)));
		}
		
		protected function onLoadCamera(event:CameraEvent) : void {
			event.camera.play();
			scene.addChild(event.camera);
//			scene.camera = event.camera;
		}
		
		protected function onCreate(event:Event) : void {
			scene.context.enableErrorChecking = true;
			trace(scene.context.driverInfo);
		}
		
	}
}

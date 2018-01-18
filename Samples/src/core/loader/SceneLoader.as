package core.loader {

	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import core.base.Geometry3D;
	import core.base.Mesh3D;
	import core.base.Pivot3D;
	import core.render.SkeletonRender;
	import core.shader.Shader3D;
	import core.shader.filter.ColorFilter;
	import core.shader.filter.SkeletonFilter34;
	import core.shader.filter.SkeletonFilterQuat;
	import core.shader.filter.TextureMapFilter;
	import core.texture.Texture3D;

	public class SceneLoader extends Pivot3D {
		
		private var url  	: String;
		private var meshMap 	: Dictionary = new Dictionary();
		private var animMap 	: Dictionary = new Dictionary();
		
		public function SceneLoader(url : String) {
			this.url = url;
		}
		
		public function load() : void {
			var loader : URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, loadConfig);
			loader.load(new URLRequest(this.url));
		}
		
		protected function loadConfig(event:Event) : void {
			var loader 	: URLLoader = event.target as URLLoader;
			var data   	: String = loader.data as String;
			var config 	: Object = JSON.parse(data);
			var path		: String = PathUtil.dirName(this.url) + "/";
			// 加载模型
			for each (var meshItem : Object in config.meshes) {
				var meshLoader : MeshLoader = new MeshLoader(path + meshItem.name);
				meshLoader.addEventListener(Event.COMPLETE, onMeshComplete);
				meshLoader.load();
				this.meshMap[meshLoader] = meshItem;
			}
			// 加载相机
			for each (var camerItem : Object in config.cameras) {
				var cameraLoader : CameraLoader = new CameraLoader(path + camerItem);
				cameraLoader.addEventListener(Event.COMPLETE, onCameraLoadComplete);
				cameraLoader.load();
			}
			
		}
		
		protected function onCameraLoadComplete(event:Event) : void {
			var loader : CameraLoader = event.target as CameraLoader;
			var ce : CameraEvent = new CameraEvent("CameraEvent");
			ce.camera = loader.camera;
			this.dispatchEvent(ce);
		}
		
		/**
		 * 模型加载完成 
		 * @param event
		 * 
		 */		
		protected function onMeshComplete(event:Event) : void {
			var loader 	: MeshLoader = event.target as MeshLoader;
			var mesh   	: Mesh3D = loader.mesh;
			var item   	: Object = this.meshMap[loader];
			var path		: String = PathUtil.dirName(this.url) + "/";
			for each (var geo : Geometry3D in mesh.geometries) {
				if (item.texture) {
					geo.shader = new Shader3D("", [new TextureMapFilter(new Texture3D(path + item.texture))]);
				} else {
					geo.shader = new Shader3D("", [new ColorFilter(0xFFFFFF * Math.random())]);
				}
			}
			addChild(mesh);
			// 加载动画
			var animLoader : AnimLoader = new AnimLoader(path + "/" + item.anim.name);
			animLoader.addEventListener(Event.COMPLETE, onAnimComplete);
			animLoader.load();
			
			this.animMap[animLoader] = mesh;
			
		}
		
		protected function onAnimComplete(event:Event) : void {
			var loader : AnimLoader = event.target as AnimLoader;	
			var mesh : Mesh3D = animMap[loader];
			mesh.render = loader.render;
			mesh.play();
			
			// 获取动画类型
			if (loader.render is SkeletonRender) {
				var sr : SkeletonRender = loader.render as SkeletonRender;
				for each (var geo : Geometry3D in mesh.geometries) {
					if (sr.quat) {
						geo.shader.addFilter(new SkeletonFilterQuat());
					} else {
						geo.shader.addFilter(new SkeletonFilter34());						
					}
				}
				
				this.dispatchEvent(new MeshEvent(mesh));
			}
			
		}
	}
}

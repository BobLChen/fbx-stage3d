package core.loader {

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import core.camera.Camera3D;

	public class CameraLoader extends EventDispatcher {
		
		private var url : String;
		
		public var camera : Camera3D;
		
		public function CameraLoader(url : String) {
			this.url = url;
		}

		public function load() : void {
			var loader : URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.load(new URLRequest(url));
		}
		
		protected function onComplete(event:Event) : void {
			var loader : URLLoader = event.target as URLLoader;
			this.camera = Parser3DUtils.readCamera(loader.data);
			this.dispatchEvent(event);
		}
		
	}
}

package core.loader {

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import core.render.DefaultRender;

	public class AnimLoader extends EventDispatcher {
		
		private var url		: String;
		public var render	: DefaultRender; 
		
		public function AnimLoader(url : String) {
			this.url = url;
		}
		
		public function load() : void {
			var loader : URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.load(new URLRequest(this.url));
		}
		
		protected function onComplete(event:Event) : void {
			var loader : URLLoader = event.target as URLLoader;
			render = Parser3DUtils.readAnim(loader.data);
			this.dispatchEvent(event);
		}
	}
}

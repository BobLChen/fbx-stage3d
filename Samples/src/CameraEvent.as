package {

	import flash.events.Event;
	
	import core.camera.Camera3D;

	public class CameraEvent extends Event {
		
		public var camera : Camera3D;
		
		public function CameraEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false) {
			super(type, bubbles, cancelable);
		}
	}
}

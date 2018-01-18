package {

	import flash.events.Event;
	
	import core.base.Mesh3D;

	public class MeshEvent extends Event {
		
		public var mesh : Mesh3D;
		
		public function MeshEvent(mesh : Mesh3D) {
			super("MeshEvent");
			this.mesh = mesh;
		}
	}
}

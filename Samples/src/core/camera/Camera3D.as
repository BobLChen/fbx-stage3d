package core.camera {

	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import core.base.Pivot3D;

	/**
	 * camera3d
	 * @author neil
	 *
	 */
	public class Camera3D extends Pivot3D {
		
		protected var _vierProjection 	: Matrix3D = new Matrix3D();
		protected var _lens 				: LensBase;
		protected var _projDirty 		: Boolean = false;		
		
		public var isClip : Boolean = false;
		
		public function Camera3D(name : String = "default", len : LensBase = null) {
			super(name);
			if (len == null) {
				_lens = new PerspectiveLens(75);
			} else {
				_lens = len;
			}
			_lens.addEventListener("PROJECTION_UPDATE", onLensProjChanged);
		}
		
		protected function onLensProjChanged(event:Event) : void {
			_projDirty = true;		
		}
						
		public function set lens(len : LensBase) : void {
			if (_lens != null) {
				this._lens.removeEventListener("PROJECTION_UPDATE", onLensProjChanged);
			}
			this._lens = len;
			this._lens.addEventListener("PROJECTION_UPDATE", onLensProjChanged);
		}
				
		public function get lens() : LensBase {
			return _lens;
		}
		
		public function updateProjectionMatrix() : void {
			_lens.updateProjectionMatrix();
		}
				
		public function get zoom() : Number {
			return this._lens.zoom;
		}
		
		public function set zoom(value : Number) : void {
			this._lens.zoom = value;
		}
		
		public function get near() : Number {
			return this._lens.near;
		}
		
		public function set near(value : Number) : void {
			if (value <= 0.1)
				value = 0.1;
			this._lens.near = value;
		}
		
		public function set viewPort(rect : Rectangle) : void {
			this._lens.viewPort = rect;
		}
		
		public function get viewPort() : Rectangle {
			return this._lens.viewPort;
		}
		
		public function get aspectRatio() : Number {
			return this._lens.aspectRatio;
		}
		
		public function set aspectRatio(value : Number) : void {
			this._lens.aspectRatio = value;
		}
		
		public function get far() : Number {
			return this._lens.far;
		}
		
		public function set far(value : Number) : void {
			this._lens.far = value;
		}
		
		public function get viewProjection() : Matrix3D {
			if (_projDirty || _dirtyInv) { 
				_projDirty = false;
				this._vierProjection.copyFrom(view);
				this._vierProjection.append(_lens.projection);
			}
			return this._vierProjection;
		}
		
		public function get projection() : Matrix3D {
			return this._lens.projection;
		}
		
		public function get view() : Matrix3D {
			return invWorld;
		}
		
	}
}

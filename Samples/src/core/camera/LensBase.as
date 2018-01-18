package core.camera {
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	
	/**
	 * 镜头基类
	 * @author neil
	 * 
	 */	
	public class LensBase extends EventDispatcher {
		
		protected var _projection 	: Matrix3D;
		protected var _scissorRect 	: Rectangle = new Rectangle();
		protected var _viewPort 		: Rectangle;
		protected var _near 			: Number 	= 0.1;
		protected var _far 			: Number 	= 1000;
		protected var _projectDirty 	: Boolean 	= true;
		protected var _aspectRatio 	: Number 	= 1;
		protected var _zoom 			: Number 	= 1;
		protected var _projectEvent 	: Event = new Event("PROJECTION_UPDATE");
		
		private var _invProjection 		: Matrix3D;
		private var _invProjectionDirty 	: Boolean = true;
		
		public function LensBase() {
			_projection = new Matrix3D();
		}
		
		public function get projectionUpdateEvent():Event {
			return _projectEvent;
		}

		public function set projectionUpdateEvent(value:Event):void {
			_projectEvent = value;
		}
		
		public function get zoom() : Number {
			return _zoom;
		}
		
		public function set zoom(value : Number) : void {
			if (_zoom == value)
				return;
			_zoom = value;
			invalidateProjection()
		}
		
		/**
		 * 获取projection 
		 * @return 
		 */		
		public function get projection() : Matrix3D {
			if (_projectDirty) {
				updateProjectionMatrix();
				_projectDirty = false;
			}
			return _projection;
		}
		
		public function set projection(value : Matrix3D) : void {
			_projection = value;
			invalidateProjection();
		}
		
		public function get near() : Number {
			return _near;
		}
		
		public function set near(value : Number) : void {
			if (value == _near)
				return;
			_near = value;
			invalidateProjection();
		}
		
		public function get far() : Number {
			return _far;
		}

		public function set far(value : Number) : void {
			if (value == _far)
				return;
			_far = value;
			invalidateProjection();
		}
		
		public function get invProjection() : Matrix3D {
			if (_invProjectionDirty) {
				_invProjection ||= new Matrix3D();
				_invProjection.copyFrom(projection);
				_invProjection.invert();
				_invProjectionDirty = false;
			}
			return _invProjection;
		}
		
		public function set viewPort(rect : Rectangle) : void {
			this._viewPort = rect;
			invalidateProjection();
		}

		public function get viewPort() : Rectangle {
			return this._viewPort;
		}
		
		public function get aspectRatio() : Number {
			return _aspectRatio;
		}
		
		public function set aspectRatio(value : Number) : void {
			if (_aspectRatio == value)
				return;
			_aspectRatio = value;
			invalidateProjection();
		}

		protected function invalidateProjection() : void {
			_projectDirty 		= true;
			_invProjectionDirty 	= true;
		}
		
		public function updateProjectionMatrix() : void {
			dispatchEvent(_projectEvent);
		}
		
		public function updateViewport(x : Number, y : Number, width : Number, height : Number) : void {
			_viewPort.x = x;
			_viewPort.y = y;
			_viewPort.width = width;
			_viewPort.height = height;
			invalidateProjection();
		}
				
	}
}

package core.camera {

	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * 透视投影矩阵
	 * @author neil
	 */
	public class PerspectiveLens extends LensBase {

		private static var _inv : Matrix3D;
		private static const rawData : Vector.<Number> = new Vector.<Number>(16, true);
		
		private var _fieldOfView : Number;
		private var _aspect : Number;
		private var _cachedAspectRatio : Number;
		private var _view : Matrix3D;
		private var _viewProjection : Matrix3D;
		private var _canvasSize : Point;

		private var _frustum : Vector.<Number>;

		public function PerspectiveLens(fieldOfView : Number = 75) {
			this._near = 0.1;
			this._far = 3000;
			this._frustum = new Vector.<Number>(24, true);
			this._view = new Matrix3D();
			this._projection = new Matrix3D();
			this.aspectRatio = this._aspect;
			this.fieldOfView = fieldOfView;
			this._viewProjection = new Matrix3D();
		}

		public override function set viewPort(rect : Rectangle) : void {
			this._viewPort = rect;
			this.updateProjectionMatrix();
		}

		public override function get viewPort() : Rectangle {
			return this._viewPort;
		}

		public function get fieldOfView() : Number {
			return _fieldOfView;
		}

		public function set fieldOfView(value : Number) : void {
			if (value == _fieldOfView)
				return;
			this._fieldOfView = value;
			this._zoom = Math.tan(value * Math.PI / 360);
			this.updateProjectionMatrix();
		}

		public override function set zoom(value : Number) : void {
			if (_zoom == value)
				return;
			this._zoom = value;
			this._fieldOfView = Math.atan(value) * 360 / Math.PI;
			this.updateProjectionMatrix();
		}

		public override function set near(value : Number) : void {
			if (_near == value)
				return;

			if (value <= 0.1) {
				value = 0.1;
			}
			this._near = value;
			this.updateProjectionMatrix();
		}

		public override function set far(value : Number) : void {
			if (this._far == value)
				return;
			this._far = value;
			this.updateProjectionMatrix();
		}

		public override function get aspectRatio() : Number {
			return this._cachedAspectRatio;
		}

		public override function set aspectRatio(value : Number) : void {
			this._aspect = value;
			this.updateProjectionMatrix();
		}

		override public function updateProjectionMatrix() : void {

			if (this.viewPort == null) {
				return;
			}
			
			var w : Number = 0;
			var h : Number = 0;
			var n : Number = this._near;
			var f : Number = this._far;

			w = this.viewPort.width;
			h = this.viewPort.height;
			
			var a : Number = w / h;

			var y : Number = 1 / this._zoom * a;
			var x : Number = y / a;

			this._cachedAspectRatio = a;
			rawData[0] = x;
			rawData[5] = y;
			rawData[10] = f / (n - f);
			rawData[11] = -1;
			rawData[14] = (f * n) / (n - f);
			rawData[0] = (x / (w / this._viewPort.width));
			rawData[5] = (y / (h / this._viewPort.height));
			rawData[8] = (1 - (this._viewPort.width / w)) - ((this._viewPort.x / w) * 2);
			rawData[9] = (-1 + (this._viewPort.height / h)) + ((this._viewPort.y / h) * 2);
			
			this._projection.copyRawDataFrom(rawData);
			this._projection.prependScale(1, 1, -1);
			this.dispatchEvent(_projectEvent);
		}

	}
}

package core.base {

	import flash.geom.Vector3D;

	/**
	 * 包围盒
	 * @author neil
	 */
	public class Bounds3D {
		
		private var _radius 	: Number = 0;
		private var _length 	: Vector3D;
		private var _min 	: Vector3D;
		private var _max 	: Vector3D;
		private var _center 	: Vector3D;
		private var _pIPoint	: Vector3D = new Vector3D();
		private var _dirty	: Boolean = true;

		public function Bounds3D() {
			this.reset();
		}

		public function get radius() : Number {
			return _radius;
		}

		public function set radius(value : Number) : void {
			_radius = value;
		}

		public function get length() : Vector3D {
			return _length;
		}

		public function set length(value : Vector3D) : void {
			_length = value;
		}

		public function get max() : Vector3D {
			return _max;
		}

		public function set max(value : Vector3D) : void {
			_max = value;
		}

		public function get center() : Vector3D {
			return _center;
		}

		public function set center(value : Vector3D) : void {
			_center = value;
		}

		public function get min() : Vector3D {
			return _min;
		}

		public function set min(value : Vector3D) : void {
			_min = value;
		}

		public function clone() : Bounds3D {
			var bounds : Bounds3D = new Bounds3D();
			bounds.radius = this.radius;
			bounds.min = this.min.clone();
			bounds.max = this.max.clone();
			bounds.length = this.length.clone();
			bounds.center = this.center.clone();
			return bounds;
		}
		
		public function toString() : String {
			return '[object Boundings3D radius=' + radius + ', min=' + min + ', max=' + max + ', center=' + center + ', length=' + length + ']';
		}

		public function reset() : void {
			this.radius = 0;
			this.min = new Vector3D();
			this.max = new Vector3D();
			this.center = new Vector3D();
			this.length = new Vector3D();
			this._dirty = true;
		}
		
	}
}

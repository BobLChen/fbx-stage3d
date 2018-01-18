package core.base {

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import core.shader.filter.ColorFilter;
	import core.utils.Matrix3DUtils;
	import core.shader.Shader3D;

	/**
	 * Cube
	 * @author neil
	 *
	 */
	public class Cube extends Mesh3D {

		private var _width 	: Number;
		private var _height 	: Number;
		private var _depth 	: Number;
		private var _segments : int;
		
		/**
		 *  
		 * @param name			名称
		 * @param width			宽度
		 * @param height			高度
		 * @param depth			深度
		 * @param segments		段数
		 * @param shader			shader
		 * 
		 */		
		public function Cube(name : String = "", width : Number = 10, height : Number = 10, depth : Number = 10, segments : int = 1, shader : Shader3D = null) {

			super(name);

			this._segments 	= segments;
			this._depth 		= depth;
			this._height 	= height;
			this._width 		= width;
			
			if (shader == null) {
				shader = new Shader3D(name + "_material", [new ColorFilter(0xFF0000)]);
			}
			
			this.geometries[0] = new Geometry3D(name);
			this.geometries[0].setVertexDataType(Geometry3D.POSITION);
			this.geometries[0].setVertexDataType(Geometry3D.NORMAL);
			this.geometries[0].setVertexDataType(Geometry3D.UV0);
			this.geometries[0].vertexVector = new Vector.<Number>();
			this.geometries[0].indexVector  = new Vector.<uint>();
			this.geometries[0].shader = shader;

			this.createPlane(width, height, (depth * 0.5), segments, "+xy");
			this.createPlane(width, height, (depth * 0.5), segments, "-xy");
			this.createPlane(depth, height, (width * 0.5), segments, "+yz");
			this.createPlane(depth, height, (width * 0.5), segments, "-yz");
			this.createPlane(width, depth, (height * 0.5), segments, "+xz");
			this.createPlane(width, depth, (height * 0.5), segments, "-xz");
			
			
		}
		
		private function createPlane(width : Number, height : Number, depth : Number, segments : int, axis : String) : void {

			var geometry : Geometry3D = geometries[0];
			var matrix : Matrix3D = new Matrix3D();

			if (axis == "+xy") {
				Matrix3DUtils.setOrientation(matrix, new Vector3D(0, 0, -1));
			} else if (axis == "-xy") {
				Matrix3DUtils.setOrientation(matrix, new Vector3D(0, 0, 1));
			} else if (axis == "+xz") {
				Matrix3DUtils.setOrientation(matrix, new Vector3D(0, 1, 0));
			} else if (axis == "-xz") {
				Matrix3DUtils.setOrientation(matrix, new Vector3D(0, -1, 0));
			} else if (axis == "+yz") {
				Matrix3DUtils.setOrientation(matrix, new Vector3D(1, 0, 0));
			} else if (axis == "-yz") {
				Matrix3DUtils.setOrientation(matrix, new Vector3D(-1, 0, 0));
			}

			Matrix3DUtils.setScale(matrix, width, height, 1);
			Matrix3DUtils.translateZ(matrix, depth);

			var raw : Vector.<Number> = matrix.rawData;
			var normal : Vector3D = Matrix3DUtils.getDir(matrix);
			var i : int = 0;
			var e : int = 0;
			var u : Number = 0;
			var v : Number = 0;
			var x : Number = 0;
			var y : Number = 0;
			i = geometry.vertexVector.length / geometry.sizePerVertex;
			e = i;
			v = 0;

			while (v <= segments) {
				u = 0;

				while (u <= segments) {
					x = (u / segments) - 0.5;
					y = (v / segments) - 0.5;
					geometry.vertexVector.push((x * raw[0]) + (y * raw[4]) + raw[12], (x * raw[1]) + (y * raw[5]) + raw[13], (x * raw[2]) + (y * raw[6]) + raw[14], normal.x, normal.y, normal.z, 1 - (u /
						segments), 1 - (v / segments));
					i++;
					u++;
				}
				v++;
			}
			i = geometry.indexVector.length;
			v = 0;

			while (v < segments) {
				u = 0;

				while (u < segments) {
					geometry.indexVector[i++] = u + 1 + v * (segments + 1) + e;
					geometry.indexVector[i++] = u + 1 + (v + 1) * (segments + 1) + e;
					geometry.indexVector[i++] = u + (v + 1) * (segments + 1) + e;
					geometry.indexVector[i++] = u + v * (segments + 1) + e;
					geometry.indexVector[i++] = u + 1 + v * (segments + 1) + e;
					geometry.indexVector[i++] = u + (v + 1) * (segments + 1) + e;
					u++;
				}
				v++;
			}
		}

		public function get segments() : int {
			return this._segments;
		}

		public function get depth() : Number {
			return this._depth;
		}

		public function get height() : Number {
			return this._height;
		}

		public function get width() : Number {
			return this._width;
		}

	}
}

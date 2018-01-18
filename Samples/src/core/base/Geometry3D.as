package core.base {

	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import core.scene.Scene3D;
	import core.shader.Shader3D;
	
	/**
	 * 网格基础数据。
	 * @author neil
	 */
	public class Geometry3D extends EventDispatcher {

		/** 顶点 */
		public static const POSITION			: int = 0;
		/** 法线 */
		public static const NORMAL 			: int = 1;
		/** uv0,默认uv */
		public static const UV0 				: int = 2;
		/** 权重 */
		public static const SKIN_WEIGHTS 	: int = 3;
		/** 骨骼索引 */
		public static const SKIN_INDICES 	: int = 4;
		/** 切线 */
		public static const TANGENT 			: int = 5;
		/** 双切线 */
		public static const BITANGENT 		: int = 6;
		/** 粒子 */
		public static const PARTICLE 		: int = 7;
		/** uv1 uv2 uv3 */
		public static const UV1 				: int = 8;
		/** custom data1 */
		public static const CUSTOM1 			: int = 9;
		/** custom data2 */
		public static const CUSTOM2 			: int = 10;
		/** custom data3 */
		public static const CUSTOM3 			: int = 11;
		/** custom data4 */
		public static const CUSTOM4 			: int = 12;
		/** custom data4 */
		public static const CUSTOM5 			: int = 13;
		
		/** 包围盒 */
		public var bounds 		: Bounds3D;
		/** 顶点buffer */
		public var vertexBuffer 	: VertexBuffer3D;
		/** 索引buffer */
		public var indexBuffer 	: IndexBuffer3D;
		/** 三角形数量 */
		public var numTriangles 	: int = -1;
		/** 三角形起始索引 */
		public var firstIndex 	: int = 0;
		/** vertexBuffer横向数据长度 */
		public var sizePerVertex	: int = 0;
		/** offset */
		public var offsets 		: Vector.<int>;
		/** formats */
		public var formats 		: Vector.<String>;
		/** sources */
		public var sources 		: Vector.<Geometry3D>;
		/** name */
		public var name 			: String;
		/** scene */
		public var scene 		: Scene3D;
		/** 着色器 */
		private var _shader 		: Shader3D;
		/** 索引数据 */
		private var _indexVector	: Vector.<uint>;
		/** 顶点数据 */
		private var _vertexVector: Vector.<Number>;
		/** 顶点数据 */
		private var _vertexBytes	: ByteArray;
				
		public function Geometry3D(name : String = null) {
			this.offsets = new Vector.<int>(14, true);
			this.sources = new Vector.<Geometry3D>(14, true);
			this.formats = new Vector.<String>();
			this.name = name;
			var i : int = 0;
			while (i < this.offsets.length) {
				this.offsets[i] = -1;
				this.formats[i] = null;
				i++;
			}
		}
		
		/**
		 * 设置顶点数据，必须是little endian
		 * @param value
		 */
		public function set vertexBytes(value : ByteArray) : void {
			_vertexBytes = value;
		}
		
		/**
		 * 设置网格数据类型				
		 * @param dataIndex				类型索引
		 * @param size					大小
		 * @return						偏移量
		 */
		public function setVertexDataType(dataIndex : uint, size : int = -1) : int {
			if (size == -1) {
				switch (dataIndex) {
					case POSITION:
					case NORMAL:
					case BITANGENT:
					case TANGENT:
						size = 3;
						break;
					case UV0:
					case UV1:
						size = 2;
						break;
						break;
					case SKIN_INDICES:
					case SKIN_WEIGHTS:
						size = 4;
						break;
				}
			}
			
			this.formats[dataIndex] = "float" + size;
			
			if (this.offsets[dataIndex] != -1) {
				this.sizePerVertex = Math.max(this.sizePerVertex, this.offsets[dataIndex] + size);
				return this.offsets[dataIndex];
			}
			this.offsets[dataIndex] 	= this.sizePerVertex;
			this.sizePerVertex 	   += size;
			this.download();
			return this.offsets[dataIndex];
		}
		
		public function dispose() : void {
			// 先卸载、再销毁
			this.download();
			for each (var souce : Geometry3D in sources) {
				souce.dispose();
			}
			if (this._vertexBytes) {
				this._vertexBytes.clear();
				this._vertexBytes = null;	
			}
			if (this._vertexVector) {
				this._vertexVector.length = 0;
				this._vertexVector = null;
			}
			if (this._indexVector) {
				this._indexVector.length = 0;
				this._indexVector = null;
			}
			this._shader		= null;
			this.bounds 		= null;
			this.offsets 	= null;
			this.formats 	= null;
			this.sources		= null;
		}
		
		/**
		 *  卸载
		 */
		public function download() : void {
			if (this.indexBuffer) {
				this.indexBuffer.dispose();
				this.indexBuffer = null;
			}
			if (this.vertexBuffer) {
				this.vertexBuffer.dispose();
				this.vertexBuffer = null;
			}
			if (this.scene) {
				this.scene.removeEventListener(Event.CONTEXT3D_CREATE, contextEvent);
				this.scene = null;
			}
			for each (var source : Geometry3D in sources) {
				if (source == null) {
					continue;
				}
				source.download();
			}
		}
		
		/**
		 * 
		 * @param startVertex
		 * @param numVertices
		 */
		public function updateVertexBuffer(startVertex : int = 0, numVertices : int = -1) : void {
			if (this.scene == null || this.scene.context == null) {
				return;
			}
			if (this._vertexVector && this._vertexVector.length > 0) {
				if (numVertices == -1) {
					numVertices = this._vertexVector.length / this.sizePerVertex;
				}
				if (this.vertexBuffer == null) {
					this.vertexBuffer = this.scene.context.createVertexBuffer(numVertices, this.sizePerVertex);
				}
				this.vertexBuffer.uploadFromVector(this._vertexVector, startVertex, numVertices);
			} else if (this._vertexBytes && this._vertexBytes.length > 0) {
				if (numVertices == -1) {
					numVertices = this._vertexBytes.length / 4 / this.sizePerVertex;
				}
				if (this.vertexBuffer == null) {
					this.vertexBuffer = this.scene.context.createVertexBuffer(numVertices, this.sizePerVertex);
				}
				this.vertexBuffer.uploadFromByteArray(this._vertexBytes, 0, startVertex, numVertices);
			} else {
				throw new Error("Surface '" + this.name + "' does not have vertex data.");
			}
		}
		
		/**
		 * @param startIndex
		 * @param numIndices
		 */
		public function updateIndexBuffer(startIndex : int = 0, numIndices : int = -1) : void {
			if (this.scene == null || this.scene.context == null) {
				return;
			}
			if (this._indexVector && (this._indexVector.length > 0)) {
				this.numTriangles = this._indexVector.length / 3;
				if (numIndices == -1) {
					numIndices = this._indexVector.length;
				}
				if (this.indexBuffer == null) {
					this.indexBuffer = this.scene.context.createIndexBuffer(numIndices);
				}
				this.indexBuffer.uploadFromVector(this._indexVector, startIndex, numIndices);
			} else {
				var len : int = this._vertexVector ? (this._vertexVector.length / this.sizePerVertex) : (this._vertexBytes.length / 4 / this.sizePerVertex);
				this._indexVector = new Vector.<uint>(len);
				var i : int = 0;
				while (i < len) {
					this._indexVector[i] = i;
					i++;
				}
				this.indexBuffer = this.scene.context.createIndexBuffer(this._indexVector.length);
				this.indexBuffer.uploadFromVector(this._indexVector, 0, this._indexVector.length);
				this.numTriangles = len / 3;
			}
		}

		/**
		 * 上传
		 * @param scene
		 *
		 */
		public function upload(scene : Scene3D) : void {
			if (this.scene) {
				return;
			}
			this.scene = scene;
			if (this.scene.context) {
				this.contextEvent();
			}
			this.scene.addEventListener(Event.CONTEXT3D_CREATE, contextEvent);
			if (this._shader) {
				this._shader.upload(scene);
			}
		}
		
		/**
		 * 上传 
		 * @param e
		 */		
		private function contextEvent(e : Event = null) : void {
			if (this.vertexBuffer) {
				this.vertexBuffer.dispose();
				this.vertexBuffer = null;
			}
			if (this.indexBuffer) {
				this.indexBuffer.dispose();
				this.indexBuffer = null;
			}
			this.updateVertexBuffer();
			this.updateIndexBuffer();
			for each (var source : Geometry3D in this.sources) {
				if (source == null) {
					continue;
				}
				source.upload(scene);
			}
		}
				
		override public function toString() : String {
			return "[object Geometry3D name:" + this.name + " triangles:" + this.numTriangles + "]";
		}
		
		/**
		 * update bounds
		 * @return
		 *
		 */
		public function updateBoundings() : Bounds3D {
			this.bounds = new Bounds3D();
			this.bounds.min.setTo(10000000, 10000000, 10000000);
			this.bounds.max.setTo(-10000000, -10000000, -10000000);
			var l : int = this.vertexVector.length;
			var i : int = this.offsets[POSITION];
			while (i < l) {
				var x : Number = this.vertexVector[i];
				var y : Number = this.vertexVector[i + 1];
				var z : Number = this.vertexVector[i + 2];
				if (x < this.bounds.min.x) {
					this.bounds.min.x = x;
				}
				if (y < this.bounds.min.y) {
					this.bounds.min.y = y;
				}
				if (z < this.bounds.min.z) {
					this.bounds.min.z = z;
				}
				if (x > this.bounds.max.x) {
					this.bounds.max.x = x;
				}
				if (y > this.bounds.max.y) {
					this.bounds.max.y = y;
				}
				if (z > this.bounds.max.z) {
					this.bounds.max.z = z;
				}
				i = i + this.sizePerVertex;
			}
			this.bounds.length.x = this.bounds.max.x - this.bounds.min.x;
			this.bounds.length.y = this.bounds.max.y - this.bounds.min.y;
			this.bounds.length.z = this.bounds.max.z - this.bounds.min.z;
			this.bounds.center.x = this.bounds.length.x * 0.5 + this.bounds.min.x;
			this.bounds.center.y = this.bounds.length.y * 0.5 + this.bounds.min.y;
			this.bounds.center.z = this.bounds.length.z * 0.5 + this.bounds.min.z;
			i = 0;
			while (i < l) {
				x = this.vertexVector[i];
				y = this.vertexVector[i + 1];
				z = this.vertexVector[i + 2];
				var dx : Number = this.bounds.center.x - x;
				var dy : Number = this.bounds.center.y - y;
				var dz : Number = this.bounds.center.z - z;
				var temp : Number = dx * dx + dy * dy + dz * dz;
				if (temp > this.bounds.radius) {
					this.bounds.radius = temp;
				}
				i = i + this.sizePerVertex;
			}
			this.bounds.radius = Math.sqrt(this.bounds.radius);
			return this.bounds;
		}
		
		/**
		 * 获取shader。 
		 * @return 
		 * 
		 */		
		public function get shader() : Shader3D {
			return this._shader;
		}
		
		public function set shader(value : Shader3D) : void {
			this._shader = value;
		}
		
		public function get vertexVector() : Vector.<Number> {
			if (this._vertexVector != null) {
				return this._vertexVector;
			}
			this._vertexVector = new Vector.<Number>();
			if (this._vertexBytes == null) {
				return this._vertexVector;
			}
			this._vertexBytes.position = 0;
			var i : int = 0;
			while (this._vertexBytes.bytesAvailable) {
				this._vertexVector[i++] = this._vertexBytes.readFloat();
			}
			return this._vertexVector;
		}
		
		public function set vertexVector(value : Vector.<Number>) : void {
			this._vertexVector = value;
		}
		
		/**
		 * indexVector
		 * @return
		 */
		public function get indexVector() : Vector.<uint> {
			if (this._indexVector == null) {
				this._indexVector = new Vector.<uint>();
			}
			return this._indexVector;
		}
		
		public function set indexVector(value : Vector.<uint>) : void {
			this._indexVector = value;
		}
		
		/**
		 * 获取geometry 
		 * @param type		Geometry3D类型
		 * @return 
		 * 
		 */		
		public function getSourceGeometry(type : int) : Geometry3D {
			if (sources[type] != null) {
				return sources[type];
			}
			return this;
		}
		
	}
}

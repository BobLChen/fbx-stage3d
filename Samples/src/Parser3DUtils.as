package {
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import core.base.Bounds3D;
	import core.base.Frame3D;
	import core.base.Geometry3D;
	import core.base.Mesh3D;
	import core.camera.Camera3D;
	import core.camera.PerspectiveLens;
	import core.render.DefaultRender;
	import core.render.FrameRender;
	import core.render.SkeletonRender;

	/**
	 * 模型工具 
	 * @author Neil
	 * 
	 */	
	public class Parser3DUtils {
		
		public function Parser3DUtils() {
			throw new Error("无法实例化MeshUtils");	
		}
		
		public static function readCamera(bytes : ByteArray) : Camera3D {
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.uncompress();
			
			var camera : Camera3D = new Camera3D();
			
			var len : int = bytes.readInt();
			camera.name = bytes.readUTFBytes(len);
			
			var w : Number = bytes.readFloat();		// width
			var h : Number = bytes.readFloat();		// height
			
			camera.near = bytes.readFloat();			// near
			camera.far  = bytes.readFloat();			// far
			(camera.lens as PerspectiveLens).fieldOfView = bytes.readFloat(); // fieldofview
			
			var vec : Vector3D = new Vector3D();
			for (var i:int = 0; i < 3; i++) {
				vec.x = bytes.readFloat();
				vec.y = bytes.readFloat();
				vec.z = bytes.readFloat();
				vec.w = bytes.readFloat();
				camera.transform.copyRowFrom(i, vec);
			}
			
			len = bytes.readInt();
			camera.frames = new Vector.<Frame3D>();
			for (i = 0; i < len; i++) {
				var frame : Frame3D = new Frame3D();
				for (var j:int = 0; j < 3; j++) {
					vec.x = bytes.readFloat();
					vec.y = bytes.readFloat();
					vec.z = bytes.readFloat();
					vec.w = bytes.readFloat();
					frame.transform.copyRowFrom(j, vec);
				}
				camera.frames.push(frame);
			}
			
			return camera;
		}
							
		
		/**
		 * 读取Mesh 
		 * @param bytes
		 * @return 
		 * 
		 */		
		public static function readMesh(bytes : ByteArray) : Mesh3D {
			
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.uncompress();
			
			var mesh : Mesh3D = new Mesh3D();
			// 读取Mesh名称
			var size : int = bytes.readInt();
			mesh.name = bytes.readUTFBytes(size);
			// 读取坐标
			var vec   : Vector3D = new Vector3D();
			for (var j:int = 0; j < 3; j++) { 
				vec.x = bytes.readFloat();		 		
				vec.y = bytes.readFloat();	 
				vec.z = bytes.readFloat();	 
				vec.w = bytes.readFloat();	 
				mesh.transform.copyRowFrom(j, vec);
			}  
			// 读取SubMesh数量
			var subCount : int = bytes.readInt();
			for (var subIdx : int = 0; subIdx < subCount; subIdx++) {
				// 读取顶点长度
				var len : int = bytes.readInt();
				var vertBytes : ByteArray = new ByteArray();
				vertBytes.endian = Endian.LITTLE_ENDIAN;
				bytes.readBytes(vertBytes, 0, len * 12);
				// 顶点geometry
				var subGeometry : Geometry3D = new Geometry3D();
				subGeometry.setVertexDataType(Geometry3D.POSITION, 3);
				subGeometry.vertexBytes = vertBytes;
				// uv0
				len = bytes.readInt();
				if (len > 0) {
					var uv0Bytes : ByteArray = new ByteArray();
					uv0Bytes.endian = Endian.LITTLE_ENDIAN;
					bytes.readBytes(uv0Bytes, 0, len * 8);
					subGeometry.sources[Geometry3D.UV0] = new Geometry3D();
					subGeometry.sources[Geometry3D.UV0].setVertexDataType(Geometry3D.UV0, 2);
					subGeometry.sources[Geometry3D.UV0].vertexBytes = uv0Bytes;
				}
				// uv1
				len = bytes.readInt();
				if (len > 0) {
					var uv1Bytes : ByteArray = new ByteArray();
					uv1Bytes.endian = Endian.LITTLE_ENDIAN;
					bytes.readBytes(uv1Bytes, 0, len * 8);
					subGeometry.sources[Geometry3D.UV1] = new Geometry3D();
					subGeometry.sources[Geometry3D.UV1].setVertexDataType(Geometry3D.UV1, 2);
					subGeometry.sources[Geometry3D.UV1].vertexBytes = uv1Bytes; 
				}
				// normal
				len = bytes.readInt();
				if (len > 0) {
					var normalBytes : ByteArray = new ByteArray();  
					normalBytes.endian = Endian.LITTLE_ENDIAN;
					bytes.readBytes(normalBytes, 0, len * 12);
					subGeometry.sources[Geometry3D.NORMAL] = new Geometry3D();
					subGeometry.sources[Geometry3D.NORMAL].setVertexDataType(Geometry3D.NORMAL, 3);
					subGeometry.sources[Geometry3D.NORMAL].vertexBytes = normalBytes; 
				}
				len = bytes.readInt();
				if (len > 0) {
					var tangenBytes : ByteArray = new ByteArray();
					tangenBytes.endian = Endian.LITTLE_ENDIAN;
					bytes.readBytes(tangenBytes, 0, len * 12);
					subGeometry.sources[Geometry3D.TANGENT] = new Geometry3D();
					subGeometry.sources[Geometry3D.TANGENT].setVertexDataType(Geometry3D.TANGENT, 3);
					subGeometry.sources[Geometry3D.TANGENT].vertexBytes = tangenBytes; 
				}
				// 权重数据
				len = bytes.readInt();
				if (len > 0) {
					var weightBytes : ByteArray = new ByteArray();
					weightBytes.endian = Endian.LITTLE_ENDIAN;
					bytes.readBytes(weightBytes, 0, len * 16);
					subGeometry.sources[Geometry3D.SKIN_WEIGHTS] = new Geometry3D();
					subGeometry.sources[Geometry3D.SKIN_WEIGHTS].setVertexDataType(Geometry3D.SKIN_WEIGHTS, 4);
					subGeometry.sources[Geometry3D.SKIN_WEIGHTS].vertexBytes = weightBytes;
				}
				// 骨骼索引
				len = bytes.readInt();
				if (len > 0) {
					var indicesBytes : ByteArray = new ByteArray();
					indicesBytes.endian = Endian.LITTLE_ENDIAN;
					bytes.readBytes(indicesBytes, 0, len * 16);
					subGeometry.sources[Geometry3D.SKIN_INDICES] = new Geometry3D();
					subGeometry.sources[Geometry3D.SKIN_INDICES].setVertexDataType(Geometry3D.SKIN_INDICES, 4);
					subGeometry.sources[Geometry3D.SKIN_INDICES].vertexBytes = indicesBytes;
				}
				// submesh
				mesh.geometries.push(subGeometry);
			}
			
			var bounds : Bounds3D = new Bounds3D();
			bounds.min.x = bytes.readFloat();
			bounds.min.y = bytes.readFloat();
			bounds.min.z = bytes.readFloat();
			bounds.max.x = bytes.readFloat();
			bounds.max.y = bytes.readFloat();
			bounds.max.z = bytes.readFloat();
			
			for each (var geo : Geometry3D in mesh.geometries) {
				geo.bounds = bounds;
			}
			
			return mesh;
		}
		
		
		public static function readAnim(bytes : ByteArray) : DefaultRender {
			bytes.uncompress();
			bytes.endian = Endian.LITTLE_ENDIAN;
			var type : int = bytes.readInt();
			if (type == 0) {
				return readFrameAnim(bytes);
			} else {
				return readSkeletonAnim(bytes, type);
			}
			return null;
		}
		
		/**
		 * 读取帧动画 
		 * @param bytes
		 * @return 
		 * 
		 */		
		private static function readFrameAnim(bytes : ByteArray) : DefaultRender {
			var count : int = bytes.readInt();
			var vec   : Vector3D = new Vector3D();
			var frames : Vector.<Frame3D> = new Vector.<Frame3D>(count, true);
			for (var i:int = 0; i < count; i++) {
				var frame : Frame3D = new Frame3D(null, Frame3D.TYPE_FRAME);
				for (var j:int = 0; j < 3; j++) {
					vec.x = bytes.readFloat();
					vec.y = bytes.readFloat();
					vec.z = bytes.readFloat();
					vec.w = bytes.readFloat();
					frame.transform.copyRowFrom(j, vec);
				}
				frames[i] = frame;
			}
			var frameRender : FrameRender = new FrameRender();
			frameRender.frames = frames;
			return frameRender;
		}
		
		private static function readSkeletonAnim(bytes : ByteArray, type : int) : DefaultRender {
			var render : SkeletonRender = new SkeletonRender();
			var num  : int = bytes.readInt();
			for (var i:int = 0; i < num; i++) {
				render.skinData[i] = [];
				var frameCount : int = bytes.readInt();
				var boneNum    : int = bytes.readInt();
				render.totalFrames = frameCount;
				render.quat = type == 2;
				render.skinBoneNum[i] = Math.ceil(render.quat ? boneNum * 1 : boneNum * 1.5);
				for (var j:int = 0; j < frameCount; j++) {
					var data : ByteArray = new ByteArray();
					data.endian = Endian.LITTLE_ENDIAN;
					if (render.quat) {
						bytes.readBytes(data, 0, boneNum * 8 * 4);
					} else {
						bytes.readBytes(data, 0, boneNum * 12 * 4);
					}
					render.skinData[i][j] = data;
				}
			}
			// 读取帧数
			frameCount = bytes.readInt();
			// 读取绑定点数量
			num = bytes.readInt();
			var vec : Vector3D = new Vector3D();
			for (i = 0; i < num; i++) {
				var size : int = bytes.readInt();
				var name : String = bytes.readUTFBytes(size);
				for (j = 0; j < frameCount; j++) {
					// 读取绑定点数据
					var mt : Matrix3D = new Matrix3D();
					for (var k:int = 0; k < 3; k++) {
						vec.x = bytes.readFloat();
						vec.y = bytes.readFloat();
						vec.z = bytes.readFloat();
						vec.w = bytes.readFloat();
						mt.copyRowFrom(k, vec);
					}
					render.addMount(name, j, mt);
				}
			}
			return render as DefaultRender;
		}
	}
}

package core.utils {

	import flash.display.BitmapData;
	import flash.display3D.Context3DCompareMode;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import core.camera.Camera3D;
	import core.scene.Scene3D;
	import core.texture.Texture3D;

	public final class Device3D {
				
		/**
		 * 模型全局矩阵数据,每次渲染的时候会把渲染的当前模型的变形矩阵拷贝到这里
		 */
		public static const world : Matrix3D = new Matrix3D();
		/**
		 *  模型全局逆矩阵数据
		 */
		public static const invGlobal : Matrix3D = new Matrix3D();
		/**
		 * camera 矩阵数据
		 */
		public static const view : Matrix3D = new Matrix3D();
		/**
		 * camera 全局矩阵数据
		 */
		public static const cameraGlobal : Matrix3D = new Matrix3D();
		/**
		 * camera viewProj矩阵
		 */
		public static const viewProj : Matrix3D = new Matrix3D();
		/**
		 * camera worldViewProj矩阵
		 */
		public static const worldViewProj : Matrix3D = new Matrix3D();
		/**
		 * camera worldView矩阵
		 */
		public static const worldView : Matrix3D = new Matrix3D();
		/**
		 * camera proj矩阵
		 */
		public static const proj : Matrix3D = new Matrix3D();
		/**
		 * gpu支持模式
		 */
		public static var profile : String = "baseline";
		/**
		 * scene
		 */
		public static var scene : Scene3D;
		/**
		 * camera
		 */
		public static var camera : Camera3D;
		/**
		 * debug
		 */
		public static var debug : Boolean = true;
		/**
		 * 视口大小
		 */
		public static var viewPort : Rectangle;
		/** draw调用次数 */
		public static var drawCalls : int;
		/** 三角形绘制数量 */
		public static var trianglesDrawn : int;
		/** 模型绘制数量 */
		public static var objectsDrawn : int;
		/** 默认贴图 */
		public static var nullBitmapData : BitmapData = new BitmapData(64, 64, false, 0xFF0000);
		/** 最大贴图尺寸 */
		public static var maxTextureSize : int = 2048;
		/**
		 * 默认混合模式
		 */
		public static var defaultSourceFactor : String = "one";
		/**
		 * 默认混合模式
		 */
		public static var defaultDestFactor : String = "zero";
		/**
		 * 默认裁剪方式
		 */
		public static var defaultCullFace : String = "back";
		/**
		 * 默认深度测试 
		 */		
		public static var defaultDepthWrite	:	Boolean = true;
		/**
		 *  默认深度测试条件
		 */		
		public static var defaultCompare		:	String = Context3DCompareMode.LESS_EQUAL;
		/**
		 *	骨骼数据
		 */
		public static var bonesMatrices : ByteArray;
		// 初始化默认贴图
		private static var h : int = 0;
		private static var v : int;
		
		public static var defaultTexture:Texture3D;
		public static var boneNum:int;

		/**
		 * 初始化null bitmapdata
		 */
		while (h < 8) {
			v = 0;

			while (v < 8) {
				nullBitmapData.fillRect(new Rectangle(h * 8, v * 8, 8, 8), (((h % 2 + v % 2) % 2) == 0) ? 0xFFFFFF : 0xB0B0B0);
				v++;
			}
			h++;
		}
	}
}

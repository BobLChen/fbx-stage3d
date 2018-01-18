package core.base {

	import flash.geom.Matrix3D;
	
	/**
	 * 动画帧信息。
	 * @author neil
	 */
	public class Frame3D {
		
		/** 帧动画 */
		public static const TYPE_FRAME	: int = 0;
		/** 其它动画 */
		public static const TYPE_NULL	: int = 2;
		
		/** frame transform */
		public var transform	: Matrix3D;
		/** frame type */
		public var type 		: int = 0;
		/** frame回调函数 */
		public var func		: Function;
		
		public function Frame3D(v : Vector.<Number> = null, type : int = 0) {
			this.type 	   = type;
			if (type == TYPE_FRAME) {
				this.transform = new Matrix3D(v);
			}
		}
		
		public function clone() : Frame3D {
			var frame : Frame3D 	= new Frame3D(null, this.type);
			frame.func 			= this.func;
			return frame;
		}
	}
}

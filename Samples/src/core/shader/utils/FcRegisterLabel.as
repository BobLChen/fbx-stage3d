package core.shader.utils {

	import flash.geom.Matrix3D;
	import flash.utils.ByteArray;

	/**
	 * fc寄存器标签
	 * @author neil
	 */
	public class FcRegisterLabel {
		
		public var fc 		: ShaderRegisterElement;
		public var vector 	: Vector.<Number>;			// vector
		public var matrix 	: Matrix3D;					// matrix
		public var bytes 	: ByteArray;					// bytes
		public var num		: int;						// size

		public function FcRegisterLabel(fc : ShaderRegisterElement, vec : Vector.<Number> = null, mt : Matrix3D = null, byte : ByteArray = null) {
			this.fc 		= fc;
			this.vector	= vec;
			this.matrix 	= mt;
			this.bytes 	= byte;
			
			if (vector != null) {
				this.num = vec.length / 4;
			} else if (matrix != null) {
				this.num = 1;
			} else {
				this.num = this.bytes.length / 4 / 4;
			}
		}
		
		public function dispose() : void {
			fc 		= null;
			bytes 	= null;
			matrix 	= null;
			vector 	= null;
		}
	}
}

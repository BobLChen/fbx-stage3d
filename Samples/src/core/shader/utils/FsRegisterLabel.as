package core.shader.utils {
	import core.texture.Texture3D;

	

	/**
	* fs寄存器标签
	* @author neil
	*
	*/
	public class FsRegisterLabel {
		
		public var fs : ShaderRegisterElement;
		public var texture : Texture3D;

		public function FsRegisterLabel(fs : ShaderRegisterElement, texture : Texture3D) {
			this.fs = fs;
			this.texture = texture;
		}

		public function dispose() : void {
			fs = null;
			texture = null;
		}

	}
}

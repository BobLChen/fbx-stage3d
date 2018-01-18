package core.shader.filter {

	import core.base.Geometry3D;
	import core.scene.Scene3D;
	import core.shader.utils.FsRegisterLabel;
	import core.shader.utils.ShaderRegisterCache;
	import core.shader.utils.ShaderRegisterElement;
	import core.texture.Texture3D;
	
	/**
	 * @author neil
	 */	
	public class TextureMapFilter extends Filter3D {
				
		private var _texture : Texture3D;
		private var _fsLabel : FsRegisterLabel;
		
		public function TextureMapFilter(texture : Texture3D) {
			super('TextureMapFilter');
			if (texture == null) {
				this._texture = new Texture3D();
			} else {
				this._texture = texture;
			}
		}
		public function get texture() : Texture3D {
			return _texture;
		}
		
		public function set texture(texture : Texture3D) : void {
			_texture = texture;
			_fsLabel.texture = _texture;
		}
		
		override public function download():void {
			this.texture.download();
		}
		
		override public function upload(scene:Scene3D):void {
			this.texture.upload(scene);
		}
		
		override public function dispose():void {
			this.texture.dispose();
		}
		
		override public function getFragmentCode(regCache:ShaderRegisterCache):String {
			var fs : ShaderRegisterElement = regCache.getFs();
			_fsLabel = new FsRegisterLabel(fs, this._texture);
			regCache.fsUsed.push(_fsLabel);
			var code : String = '';
			code += 'tex ' + regCache.oc + ', ' + regCache.getV(Geometry3D.UV0) + ', ' + fs + getTextureDescription(texture) + ' \n';
			return code;
		}
		
	}
}
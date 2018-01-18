package core.shader.filter {
	import core.scene.Scene3D;
	import core.texture.Texture3D;
	import core.shader.utils.ShaderRegisterCache;

	

	/**
	 * shader 段程序。一个shader由多个filter组成。|
	 * ：
	 * 1、priority：权重，决定filter的组织顺序。权重越大越靠前组装。filter的顺序也决定了shader的最终效果。组织顺序根据快速排序法排列
	 * 2、upload  ：在filter里面的texture上传全部都是在upload里面上传
	 * 3、download:卸载
	 * 4、getFragmentCode：获取fragment程序。注意fragment优先于vertex程序生成。因为fragment里面决定了vertex需要传入什么数据。
	 * 5、getVertexAGALCode:获取vertex程序。注意vertex后于fragment程序生成。即：当使用v变量时，通过寄存器cache初始化时，这个过程必须放在
	 * fragment函数里面进行。
	 * @author neil
	 *
	 */
	public class Filter3D {
		
		public var name : String = 'default filter';
		/**
		 * 权重，决定filter的组织顺序，权重越大，越靠前组装
		 */
		public var priority : int = 0;

		public function upload(scene : Scene3D) : void {
			
		}

		public function dispose() : void {

		}

		public function download() : void {

		}

		/**
		 *  在模型每一次draw之前就会调用update方法。可以在update里面动态修改传入的常量值
		 */
		public function update() : void {

		}

		/**
		 * fragment程序会最先生成，因为fragment会需求vertex程序传入数据。因此只有当fragment生成完毕之后，vertex程序才
		 * 知道fragment会需求什么样的数据，vertex程序才会决定传给fragment什么数据。因此：【注意--->】使用V变量寄存的时候。V变量的初始化
		 * 是在fragment中初始化的。
		 * @param regCache
		 * @return
		 *
		 */
		public function getFragmentCode(regCache : ShaderRegisterCache) : String {
			return '';
		}

		/**
		 *
		 * @param regCache
		 * @return
		 *
		 */
		public function getVertexCode(regCache : ShaderRegisterCache) : String {
			return '';
		}
		
		public function Filter3D(name : String = 'defult filter') {
			this.name = name;
		}

		/**
		 * 获取texture的描述。例如：<2d, nearfilter, mip, wrap>
		 * @param texture
		 * @return
		 */
		protected function getTextureDescription(texture : Texture3D) : String {
			return ' <' + texture.typeMode + ', ' + texture.filterMode + ', ' + texture.mipMode + ', ' + texture.wrapMode + '>';
		}

	}
}

package core.shader.filter {
	import core.shader.utils.FcRegisterLabel;
	import core.shader.utils.ShaderRegisterCache;
	import core.shader.utils.ShaderRegisterElement;
	
	/**
	 * 纯色filter
	 * @author neil
	 */	
	public class ColorFilter extends Filter3D {
		
		private var datas  : Vector.<Number> = Vector.<Number>([1, 1, 1, 1]);
 		private var _color : uint;
		private var _alpha : Number;		
		/**
		 *  
		 * @param color		颜色
		 * @param alpha		透明度
		 * 
		 */		
		public function ColorFilter(color : uint = 0x555555, alpha : Number = 1) {
			super('color');
			this.priority = 19;
			this.color = color;
			this.alpha = alpha;			
		}
				
		override public function getFragmentCode(regCache : ShaderRegisterCache) : String {
			var fc0 : ShaderRegisterElement = regCache.getFc();
			regCache.fcUsed.push(new FcRegisterLabel(fc0, datas));
			return 'mov ' + regCache.oc + '.xyzw, ' + fc0 + '.xyzw \n';;
		}
		
		/**
		 * rgb色 
		 * @return 
		 * 
		 */		
		public function get color() : uint {
			return _color;
		}
		
		/**
		 * @param value	rgb
		 */		
		public function set color(value : uint) : void {
			datas[0] = ((value >> 16) & 0xFF) / 0xFF;
			datas[1] = ((value >> 8) & 0xFF) / 0xFF;
			datas[2] = (value & 0xFF) / 0xFF;
			_color = value;
		}
		
		/**
		 * 设置alpha 
		 * @param value
		 * 
		 */		
		public function set alpha(value : Number) : void {
			_alpha = value;
			datas[3] = _alpha;
		}
		
		public function get alpha() : Number {
			return _alpha;
		}

	}
}
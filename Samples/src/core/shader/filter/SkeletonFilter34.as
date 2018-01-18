package core.shader.filter {

	import core.base.Geometry3D;
	import core.shader.utils.ShaderRegisterCache;
	import core.shader.utils.ShaderRegisterElement;

	/**
	 * 3x4矩阵骨骼动画filter
	 * @author neil
	 *
	 */
	public class SkeletonFilter34 extends Filter3D {
		
		public function SkeletonFilter34(name : String = "SkeletonFilter34") {
			super(name);
			priority = 1000;
		}

		override public function getVertexCode(regCache : ShaderRegisterCache) : String {
			
			var idxVa : ShaderRegisterElement = regCache.getVa(Geometry3D.SKIN_INDICES);
			var weiVa : ShaderRegisterElement = regCache.getVa(Geometry3D.SKIN_WEIGHTS);
			
			var temp : ShaderRegisterElement = regCache.getVt();
			var idx : int = regCache.boneVcs.index;
			
			var code : String = '';
			code += 'mov ' + regCache.op + '.xyz, ' + regCache.vc0123 + '.xxx \n';
			
			code += 'm34 ' + temp + '.xyz, ' + regCache.getVa(Geometry3D.POSITION) + ', ' + 'vc[' + idxVa + '.x+' + idx + '].xyzw \n';
			code += 'mul ' + temp + '.xyz, ' + temp + '.xyz, ' + weiVa + '.xxx \n';
			code += 'add ' + regCache.op + '.xyz, ' + regCache.op + '.xyz, ' + temp + '.xyz \n';
			
			code += 'm34 ' + temp + '.xyz, ' + regCache.getVa(Geometry3D.POSITION) + ', ' + 'vc[' + idxVa + '.y+' + idx + '].xyzw \n';
			code += 'mul ' + temp + '.xyz, ' + temp + '.xyz, ' + weiVa + '.yyy \n';
			code += 'add ' + regCache.op + '.xyz, ' + regCache.op + '.xyz, '+ temp + '.xyz \n';
			
			code += 'm34 ' + temp + '.xyz, ' + regCache.getVa(Geometry3D.POSITION) + ', ' + 'vc[' + idxVa + '.z+' + idx + '].xyzw \n';
			code += 'mul ' + temp + '.xyz, ' + temp + '.xyz, ' + weiVa + '.zzz \n';
			code += 'add ' + regCache.op + '.xyz, ' + regCache.op + '.xyz, ' + temp + '.xyz \n';
			
			code += 'm34 ' + temp + '.xyz, ' + regCache.getVa(Geometry3D.POSITION) + ', ' + 'vc[' + idxVa + '.w+' + idx + '].xyzw \n';
			code += 'mul ' + temp + '.xyz, ' + temp + '.xyz, ' + weiVa + '.www \n';
			code += 'add ' + regCache.op + '.xyz, ' + regCache.op + '.xyz, ' + temp + '.xyz \n';
						
			regCache.removeFt(temp);
			return code;
		}

	}
}

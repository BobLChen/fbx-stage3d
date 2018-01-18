package core.shader.filter {

	import core.base.Geometry3D;
	import core.shader.filter.Filter3D;
	import core.shader.utils.ShaderRegisterCache;
	import core.shader.utils.ShaderRegisterElement;
	import core.shader.utils.VcRegisterLabel;
		
	/**
	 * 骨骼动画filter
	 * @author neil
	 */
	public class SkeletonFilterQuat extends Filter3D {

		// 骨骼常量寄存器
		private var data : Vector.<Number>;

		public function SkeletonFilterQuat(name : String = "defult filter") {
			super(name);
			this.data = Vector.<Number>([1, 0, 0, 0])
			this.priority = 1000;
		}

		override public function getVertexCode(regCache : ShaderRegisterCache) : String {

			// 设置骨骼vc偏移
			data[3] = regCache.boneVcs.index;

			var vc123 : ShaderRegisterElement = regCache.getVc();
			regCache.vcUsed.push(new VcRegisterLabel(vc123, data));
			
			var indexVa : Vector.<String> = Vector.<String>([
				regCache.getVa(Geometry3D.SKIN_INDICES) + '.x', 
				regCache.getVa(Geometry3D.SKIN_INDICES) + '.y', 
				regCache.getVa(Geometry3D.SKIN_INDICES) + '.z', 
				regCache.getVa(Geometry3D.SKIN_INDICES) + '.w'
			]);
			var weightVa : Vector.<String> = Vector.<String>([
				regCache.getVa(Geometry3D.SKIN_WEIGHTS) + '.x', 
				regCache.getVa(Geometry3D.SKIN_WEIGHTS) + '.y', 
				regCache.getVa(Geometry3D.SKIN_WEIGHTS) + '.z', 
				regCache.getVa(Geometry3D.SKIN_WEIGHTS) + '.w'
			]);
			
			var vt0 : ShaderRegisterElement = regCache.getVt();
			var vt1 : ShaderRegisterElement = regCache.getVt();
			var vt2 : ShaderRegisterElement = regCache.getVt();
			var vt3 : ShaderRegisterElement = regCache.getVt();
			var vt4 : ShaderRegisterElement = regCache.getVt();
			var vt5 : ShaderRegisterElement = regCache.getVt();
			var vt6 : ShaderRegisterElement = regCache.getVt();

			var vertexCode : String = '';
			
			for (var i : int = 0; i < 4; i++) {
				// 申请vt0
				// 取出位移信息vt0
				// 获取vc骨骼位置偏移量
				vertexCode += 'add ' + vt1 + '.x, ' + indexVa[i] + ', ' + vc123 + '.w \n';
				vertexCode += 'mov ' + vt0 + ', vc[' + vt1 + '.x' + '] \n';
				// 取出四元数 vt1 = 四元数
				vertexCode += 'mov ' + vt1 + ', vc[' + vt1 + '.x' + '+1] \n';
				// 将四元数转化为matrix3x3
				// [ 1-2yy-2zz , 2xy-2wz , 2xz+2wy ]
				// [ 2xy+2wz , 1-2xx-2zz , 2yz-2wx ]
				// [ 2xz-2wy , 2yz+2wx , 1-2xx-2yy ]
				// 计算2x 2y 2z
				// vt2 = 2x, 2y, 2z, w
				vertexCode += 'add ' + vt2 + '.xyz, ' + vt1 + '.xyz, ' + vt1 + '.xyz \n';
				// 计算vt3 = 2xw 2yw 2zw
				vertexCode += 'mul ' + vt3 + '.xyz, ' + vt2 + '.xyz, ' + vt1 + '.w \n';
				// 计算vt4 = 2xx 2yx 2zx
				vertexCode += 'mul ' + vt4 + '.xyz, ' + vt2 + '.xyz, ' + vt1 + '.x \n';
				// 计算vt5 = 2yy 2zy 2zz
				vertexCode += 'mul ' + vt5 + '.xyz, ' + vt2 + '.yyz, ' + vt1 + '.yzz \n';

				// vt1 -> 计算[1-2yy-2zz , 2xy-2wz , 2xz+2wy]
				// vt1.x = 2yy+2zz
				vertexCode += 'add ' + vt1 + '.x, ' + vt5 + '.x, ' + vt5 + '.z \n';
				// vt1.x = 1 - 2yy - 2zz
				vertexCode += 'sub ' + vt1 + '.x, ' + vc123 + '.x, ' + vt1 + '.x \n';
				// vt1.y = 2xy - 2wz
				vertexCode += 'sub ' + vt1 + '.y, ' + vt4 + '.y, ' + vt3 + '.z \n';
				// vt1.z = 2xz + 2wy
				vertexCode += 'add ' + vt1 + '.z, ' + vt4 + '.z, ' + vt3 + '.y \n';

				// vt2 -> 计算[2xy+2wz , 1-2xx-2zz , 2yz-2wx]
				// vt2.x = 2xy + 2wz
				vertexCode += 'add ' + vt2 + '.x, ' + vt4 + '.y, ' + vt3 + '.z \n';
				// vt2.y = 2xx + 2zz
				vertexCode += 'add ' + vt2 + '.y, ' + vt4 + '.x, ' + vt5 + '.z \n';
				// vt2.y = 1-2xx-2zz
				vertexCode += 'sub ' + vt2 + '.y, ' + vc123 + '.x, ' + vt2 + '.y \n';
				// vt2.z = 2yz-2wx
				vertexCode += 'sub ' + vt2 + '.z, ' + vt5 + '.y, ' + vt3 + '.x \n';

				// vt6 -> 计算[2xz-2wy , 2yz+2wx , 1-2xx-2yy]
				// vt6.x = 2xz - 2wy
				vertexCode += 'sub ' + vt6 + '.x, ' + vt4 + '.z, ' + vt3 + '.y \n';
				// vt6.y = 2yz + 2wx
				vertexCode += 'add ' + vt6 + '.y, ' + vt5 + '.y, ' + vt3 + '.x \n';
				// vt6.z = 2xx + 2yy
				vertexCode += 'add ' + vt6 + '.z, ' + vt4 + '.x, ' + vt5 + '.x \n';
				// vt6.z = 1 - 2xx - 2yy
				vertexCode += 'sub ' + vt6 + '.z, ' + vc123 + '.x, ' + vt6 + '.z \n';

				// 添加位移信息vt0
				vertexCode += 'mov ' + vt1 + '.w, ' + vt0 + '.x \n';
				vertexCode += 'mov ' + vt2 + '.w, ' + vt0 + '.y \n';
				vertexCode += 'mov ' + vt6 + '.w, ' + vt0 + '.z \n';

				// 顶点乘以矩阵
				vertexCode += 'dp4 ' + vt0 + '.x, ' + regCache.getVa(Geometry3D.POSITION) + ', ' + vt1 + ' \n';
				vertexCode += 'dp4 ' + vt0 + '.y, ' + regCache.getVa(Geometry3D.POSITION) + ', ' + vt2 + ' \n';
				vertexCode += 'dp4 ' + vt0 + '.z, ' + regCache.getVa(Geometry3D.POSITION) + ', ' + vt6 + ' \n';
				vertexCode += 'mov ' + vt0 + '.w, ' + regCache.getVa(Geometry3D.POSITION) + '.w \n';

				vertexCode += 'mul ' + vt0 + ', ' + vt0 + ', ' + weightVa[i] + ' \n';

				if (i == 0) {
					vertexCode += 'mov ' + regCache.op + ', ' + vt0 + ' \n';
				} else {
					vertexCode += 'add ' + regCache.op + ', ' + regCache.op + ', ' + vt0 + ' \n';
				}
			}
			
			regCache.removeVt(vt0);
			regCache.removeVt(vt1);
			regCache.removeVt(vt2);
			regCache.removeVt(vt3);
			regCache.removeVt(vt4);
			regCache.removeVt(vt5);
			regCache.removeVt(vt6);
			
			return vertexCode;
		}

	}
}

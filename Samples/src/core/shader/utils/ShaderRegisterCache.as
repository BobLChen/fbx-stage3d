package core.shader.utils {
	import core.utils.Device3D;
	
	
	/**
	 * @author neil
	 */
	public class ShaderRegisterCache {
		
		/** 使用的fs寄存器 */
		public var fsUsed : Vector.<FsRegisterLabel>;
		/** 使用的vc寄存器 */
		public var vcUsed : Vector.<VcRegisterLabel>;
		/** 使用的fc寄存器 */
		public var fcUsed : Vector.<FcRegisterLabel>;
		
		private var _ftPool 	: RegisterPool;						// ft
		private var _vtPool 	: RegisterPool;						// vt
		private var _vPool 	: RegisterPool;						// v
		private var _fcPool 	: RegisterPool;						// fc
		private var _vcPool 	: RegisterPool;						// vc
		private var _fsPool 	: RegisterPool;						// fs
		private var _vaPool 	: RegisterPool;						// va
		private var _op 		: ShaderRegisterElement;				// oc
		private var _oc 		: ShaderRegisterElement;				// op
		private var _vas   	: Vector.<ShaderRegisterElement>;	// va顶点流
		private var _varys 	: Vector.<ShaderRegisterElement>;	// v
		private var _vc0123	: ShaderRegisterElement;				// fs0123
		private var _fc0123	: ShaderRegisterElement;				// fc0123
		private var _vcMvp  : ShaderRegisterElement;				// mvp
		
		private var _bonesVc : ShaderRegisterElement = null;
		private var _hasBone : Boolean = false;
		
		public function ShaderRegisterCache() {
			reset();
		}
		
		public function get hasBone():Boolean {
			return _hasBone;
		}

		public function get boneVcs():ShaderRegisterElement {
			if (_bonesVc == null) {
				for (var i:int = 0; i < Device3D.boneNum; i++) {
					if (i == 0) {
						_bonesVc = getVc();
						getVc();
					} else {
						getVc();
						getVc();
					}
				}
				this._hasBone = true;
			}
			return _bonesVc;
		}
		
		/**
		 * Resets all registers.
		 */
		public function reset() : void {
			_vc0123	= null;
			_fc0123	= null;
			_op		= null;
			_oc		= null;
			_vas 	= new Vector.<ShaderRegisterElement>(14, true);
			_varys  = new Vector.<ShaderRegisterElement>(14, true);
			_ftPool 	= new RegisterPool("ft", 8);
			_vtPool 	= new RegisterPool("vt", 8);
			_vPool 	= new RegisterPool("v", 8);
			_fsPool 	= new RegisterPool("fs", 8);
			_vaPool 	= new RegisterPool("va", 8);
			_fcPool 	= new RegisterPool("fc", 28);
			_vcPool 	= new RegisterPool("vc", 128);
//			_op 		= new ShaderRegisterElement("oc", -1);
//			_oc 		= new ShaderRegisterElement("op", -1);
			fsUsed 	= new Vector.<FsRegisterLabel>();
			vcUsed 	= new Vector.<VcRegisterLabel>();
			fcUsed 	= new Vector.<FcRegisterLabel>();
		}
		
		public function dispose() : void {

			_ftPool.dispose();
			_vtPool.dispose();
			_vPool.dispose();
			_fcPool.dispose();
			_vaPool.dispose();
			_ftPool = null;
			_vtPool = null;
			_vPool = null;
			_fcPool = null;
			_vaPool = null;
			_op = null;
			_oc = null;
			
			for each (var fsLabel : FsRegisterLabel in fsUsed) {
				fsLabel.dispose();
			}
			fsUsed.length = 0;
			fsUsed = null;
			
			for each (var vcLabel : VcRegisterLabel in vcUsed) {
				vcLabel.dispose();
			}
			vcUsed.length = 0;
			vcUsed = null;
			
			for each (var fcLabel : FcRegisterLabel in fcUsed) {
				fcLabel.dispose();
			}
			fcUsed.length = 0;
			fcUsed = null;
		}
		
		/**
		 * 获取fc0123 
		 * @return 
		 * 
		 */		
		public function get fc0123() : ShaderRegisterElement {
			if (_fc0123 == null) {
				_fc0123 = getFc();
				fcUsed.push(new FcRegisterLabel(_fc0123, Vector.<Number>([0, 1, 2, 3])));
			}
			return _fc0123;
		}
		
		/**
		 * 获取vc0123 
		 * @return 
		 * 
		 */		
		public function get vc0123() : ShaderRegisterElement {
			if (_vc0123 == null) {
				_vc0123 = getVc();
				vcUsed.push(new VcRegisterLabel(_vc0123, Vector.<Number>([0, 1, 2, 3])));
			}
			return _vc0123;
		}
		
		/**
		 * 获取mvp vc寄存器 
		 * @return 
		 * 
		 */		
		public function get vcMvp() : ShaderRegisterElement {
			if (_vcMvp == null) {
				_vcMvp = getVc();
				getVc();
				getVc();
				getVc();
			}
			return _vcMvp;
		}
		
		/**
		 * 获取所有的va寄存器 
		 * @return 
		 * 
		 */		
		public function get vas() : Vector.<ShaderRegisterElement> {
			return _vas;
		}
		
		/**
		 * 获取所有的v寄存器 
		 * @return 
		 * 
		 */		
		public function get varys() : Vector.<ShaderRegisterElement> {
			return _varys;
		}
		
		/**
		 * 缓存ft
		 * @param ft
		 * 
		 */		
		public function removeFt(ft : ShaderRegisterElement) : void {
			_ftPool.removeUsage(ft);
		}
		
		/**
		 * 缓存vt 
		 * @param register
		 * 
		 */		
		public function removeVt(register : ShaderRegisterElement) : void {
			_vtPool.removeUsage(register);
		}
		
		/**
		 * 获取一个ft 
		 * @return 
		 * 
		 */		
		public function getFt() : ShaderRegisterElement {
			return _ftPool.requestFreeVectorReg();
		}
		
		/**
		 * 获取一个fc 
		 * @return 
		 * 
		 */		
		public function getFc() : ShaderRegisterElement {
			return _fcPool.requestFreeVectorReg();
		}
		
		/**
		 * 获取一个vc 
		 * @return 
		 * 
		 */		
		public function getVc() : ShaderRegisterElement {
			return _vcPool.requestFreeVectorReg();
		}
		
		/**
		 * 获取一个vt 
		 * @return 
		 * 
		 */		
		public function getVt() : ShaderRegisterElement {
			return _vtPool.requestFreeVectorReg();
		}
		
		/**
		 * 获取一个V 
		 * @param		type		类型
		 * @return 
		 * 
		 */		
		public function getV(type : int) : ShaderRegisterElement {
			if (_varys[type] == null) {
				_varys[type] = _vPool.requestFreeVectorReg();
			}
			return _varys[type];
		}
		
		public function getFreeV() : ShaderRegisterElement {
			return _vPool.requestFreeVectorReg();
		}
		
		/**
		 * 获取一个Va 
		 * @param		type		类型
		 * @return 
		 * 
		 */		
		public function getVa(type : int) : ShaderRegisterElement {
			if (_vas[type] == null) {
				_vas[type] = _vaPool.requestFreeVectorReg();
			}
			return _vas[type];
		}
		
		public function getFreeVa() : ShaderRegisterElement {
			return _vaPool.requestFreeVectorReg();
		}
		
		/**
		 * 获取一个fs 
		 * @return 
		 * 
		 */		
		public function getFs() : ShaderRegisterElement {
			return _fsPool.requestFreeVectorReg();
		}
		
		public function get op() : ShaderRegisterElement {
			if (_op == null) {
				_op = getVt();
			}
			return _op;
		}

		public function get oc() : ShaderRegisterElement {
			if (_oc == null) {
				_oc = getFt();
			}
			return _oc;
		}
		
	}
}

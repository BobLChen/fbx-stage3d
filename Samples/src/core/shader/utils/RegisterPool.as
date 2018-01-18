package core.shader.utils {

	/**
	 * @author neil
	 */
	internal class RegisterPool {
		
		private var _vectorRegisters	: Vector.<ShaderRegisterElement>;	// 空闲寄存器	
				
		/**
		 * @param regName		寄存器名称
		 * @param regCount		寄存器数量
		 * 
		 */		
		public function RegisterPool(regName : String, regCount : int) {
			_vectorRegisters = new Vector.<ShaderRegisterElement>(regCount);
			for (var i : int = 0; i < regCount; ++i) {
				_vectorRegisters[i] = new ShaderRegisterElement(regName, i);
			}
		}
		
		/**
		 * 申请空闲寄存器
		 */
		public function requestFreeVectorReg() : ShaderRegisterElement {
			if (_vectorRegisters.length == 0) {
				throw new Error("Register overflow!");
			}
			return _vectorRegisters.shift();
		}
		
		/**
		 * 回收寄存器 
		 * @param register
		 * 
		 */		
		public function removeUsage(register : ShaderRegisterElement) : void {
			_vectorRegisters.push(register);
		}

		public function dispose() : void {
			_vectorRegisters = null;
		}
		
		/**
		 * 是否有空闲寄存器 
		 * @return 
		 * 
		 */		
		public function hasRegisteredRegs() : Boolean {
			return _vectorRegisters.length > 0 ? true : false;
		}
				
	}
}

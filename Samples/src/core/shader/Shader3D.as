package core.shader {

	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Program3D;
	import flash.events.Event;
	
	import core.base.Geometry3D;
	import core.base.Pivot3D;
	import core.scene.Scene3D;
	import core.shader.filter.Filter3D;
	import core.shader.utils.FcRegisterLabel;
	import core.shader.utils.FsRegisterLabel;
	import core.shader.utils.ShaderRegisterCache;
	import core.shader.utils.ShaderRegisterElement;
	import core.shader.utils.VcRegisterLabel;
	import core.utils.Device3D;
	import core.utils.FilterQuickSortUtils;
	
	/**
	 * shader
	 * @author neil
	 */
	public class Shader3D {
		
		public static const BLEND_NONE 			: String = 'BLEND_NONE';
		public static const BLEND_ADDITIVE 		: String = 'BLEND_ADDITIVE';
		public static const BLEND_ALPHA_BLENDED 	: String = 'BLEND_ALPHA_BLENDED';
		public static const BLEND_MULTIPLY 		: String = 'BLEND_MULTIPLY';
		public static const BLEND_SCREEN 		: String = 'BLEND_SCREEN';
		public static const BLEND_ALPHA 			: String = 'BLEND_ALPHA';
		
		public  var name 			: String;
		private var regCache 		: ShaderRegisterCache;					// 寄存器
		private var _filters 		: Vector.<Filter3D>;						// filters
		private var _program 		: Program3D;								// GPU指令
		private var _scene 			: Scene3D;								// scene
		private var _depthPass		: Shader3D;								// 深度shader
		private var _sourceFactor	: String;								// 混合模式
		private var _destFactor		: String;								// 混合模式
		private var _depthWrite 		: Boolean;								// 开启深度
		private var _depthCompare 	: String;								// 深度测试
		private var _cullFace 		: String;								// 裁剪
		private var _blendMode 		: String = BLEND_NONE;					// 混合模式
		private var _stateDirty		: Boolean = false;						// GPU状态
		private var _programDirty	: Boolean = true;						// GPU指令
		private var _disposed		: Boolean = false;						// 是否已经被dispose
		
		/**
		 * shader3d
		 * @param name		shader名称
		 * @param filters	filters
		 *
		 */
		public function Shader3D(name : String = "", fters : Array = null) {
			fters = (fters == null) ? [] : fters;
			
			this.name 			= name;
			this._depthWrite  	= true;
			this._depthCompare	= Device3D.defaultCompare;
			this._cullFace	 	= Device3D.defaultCullFace;
			this._sourceFactor	= Device3D.defaultSourceFactor;
			this._destFactor		= Device3D.defaultDestFactor;
			this._filters 		= Vector.<Filter3D>(fters);
		}
				
		/**
		 * 是否已经被释放 
		 * @return 
		 * 
		 */		
		public function get disposed():Boolean {
			return _disposed;
		}

		/** 裁剪 */
		public function get cullFace():String {
			return _cullFace;
		}

		/**
		 * @private
		 */
		public function set cullFace(value:String):void {
			_cullFace = value;
			this.validateState();
		}

		/** 深度测试条件 */
		public function get depthCompare():String {
			return _depthCompare;
		}

		/**
		 * @private
		 */
		public function set depthCompare(value:String):void {
			_depthCompare = value;
			this.validateState();
		}

		/** 深度测试 */
		public function get depthWrite():Boolean {
			return _depthWrite;
		}

		/**
		 * @private
		 */
		public function set depthWrite(value:Boolean):void {
			_depthWrite = value;
			this.validateState();
		}

		/** 混合模式->destFactor */
		public function get destFactor():String {
			return _destFactor;
		}
		
		/**
		 * @private
		 */
		public function set destFactor(value:String):void {
			_destFactor 	= value;
			this.validateState();
		}

		/** 混合模式->sourceFactor */
		public function get sourceFactor():String {
			return _sourceFactor;
		}

		/**
		 * @private
		 */
		public function set sourceFactor(value:String):void {
			_sourceFactor = value;
			this.validateState();
		}
				
		/**
		 * 通过名称获取Filter 
		 * @param name	filter名称
		 * @return 
		 * 
		 */		
		public function getFilterByName(name : String) : Filter3D {
			for each (var filter : Filter3D in _filters) {
				if (filter.name == name)
					return filter;
			}
			return null;
		}
		
		/**
		 * 通过类型获取Fitler
		 * @param clazz	类型
		 * @return 
		 * 
		 */		
		public function getFilterByClass(clazz : Class) : Filter3D {
			for each (var filter : Filter3D in _filters) {
				if (filter is clazz)
					return filter;
			}
			return null;
		}
		
		/**
		 * 所有filter 
		 * @return 
		 */		
		public function get filters() : Vector.<Filter3D> {
			return _filters;
		}
		
		/**
		 * 移除filter 
		 * @param filter
		 */		
		public function removeFilter(filter : Filter3D) : void {
			var index : int = _filters.indexOf(filter);
			if (index == -1) {
				return;
			}
			_programDirty = true;
			_filters.splice(index, 1);
		}
		
		/**
		 * 添加filter 
		 * @param filter
		 */		
		public function addFilter(filter : Filter3D) : void {
			if (_filters.indexOf(filter) != -1) {
				return;
			}
			_filters.push(filter);
			_programDirty = true;
		}
		
		/**
		 * 上传 
		 * @param scene			scene
		 * 
		 */		
		public function upload(scene : Scene3D) : void {
			if (scene == null) {
				throw new Error("scene can't be null");
			}
			if (_programDirty == false) {
				return;
			}
			this._scene = scene;
			if (scene.context != null) {
				this.context3DEvent();
			}
			scene.addEventListener(Event.CONTEXT3D_CREATE, context3DEvent);
		}
				
		/**
		 * 创建program程序并上传 
		 * @param e
		 * 
		 */		
		private function context3DEvent(e : Event = null) : void {
			// build
			this.build();
			// upload filters
			for each (var filter : Filter3D in filters) {
				filter.upload(scene);
			}
		}
		
		/**
		 * build shader程序
		 */
		public function build() : void {
			_programDirty = true;
			if (scene == null) {
				return;
			}
			if (regCache != null) {
				regCache.dispose();
			}
			regCache = new ShaderRegisterCache();
			// 对filter排序
			FilterQuickSortUtils.sortByPriorityAsc(_filters, 0, _filters.length - 1);
			var fragCode		: String = buildFragmentCode();		// 组装fragment shader
			var vertexCode	: String = buildVertexCode();		// 组装vertex shader
			// 编译指令
			var vertexAgal	: AGALMiniAssembler = new AGALMiniAssembler();
			vertexAgal.assemble(Context3DProgramType.VERTEX, vertexCode);
			var fragAgal		: AGALMiniAssembler = new AGALMiniAssembler();
			fragAgal.assemble(Context3DProgramType.FRAGMENT, fragCode);
			// debug
			if (Device3D.debug) {
				trace('---------程序开始------------');
				trace('---------顶点程序------------');
				trace(vertexCode);
				trace('---------片段程序------------');
				trace(fragCode);
				trace('---------程序结束------------');
			}
			if (this._program != null) {
				this._program.dispose();
				this._program = null;
			}
			// 创建program
			this._program = scene.context.createProgram();
			// 上传指令
			this._program.upload(vertexAgal.agalcode, fragAgal.agalcode);
			this._programDirty = false;
		}
		
		/**
		 * 生成片段程序
		 * @return
		 *
		 */
		private function buildFragmentCode() : String {
			var code : String = "";
			code += "mov " + regCache.oc + ", " + regCache.fc0123 + ".yyyy \n";
			for each (var filter : Filter3D in filters) {
				code += filter.getFragmentCode(regCache);
			}
			code += "mov oc, " + regCache.oc + " \n";
			return code;
		}
		
		/**
		 * 生成顶点程序
		 * @return
		 */
		private function buildVertexCode() : String {
			var code : String = "mov " + regCache.op + ", " + regCache.getVa(Geometry3D.POSITION) + " \n";
			for each (var filter : Filter3D in filters) {
				code += filter.getVertexCode(regCache);
			}
			// V
			var length : int = regCache.varys.length;
			for (var i:int = 0; i < length; i++) {
				var vary : ShaderRegisterElement = regCache.varys[i];
				if (vary != null) {
					code += "mov " + vary + ", " + regCache.getVa(i) + " \n";
				}
			}
			code += "m44 op, " + regCache.op + ", " + regCache.vcMvp + " \n";
			return code;
		}
		
		/**
		 * 绘制 
		 * @param pivot			3d显示对象
		 * @param geometry		网格数据
		 * @param firstIndex		起始三角形
		 * @param count			三角形数量
		 * 
		 */		
		public function draw(pivot : Pivot3D, geometry : Geometry3D, firstIndex : int = 0, count : int = -1) : void {
			if (this._scene == null || _programDirty == true) {
				this.upload(pivot.scene);
			}
			if (geometry.scene == null) {
				geometry.upload(scene);
			}
			var context : Context3D = this.scene.context;
			// 修改混合、深度测试、裁减
			if (_stateDirty) {
				context.setBlendFactors(sourceFactor, destFactor);
				context.setDepthTest(depthWrite, depthCompare);
				context.setCulling(cullFace);
			}
			for each (var filter : Filter3D in filters) {
				filter.update();
			}
			// 设置program
			context.setProgram(_program);
			// 设置数据
			setContextDatas(context, geometry);
			// 绘制三角形
			context.drawTriangles(geometry.indexBuffer, firstIndex, count);
			// 清空数据
			clearContextDatas(context);
			// draw calls
			Device3D.drawCalls++;
			Device3D.trianglesDrawn += count;
			// 重置回默认状态
			if (_stateDirty) {
				context.setBlendFactors(Device3D.defaultSourceFactor, Device3D.defaultDestFactor);
				context.setDepthTest(Device3D.defaultDepthWrite, Device3D.defaultCompare);
				context.setCulling(Device3D.defaultCullFace);
			}
		}
		
		/**
		 * 清楚数据 
		 * @param context
		 * 
		 */		
		private function clearContextDatas(context : Context3D) : void {
			for each (var va : ShaderRegisterElement in regCache.vas) {
				if (va != null) {
					context.setVertexBufferAt(va.index, null);
				}
			}
			for each (var fs : FsRegisterLabel in regCache.fsUsed) {
				context.setTextureAt(fs.fs.index, null);
			}
		}
		
		/**
		 * 设置数据 
		 * @param context
		 * @param geometry
		 * 
		 */		
		private function setContextDatas(context : Context3D, geometry : Geometry3D) : void {
			// 设置va
			var i   : int = 0;
			var len : int = regCache.vas.length;
			for (i = 0; i < len; i++) {
				var va  : ShaderRegisterElement = regCache.vas[i];
				if (va != null) {
					var subGeo : Geometry3D = geometry.getSourceGeometry(i);
					context.setVertexBufferAt(va.index, subGeo.vertexBuffer, subGeo.offsets[i], subGeo.formats[i]);
				}
			}
			// mvp单独设置
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, regCache.vcMvp.index, Device3D.worldViewProj, true);
			// bone
			if (regCache.hasBone) {
				context.setProgramConstantsFromByteArray(Context3DProgramType.VERTEX, regCache.boneVcs.index, Device3D.boneNum * 2, Device3D.bonesMatrices, 0);
			}
			// 设置vc
			for each (var vcLabel : VcRegisterLabel in regCache.vcUsed) {
				if (vcLabel.vector != null) {
					// vector频率使用得最高
					context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vcLabel.vc.index, vcLabel.vector, vcLabel.num);
				} else if (vcLabel.matrix != null) {
					// matrix其次
					context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, vcLabel.vc.index, vcLabel.matrix, true);
				} else {
					// bytes最后
					context.setProgramConstantsFromByteArray(Context3DProgramType.VERTEX, vcLabel.vc.index, vcLabel.num, vcLabel.bytes, 0);
				}
			}
			// 设置fc
			for each (var fcLabel : FcRegisterLabel in regCache.fcUsed) {
				if (fcLabel.vector != null) {
					// vector频率使用得最高
					context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, fcLabel.fc.index, fcLabel.vector, fcLabel.num);
				} else if (fcLabel.matrix != null) {
					// matrix其次
					context.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, fcLabel.fc.index, fcLabel.matrix, true);
				} else {
					// bytes最后
					context.setProgramConstantsFromByteArray(Context3DProgramType.FRAGMENT, fcLabel.fc.index, fcLabel.num, fcLabel.bytes, 0);
				}
			}
			// 设置fs
			for each (var fsLabel : FsRegisterLabel in regCache.fsUsed) {
				context.setTextureAt(fsLabel.fs.index, fsLabel.texture.texture);
			}
		}
		
		/**
		 *  卸载
		 */		
		public function download() : void {
			if (_scene != null) {
				_scene.removeEventListener(Event.CONTEXT3D_CREATE, context3DEvent);
				_scene = null;
			}
			for each (var filter : Filter3D in _filters) {
				filter.download();
			}
			this._programDirty = true;
		}
		
		/**
		 * scene 
		 * @return 
		 */		
		public function get scene() : Scene3D {
			return this._scene;
		}
		
		/**
		 * 释放 
		 */		
		public function dispose() : void {
			if (disposed) {
				return;
			}
			this.download();
			for each (var filter : Filter3D in filters) {
				filter.dispose();
			}
			if (this._program != null) {
				this._program.dispose();
			}
			if (this.regCache != null) {
				this.regCache.dispose();
			}
			this._filters = null;
			this._disposed= true;
		}
		
		/**
		 * 透明 
		 * @return 
		 */		
		public function get transparent() : Boolean {
			return blendMode == BLEND_ALPHA ? true : false;
		}
		
		/**
		 * 透明 
		 * @param value
		 */		
		public function set transparent(value : Boolean) : void {
			if (value) {
				this.blendMode = BLEND_ALPHA;
			} else {
				this.blendMode = BLEND_NONE;
			}
		}
		
		/**
		 * 双面显示 
		 * @return 
		 */		
		public function get twoSided() : Boolean {
			return this.cullFace == Context3DTriangleFace.NONE;
		}
		
		/**
		 * 双面显示
		 * @param value
		 */
		public function set twoSided(value : Boolean) : void {
			if (value) {
				this.cullFace = Context3DTriangleFace.NONE;
			} else {
				this.cullFace = Context3DTriangleFace.BACK;
			}
			this.validateState();
		}
		
		/**
		 * 混合模式 
		 * @return 
		 * 
		 */		
		public function get blendMode() : String {
			return this._blendMode;
		}
		
		/**
		 * 设置混合模式
		 * @param value
		 */
		public function set blendMode(value : String) : void {
			if (_blendMode == value) {
				return;
			}
			this._blendMode = value;
			switch (this._blendMode) {
				case BLEND_NONE:
					this.sourceFactor 	= Context3DBlendFactor.ONE;
					this.destFactor 		= Context3DBlendFactor.ZERO;
					break;
				case BLEND_ADDITIVE:
					this.sourceFactor 	= Context3DBlendFactor.ONE;
					this.destFactor 		= Context3DBlendFactor.ONE;
					break;
				case BLEND_ALPHA_BLENDED:
					this.sourceFactor 	= Context3DBlendFactor.ONE;
					this.destFactor 		= Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
					break;
				case BLEND_MULTIPLY:
					this.sourceFactor 	= Context3DBlendFactor.DESTINATION_COLOR;
					this.destFactor 		= Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
					break;
				case BLEND_SCREEN:
					this.sourceFactor 	= Context3DBlendFactor.ONE;
					this.destFactor 		= Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR;
					break;
				case BLEND_ALPHA:
					this.sourceFactor 	= Context3DBlendFactor.SOURCE_ALPHA;
					this.destFactor 		= Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
					break;
			}
			this.validateState();
		}
		
		private function validateState() : void {
			this._stateDirty = true;
			if (this.sourceFactor 	== Device3D.defaultSourceFactor 	&&
				this.destFactor		== Device3D.defaultDestFactor	&&
				this.depthCompare	== Device3D.defaultCompare		&&
				this.depthWrite		== Device3D.defaultDepthWrite	&&
				this.cullFace		== Device3D.defaultCullFace) {
				this._stateDirty = false;
			}
		}
		
	}
}

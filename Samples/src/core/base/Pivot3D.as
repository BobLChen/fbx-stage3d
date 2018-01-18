package core.base {

	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import core.scene.Scene3D;
	import core.shader.Shader3D;
	import core.utils.Matrix3DUtils;
		
	/**
	 * 3D对象基类
	 * @author neil
	 */
	public class Pivot3D extends EventDispatcher {
		
		/** 循环动画 */
		public static const ANIMATION_LOOP_MODE 	: int 	= 0;
		/** 非循环动画 */
		public static const ANIMATION_STOP_MODE 	: int 	= 2;
		// 临时变量
		protected static var _temp0 : Vector3D = new Vector3D();
		
		/** 名称 */
		public var name 		: String;
		/** 动画标签 */
		public var labels 	: Dictionary;
		/** 帧信息 */
		public var frames 	: Vector.<Frame3D>;
		// scene
		protected var _scene 		: Scene3D;
		protected var _inScene 		: Boolean;
		protected var _world 		: Matrix3D;
		protected var _dirtyInv 		: Boolean = true;
		protected var _from 			: Number = 0;
		protected var _to 			: Number = 0;
		protected var _fps 			: Number = 30;
		protected var _fpsSpeed 		: Number = 1 / _fps;	
		
		private var _transform 		: Matrix3D;
		private var _dirty 			: Boolean = true;
		private var _vector 			: Vector3D;
		private var _children 		: Vector.<Pivot3D>;
		private var _visible 		: Boolean = true;
		private var _invGlobal 		: Matrix3D;
		private var _parent 			: Pivot3D;
		private var _currentFrame	: Number = -1;
		private var _frameSpeed 		: Number = 1;
		private var _isPlaying 		: Boolean = false;
		private var _lastFrame 		: Number;
		private var animationMode	: int = ANIMATION_LOOP_MODE; 
		
		public function Pivot3D(name : String = "") {
			this._transform 	= new Matrix3D();
			this.labels 		= new Dictionary();
			this._children 	= new Vector.<Pivot3D>();
			this._invGlobal 	= new Matrix3D();
			this._world 		= new Matrix3D();
			this.name 		= name;
		}
		
		/**
		 * 获取帧频 
		 * @return 
		 */		
		public function get fps():Number {
			return _fps;
		}
		
		/**
		 * 设置帧频 
		 * @param value
		 */		
		public function set fps(value:Number):void {
			_fps      = value;
			_fpsSpeed = 1 / _fps;
			var len : int = this.children.length;
			for (var i:int = 0; i < len; i++) {
				this.children[i].fps = value;
			}
		}
		
		public function get inScene() : Boolean {
			return _inScene;
		}

		/**
		 * 获取local 矩阵数据
		 * @return
		 */
		public function get transform() : Matrix3D {
			return _transform;
		}

		/**
		 * 设置local矩阵数据
		 * @param value
		 */
		public function set transform(value : Matrix3D) : void {
			_transform = value;
			this.updateTransforms(true);
		}
		
		/**
		 * 上传
		 * @param scene
		 * @param includeChildren
		 */
		public function upload(scene : Scene3D, includeChildren : Boolean = true) : void {
			this._scene = scene;
			if (includeChildren) {
				for each (var piv : Pivot3D in this._children) {
					piv.upload(scene, includeChildren);
				}
			}
		}
		
		/**
		 * 卸载
		 * @param includeChildren
		 */
		public function download(includeChildren : Boolean = true) : void {
			this._scene = null;
			if (includeChildren) {
				for each (var piv : Pivot3D in this._children) {
					piv.download(includeChildren);
				}
			}
		}
		
		/**
		 * 设置坐标
		 * @param x			x
		 * @param y			y
		 * @param z			z
		 * @param smooth		
		 * @param local		
		 *
		 */
		public function setPosition(x : Number, y : Number, z : Number, smooth : Number = 1) : void {
			_temp0.setTo(x, y, z);
			Matrix3DUtils.setPosition(this.transform, _temp0.x, _temp0.y, _temp0.z, smooth);
			this.updateTransforms(true);
		}
		
		/**
		 * 获取位移
		 * @param local		local?
		 * @param out		position
		 * @return 			position
		 */
		public function getPosition(local : Boolean = true, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.getPosition(local ? this.transform : this.world, out);
		}

		/**
		 * 设置缩放
		 * @param x	x轴缩放
		 * @param y	y轴缩放
		 * @param z	z轴缩放
		 * @param smooth	 插值
		 *
		 */
		public function setScale(x : Number, y : Number, z : Number, smooth : Number = 1) : void {
			Matrix3DUtils.setScale(this.transform, x, y, z, smooth);
			this.updateTransforms(true);
		}

		/**
		 * 获取缩放值
		 * @param local	标识是否获取local缩放值还是global缩放值
		 * @param out	写入数据，如果out为null会创建一个out
		 * @return
		 *
		 */
		public function getScale(local : Boolean = true, out : Vector3D = null) : Vector3D {
			out = Matrix3DUtils.getScale(local ? this.transform : this.world, out);
			return out;
		}
		
		/**
		 * 设置角度
		 * @param x
		 * @param y
		 * @param z
		 *
		 */
		public function setRotation(x : Number, y : Number, z : Number) : void {
			Matrix3DUtils.setRotation(this.transform, x, y, z);
			this.updateTransforms(true);
		}

		/**
		 * 该方式是以欧拉角得方式获取，因此获取的角度值为-90到90范围。
		 * 如果想要以360度方式获取，或者其他方式。自己在外面缓存当前设置的角度值，
		 * 或者使用 getRotationX/Y/Z方式获取。该方式是通过计算dir向量来计算
		 * @param local
		 * @param out
		 * @return
		 *
		 */
		public function getRotation(local : Boolean = true, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.getRotation(local ? this.transform : this.world, out);
		}
		
		/**
		 * 设置pivot朝向。pivot会朝着目的点
		 * @param x		target x
		 * @param y		target y
		 * @param z		target z
		 * @param up		可以指定pivot的up方向，指定时候pivot会根据该up方向来确定朝向方位。
		 * @param smooth	 插值
		 *
		 */
		public function lookAt(x : Number, y : Number, z : Number, up : Vector3D = null, smooth : Number = 1) : void {
			Matrix3DUtils.lookAt(this.transform, x, y, z, up, smooth);
			this.updateTransforms(true);
		}
		
		/**
		 * 设置朝向，例如面向摄像机
		 * @param dir		朝向
		 * @param up			up vector
		 * @param smooth		插值
		 */
		public function setOrientation(dir : Vector3D, up : Vector3D = null, smooth : Number = 1) : void {
			Matrix3DUtils.setOrientation(this.transform, dir, up, smooth);
			this.updateTransforms(true);
		}
		
		/**
		 * 会在上一次的基础上进行旋转。例:当前角度为30,旋转角度为15，那么结果角度就为45而不是15。setRotation(x,y,z)属于直接设置值
		 * @param angle	角度
		 * @param local	标识是否参照local旋转还是参照global进行旋转
		 * @param pivotPoint		旋转参照点。例如pivotPoint->(0, 0, 0)，那么pivot会绕着0,0,0进行旋转，默认为自身。
		 *
		 */
		public function rotateX(angle : Number, local : Boolean = true, pivotPoint : Vector3D = null) : void {
			Matrix3DUtils.rotateX(this.transform, angle, local, pivotPoint);
			this.updateTransforms(true);
		}

		/**
		 * 会在上一次的基础上进行旋转。例:当前角度为30,旋转角度为15，那么结果角度就为45而不是15。setRotation(x,y,z)属于直接设置值
		 * @param angle	角度
		 * @param local	标识是否参照local旋转还是参照global进行旋转
		 * @param pivotPoint		旋转参照点。例如pivotPoint->(0, 0, 0)，那么pivot会绕着0,0,0进行旋转，默认为自身。
		 *
		 */
		public function rotateY(angle : Number, local : Boolean = true, pivotPoint : Vector3D = null) : void {
			Matrix3DUtils.rotateY(this.transform, angle, local, pivotPoint);
			this.updateTransforms(true);
		}

		/**
		 * 会在上一次的基础上进行旋转。例:当前角度为30,旋转角度为15，那么结果角度就为45而不是15。setRotation(x,y,z)属于直接设置值
		 * @param angle	角度
		 * @param local	标识是否参照local旋转还是参照global进行旋转
		 * @param pivotPoint		旋转参照点。例如pivotPoint->(0, 0, 0)，那么pivot会绕着0,0,0进行旋转，默认为自身。
		 *
		 */
		public function rotateZ(angle : Number, local : Boolean = true, pivotPoint : Vector3D = null) : void {
			Matrix3DUtils.rotateZ(this.transform, angle, local, pivotPoint);
			this.updateTransforms(true);
		}

		/**
		 * 绕着指定轴线进行旋转
		 * @param angle	角度
		 * @param axis	轴
		 * @param pivotPoint  参照点，默认为自身。
		 *
		 */
		public function rotateAxis(angle : Number, axis : Vector3D, pivotPoint : Vector3D = null) : void {
			Matrix3DUtils.rotateAxis(this.transform, angle, axis, pivotPoint);
			this.updateTransforms(true);
		}

		/**
		 * 设置缩放值
		 * @param val
		 *
		 */
		public function set scaleX(val : Number) : void {
			Matrix3DUtils.scaleX(this.transform, val);
			this.updateTransforms(true);
		}

		/**
		 * 设置缩放值
		 * @param val
		 *
		 */
		public function set scaleY(val : Number) : void {
			Matrix3DUtils.scaleY(this.transform, val);
			this.updateTransforms(true);
		}

		/**
		 * 设置缩放值
		 * @param val
		 *
		 */
		public function set scaleZ(val : Number) : void {
			Matrix3DUtils.scaleZ(this.transform, val);
			this.updateTransforms(true);
		}

		/**
		 * 获取缩放值
		 * @return
		 *
		 */
		public function get scaleX() : Number {
			return Matrix3DUtils.getRight(this.transform, this._vector).length;
		}

		/**
		 * 获取缩放值
		 * @return
		 *
		 */
		public function get scaleY() : Number {
			return Matrix3DUtils.getUp(this.transform, this._vector).length;
		}

		/**
		 * 获取缩放值
		 * @return
		 *
		 */
		public function get scaleZ() : Number {
			return Matrix3DUtils.getDir(this.transform, this._vector).length;
		}

		/**
		 * 设置pivot位移。该位移以世界坐标轴为参照物。
		 * @param x
		 * @param y
		 * @param z
		 * @param local
		 *
		 */
		public function setTranslation(x : Number = 0, y : Number = 0, z : Number = 0, local : Boolean = true) : void {
			Matrix3DUtils.setTranslation(this.transform, x, y, z, local);
			this.updateTransforms(true);
		}
		
		/**
		 * 在自身坐标系上面进行位移
		 * @param distance	位置长度
		 * @param local	标识使用local或者global进行位置
		 *
		 */
		public function translateX(distance : Number, local : Boolean = true) : void {
			Matrix3DUtils.translateX(this.transform, distance, local);
			this.updateTransforms(true);
		}

		/**
		 * 在自身坐标系上面进行位移
		 * @param distance	位置长度
		 * @param local	标识使用local或者global进行位置
		 *
		 */
		public function translateY(distance : Number, local : Boolean = true) : void {
			Matrix3DUtils.translateY(this.transform, distance, local);
			this.updateTransforms(true);
		}

		/**
		 * 在自身坐标系上面进行位移
		 * @param distance	位置长度
		 * @param local	标识使用local或者global进行位置
		 *
		 */
		public function translateZ(distance : Number, local : Boolean = true) : void {
			Matrix3DUtils.translateZ(this.transform, distance, local);
			this.updateTransforms(true);
		}

		/**
		 * 根据指定轴进行位移
		 * @param distance	位置长度
		 * @param axis		轴
		 */
		public function translateAxis(distance : Number, axis : Vector3D) : void {
			Matrix3DUtils.translateAxis(this.transform, distance, axis);
			this.updateTransforms(true);
		}

		/**
		 * 从其他pivot中拷贝transform信息
		 * @param source
		 * @param local
		 *
		 */
		public function copyTransformFrom(source : Pivot3D, local : Boolean = true) : void {
			if (local) {
				this.transform.copyFrom(source.transform);
			} else {
				this.world = source.world;
			}
			this.updateTransforms(true);
		}
		
		/**
		 *  重置transform
		 */
		public function resetTransforms() : void {
			this.transform.identity();
			this.updateTransforms(true);
		}

		/**
		 * 获取x坐标
		 * @return
		 *
		 */
		public function get x() : Number {
			this.transform.copyColumnTo(3, _temp0);
			return _temp0.x;
		}

		/**
		 * 设置x坐标
		 * @param val
		 *
		 */
		public function set x(val : Number) : void {
			this.transform.copyColumnTo(3, _temp0);
			_temp0.x = val;
			this.transform.copyColumnFrom(3, _temp0);
			this.updateTransforms(true);
		}
		
		/**
		 * 获取y坐标
		 * @return
		 *
		 */
		public function get y() : Number {
			this.transform.copyColumnTo(3, _temp0);
			return _temp0.y;
		}

		/**
		 * 设置y坐标
		 * @param val
		 *
		 */
		public function set y(val : Number) : void {
			this.transform.copyColumnTo(3, _temp0);
			_temp0.y = val;
			this.transform.copyColumnFrom(3, _temp0);
			this.updateTransforms(true);
		}

		/**
		 * 获取z坐标
		 * @return
		 *
		 */
		public function get z() : Number {
			this.transform.copyColumnTo(3, _temp0);
			return _temp0.z;
		}

		/**
		 * 设置z坐标
		 * @param val
		 *
		 */
		public function set z(val : Number) : void {
			this.transform.copyColumnTo(3, _temp0);
			_temp0.z = val;
			this.transform.copyColumnFrom(3, _temp0);
			this.updateTransforms(true);
		}

		/**
		 * 模型右方方向
		 * @param local
		 * @param out
		 * @return
		 *
		 */
		public function getRight(local : Boolean = true, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.getRight(local ? this.transform : this.world, out);
		}

		/**
		 * 左方方向
		 * @param local
		 * @param out
		 * @return
		 *
		 */
		public function getLeft(local : Boolean = true, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.getLeft(local ? this.transform : this.world, out);
		}

		/**
		 * 上方方向
		 * @param local
		 * @param out
		 * @return
		 *
		 */
		public function getUp(local : Boolean = true, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.getUp(local ? this.transform : this.world, out);
		}

		/**
		 * 下方方向
		 * @param local
		 * @param out
		 * @return
		 *
		 */
		public function getDown(local : Boolean = true, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.getDown(local ? this.transform : this.world, out);
		}

		/**
		 * 前方方向
		 * @param local
		 * @param out
		 * @return
		 *
		 */
		public function getDir(local : Boolean = true, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.getDir(local ? this.transform : this.world, out);
		}

		/**
		 * 后方方向
		 * @param local
		 * @param out
		 * @return
		 *
		 */
		public function getBackward(local : Boolean = true, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.getBackward(local ? this.transform : this.world, out);
		}

		/**
		 * 用于标量转换
		 * localtoGlobal
		 * @param point
		 * @param out
		 * @return
		 *
		 */
		public function localToGlobal(point : Vector3D, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.transformVector(this.world, point, out);
		}
		
		/**
		 * 用于矢量转换
		 * @param vector
		 * @param out
		 * @return
		 *
		 */
		public function localToGlobalVector(vector : Vector3D, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.deltaTransformVector(this.world, vector, out);
		}

		/**
		 * 用于标量转换
		 * @param point
		 * @param out
		 * @return
		 *
		 */
		public function globalToLocal(point : Vector3D, out : Vector3D = null) : Vector3D {
			return Matrix3DUtils.transformVector(this.invWorld, point, out);
		}

		/**
		 * 用于矢量转换
		 * @param vector
		 * @param out
		 * @return
		 *
		 */
		public function globalToLocalVector(vector : Vector3D, out : Vector3D = null) : Vector3D {
			return out = Matrix3DUtils.deltaTransformVector(this.invWorld, vector, out);
		}

		/**
		 * 模型的变形矩阵
		 * @return
		 */
		public function get world() : Matrix3D {
			if (this._dirty) {
				this.transform.copyToMatrix3D(this._world);
				if (this._parent && this._parent != this._scene) {
					this._world.append(this._parent.world);
				}
				this._dirty    = false;
				this._dirtyInv = true;
			}
			return this._world;
		}
		
		public function set world(value : Matrix3D) : void {
			this.transform.copyFrom(value);
			if (this.parent) {
				this.transform.append(this.parent.invWorld);
			}
			this.updateTransforms(true);
		}
		
		public function get invWorld() : Matrix3D {
			if (this._dirtyInv || this._dirty) {
				this._invGlobal.copyFrom(this.world);
				this._invGlobal.invert();
				this._dirtyInv = false;
			}
			return this._invGlobal;
		}

		public function updateTransforms(includeChildren : Boolean = false) : void {
			if (includeChildren) {
				var len : int = this._children.length;
				var i   : int = 0;
				while (i < len) {
					this._children[i].updateTransforms(includeChildren);
					i++;
				}
			}
			this._dirty    = true;
			this._dirtyInv = true;
		}
		
		/**
		 * 获取子对象
		 * @return
		 *
		 */
		public function get children() : Vector.<Pivot3D> {
			return this._children;
		}

		/**
		 * 获取父对象
		 * @return
		 */
		public function get parent() : Pivot3D {
			return this._parent;
		}
		
		/**
		 * 添加子对象
		 * @param pivot
		 * @param useGlobalSpace
		 * @return
		 *
		 */
		public function addChild(pivot : Pivot3D, useGlobalSpace : Boolean = false) : Pivot3D {
			var idx : int = this.children.indexOf(pivot);
			if (idx != -1) {
				return pivot;
			}
			pivot._parent = this;
			this.children.push(pivot);
			return pivot;
		}
		
		public function removeChild(pivot : Pivot3D) : Pivot3D {
			this.children.splice(this.children.indexOf(pivot), 1);
			return pivot;
		}
				
		/**
		 * 获取播放速度
		 * @return
		 *
		 */
		public function get frameSpeed() : Number {
			return this._frameSpeed;
		}

		/**
		 * 设置播放速度
		 * @param value
		 *
		 */
		public function set frameSpeed(value : Number) : void {
			this._frameSpeed = value;
			for each (var child : Pivot3D in this.children) {
				child.frameSpeed = value;
			}
		}
		
		/**
		 * 是否正在播放
		 * @return
		 *
		 */
		public function get isPlaying() : Boolean {
			return this._isPlaying;
		}
		
		/**
		 * gotoAndStop
		 * @param frame
		 */
		public function gotoAndStop(frame : int) : void {
			var length : int = this._children.length;
			var i : int = 0;
			while (i < length) {
				this._children[i].gotoAndStop(frame);
				i++;
			}
			if (frames == null)
				return;
			this.animationMode 	= ANIMATION_STOP_MODE;
			this._from 			= 0;
			this._to 			= this.frames.length;
			this.currentFrame 	= frame;
			this._isPlaying 		= false;
		}
		
		/**
		 * gotoAndPlay
		 * @param frame
		 * @param animationMode
		 */
		public function gotoAndPlay(frame : int, animationMode : int = ANIMATION_LOOP_MODE) : void {
			var length : int = this._children.length;
			var i : int = 0;
			while (i < length) {
				this._children[i].gotoAndPlay(frame, animationMode);
				i++;
			}
			if (this.frames == null) {
				return;
			}
			this.animationMode = animationMode;
			this._isPlaying = true;
			this._to 	= frames.length;
			this._from 	= frame;
			this._currentFrame = 0;
		}
		
		/**
		 * 当前帧数
		 * @return
		 */
		public function get currentFrame() : Number {
			return this._currentFrame;
		}

		/**
		 * 设置当前帧
		 * @param frame
		 */
		public function set currentFrame(frame : Number) : void {
			if (this.frames && this.frames.length) {
				if (frame < 0) {
					frame = 0;
				}
				if (frame >= this.frames.length) {
					frame = this.frames.length - 1;
				}
				this._currentFrame = frame;
				var f : Frame3D = this.frames[int(this._currentFrame)];
				if (f.func != null && frame != this._lastFrame) {
					f.func();
				}
				if (f.type == Frame3D.TYPE_FRAME) {
					this.transform.copyFrom(f.transform);
					this.updateTransforms(true);
				}
				if (this._lastFrame != frame) {
					this.updateTransforms(true);
				}
				this._lastFrame = frame;
			}
		}
		
		/**
		 * 为帧添加回调函数
		 * @param frame
		 * @param callback
		 */
		public function addFrameScript(frame : int, callback : Function) : void {
			if (this.frames && frame < this.frames.length) {
				this.frames[frame] = this.frames[frame].clone() as Frame3D;
				this.frames[frame].func = callback;
			}
		}
		
		/**
		 * play
		 * @param animationMode
		 */
		public function play(animationMode : int = ANIMATION_LOOP_MODE) : void {
			var length : int = this._children.length;
			var i : int = 0;
			while (i < length) {
				this._children[i].play(animationMode);
				i++;
			}
			if (this.frames == null) {
				return;
			}
			this.animationMode 	= animationMode;
			this._from 			= 0;
			this._to 			= this.frames.length;
			this._isPlaying 		= true;
		}

		/**
		 * stop
		 *
		 */
		public function stop() : void {
			var length : int = this._children.length;
			var i : int = 0;
			while (i < length) {
				this._children[i].stop();
				i++;
			}
			this._isPlaying = false;
		}
		
		/**
		 *  前一帧
		 */
		public function prevFrame(advancedTime : Number) : void {
			if (this._frameSpeed > 0) {
				this.nextFrame(advancedTime);
				return;
			}
			this._currentFrame = this._currentFrame + this._frameSpeed * (advancedTime / _fpsSpeed);
			if (this._currentFrame < this._from) {
				if (this.animationMode == ANIMATION_LOOP_MODE) {
					this._currentFrame = this._currentFrame + this._to - this._from;
				} else if (this.animationMode == ANIMATION_STOP_MODE) {
					this._currentFrame = this._from;
					this.stop();
				} else {
					this._currentFrame = this._currentFrame - this._frameSpeed * (advancedTime / _fpsSpeed);
					this._frameSpeed = -this._frameSpeed;
				}
			}
			this.currentFrame = this._currentFrame;
		}
		
		/**
		 *  下一帧
		 */
		public function nextFrame(advancedTime : Number) : void {
			if (this._frameSpeed < 0) {
				this.prevFrame(advancedTime);
				return;
			}
			this._currentFrame = this._currentFrame + this._frameSpeed * (advancedTime / _fpsSpeed);
			var animComplete : Boolean = false;
			if (this._currentFrame >= this._to) {
				if (this.animationMode == ANIMATION_LOOP_MODE) {
					this._currentFrame = this._from;
				} else if (this.animationMode == ANIMATION_STOP_MODE) {
					this._currentFrame = this._to - 1;
					this.stop();
				} else {
					this._currentFrame = this._to;
					this._frameSpeed   = -this._frameSpeed;
				}
			}
			this.currentFrame = this._currentFrame;
		}
		
		/**
		 * 更新
		 */
		public function update(advancedTime : Number, includeChildren : Boolean = false) : void {
			if (includeChildren) {
				var length : int = this._children.length;
				var i : int = 0;
				while (i < length) {
					this._children[i].update(advancedTime, includeChildren);
					i++;
				}
			}
			if (this._isPlaying) {
				this.nextFrame(advancedTime);
			}
		}

		/**
		 * 是否隐藏
		 * @return
		 *
		 */
		public function get visible() : Boolean {
			return this._visible;
		}

		/**
		 * 是否隐藏
		 * @param value
		 *
		 */
		public function set visible(value : Boolean) : void {
			this._visible = value;
			var length 	: int = this._children.length;
			var i 		: int = 0;
			while (i < length) {
				this._children[i].visible = value;
				i++;
			}
		}

		/**
		 * 获取scene
		 * @return
		 *
		 */
		public function get scene() : Scene3D {
			return this._scene;
		}
		
		/**
		 * draw
		 * @param includeChildren
		 * @param shader
		 */
		public function draw(includeChildren : Boolean = true, shader : Shader3D = null) : void {
			if (includeChildren) {
				var length : int = this._children.length;
				var i : int = 0;
				while (i < length) {
					this._children[i].draw(includeChildren, shader);
					i++;
				}
			}
		}
	}
}

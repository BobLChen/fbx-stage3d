package core.scene {

	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	import core.base.Pivot3D;
	import core.camera.Camera3D;
	import core.shader.Shader3D;
	import core.texture.Texture3D;
	import core.utils.Device3D;
	
	public class Scene3D extends Pivot3D {
		
		private var _container : DisplayObjectContainer;
		private var _paused : Boolean;
		private var _camera : Camera3D;
		private var _context3D : Context3D;
		private var _viewPort : Rectangle;
		private var _antialias : int = 0;
		private var _autoResize : Boolean = false;
		private var _lastTime : int;
		public var _clearColor : Vector3D;
								
		public function Scene3D(container : DisplayObjectContainer) {
			super("Scene");
			_container = container;
			_clearColor = new Vector3D(0.2, 0.2, 0.2, 1);
			_viewPort = new Rectangle();
			_camera = new Camera3D("Default_Scene_Camera");
			if (_container.stage) {
				addedToStageEvent(null);
			} else {
				_container.addEventListener(Event.ADDED_TO_STAGE, addedToStageEvent);
			}
		}

		private function addedToStageEvent(e : Event) : void {
			_container.removeEventListener(Event.ADDED_TO_STAGE, addedToStageEvent);
			var stage3d : Stage3D = _container.stage.stage3Ds[0];
			stage3d.addEventListener(Event.CONTEXT3D_CREATE, stageContextEvent);
			stage3d.requestContext3D(Context3DRenderMode.AUTO);
		}

		/**
		 * context3d create success
		 * @param e
		 */
		private function stageContextEvent(e : Event) : void {
			
			Device3D.defaultTexture = new Texture3D(Device3D.nullBitmapData);
			Device3D.defaultTexture.upload(this);
			
			var stage : Stage = _container.stage;
			_context3D = stage.stage3Ds[0].context3D;
			setViewport(0, 0, stage.stageWidth, stage.stageHeight, _antialias);
			_lastTime = getTimer();
			_container.addEventListener(Event.ENTER_FRAME, enterFrameEvent);
			dispatchEvent(e);
		}
		
		/**
		 * 设置背景色
		 * @param value
		 */
		public function set backgroundColor(value : int) : void {
			_clearColor.z = (value & 0xFF) / 0xFF;
			_clearColor.y = ((value >> 8) & 0xFF) / 0xFF;
			_clearColor.x = ((value >> 16) & 0xFF) / 0xFF;
		}

		/**
		 * 获取背景色
		 * @return
		 */
		public function get backgroundColor() : int {
			return (int(_clearColor.x * 0xFF) << 16) | (int(_clearColor.y * 0xFF) << 8) | int(_clearColor.z * 0xFF);
		}

		/**
		 * 设置viewport
		 * @param x			x
		 * @param y			y
		 * @param width		width
		 * @param height		height
		 * @param antialias	锯齿等级
		 *
		 */
		public function setViewport(x : Number = 0, y : Number = 0, width : Number = 640, height : Number = 480, antialias : int = 0) : void {
			if (_viewPort && _viewPort.x == x && _viewPort.y == y && _viewPort.width == width && _viewPort.height == height && _antialias == antialias) {
				return;
			}
			if (width < 50) {
				width = 50;
			}
			if (height < 50) {
				height = 50;
			}
			if (_context3D != null && (_context3D.driverInfo.indexOf("Software") != -1)) {
				if (width > 0x0800)
					width = 0x0800;
				if (height > 0x0800)
					height = 0x0800;
			}
			if (_viewPort == null) {
				_viewPort = new Rectangle();
			}
			_viewPort.x = x;
			_viewPort.y = y;
			_viewPort.width = width;
			_viewPort.height = height;
			
			_camera.viewPort = _viewPort;
			
			if (context) {
				_antialias = antialias;
				_context3D.configureBackBuffer(_viewPort.width, _viewPort.height, _antialias, true);
			}
		}
		
		/**
		 * @return 	camera
		 */
		public function get camera() : Camera3D {
			return _camera;
		}

		/**
		 * set camera(有一个默认camera)
		 * @param value
		 */
		public function set camera(value : Camera3D) : void {
			if (value == null)
				return;
			_camera = value;
			_camera.viewPort = _viewPort;
			_camera.updateProjectionMatrix();
		}

		/**
		 * enterFrame
		 * @param e
		 *
		 */
		private function enterFrameEvent(e : Event) : void {
			
			var delta : int = getTimer() - _lastTime;
			_lastTime = getTimer();
			
			if (!_paused) {
				update(delta / 1000);
			}
			
			Device3D.trianglesDrawn = 0;
			Device3D.drawCalls = 0;
			Device3D.objectsDrawn = 0;
			Device3D.camera = camera;
			Device3D.cameraGlobal.copyFrom(Device3D.camera.world);
			Device3D.viewProj.copyFrom(Device3D.camera.viewProjection);
			Device3D.proj.copyFrom(Device3D.camera.projection);
			Device3D.view.copyFrom(Device3D.camera.view);
			Device3D.scene = this;
			
			if (context) {
				_context3D.clear(_clearColor.x, _clearColor.y, _clearColor.z, _clearColor.w);
				_context3D.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
				render(_camera, false);
				_context3D.present();
			}
		}
		
		public function setupFrameInfo(camera : Camera3D = null) : void {
			Device3D.camera = camera || _camera;
			Device3D.cameraGlobal.copyFrom(Device3D.camera.world);
			Device3D.viewProj.copyFrom(Device3D.camera.viewProjection);
			Device3D.proj.copyFrom(Device3D.camera.projection);
			Device3D.view.copyFrom(Device3D.camera.view);
			Device3D.scene = this;
			Device3D.viewPort = Device3D.camera.viewPort || _viewPort;
		}
		
		/**
		 * @param includeChildren
		 * @param material
		 */
		override public function draw(includeChildren : Boolean = true, material : Shader3D = null) : void {
			throw new Error("scene 不能被draw ");
		}
				
		override public function update(delta : Number, includeChildren : Boolean = false) : void {
			for each (var pivot : Pivot3D in children) {
				pivot.update(delta, true);
			}
		}
		
		/**
		 * @param camera			camera
		 * @param clearDepth		是否清楚深度信息
		 * @param target			renderTotexture
		 */
		public function render(camera : Camera3D = null, clearDepth : Boolean = false) : void {
			context.clear(_clearColor.x, _clearColor.y, _clearColor.z, _clearColor.w);
			setupFrameInfo(camera);
			for each (var pivot : Pivot3D in children) {
				pivot.draw(true);
			}
		}
		
		/**
		 * context3d
		 * @return
		 *
		 */
		public function get context() : Context3D {
			return _context3D;
		}
		
		/**
		 * 锯齿等级
		 * @return
		 *
		 */
		public function get antialias() : int {
			return _antialias;
		}

		/**
		 * 设置锯齿等级
		 * @param value
		 *
		 */
		public function set antialias(value : int) : void {
			_antialias = value;
			if (_context3D) {
				_context3D.configureBackBuffer(_viewPort.width, _viewPort.height, _antialias);
			}
		}
		
		public function get viewPort() : Rectangle {
			return _viewPort;
		}
		
		public function get autoResize() : Boolean {
			return _autoResize;
		}

		/**
		 * 自动调整backbuffer大小
		 * @param value
		 */
		public function set autoResize(value : Boolean) : void {
			_autoResize = value;
			if (_container.stage) {
				if (value) {
					_container.stage.align = StageAlign.TOP_LEFT;
					_container.stage.scaleMode = StageScaleMode.NO_SCALE;
					_container.stage.addEventListener(Event.RESIZE, resizeStageEvent, false, 0, true);
				} else {
					_container.stage.removeEventListener(Event.RESIZE, resizeStageEvent);
				}
			}
		}

		/**
		 * resize
		 * @param e
		 *
		 */
		private function resizeStageEvent(e : Event) : void {
			setViewport(0, 0, _container.stage.stageWidth, _container.stage.stageHeight);
		}
		
	}
}

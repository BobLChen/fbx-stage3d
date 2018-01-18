package core.base {

	import flash.events.Event;
	
	import core.render.DefaultRender;
	import core.render.FrameRender;
	import core.render.SkeletonRender;
	import core.scene.Scene3D;
	import core.shader.Shader3D;
	import core.utils.Device3D;

	/**
	 * mesh3d，所有可绘制模型均继承于他或者由它构建。
	 * @author neil
	 */
	public class Mesh3D extends Pivot3D {

		private static var refaultRender	: DefaultRender = new DefaultRender();
		
		public var geometries			: Vector.<Geometry3D>;		// 子mesh
		public var mouseEnabled			: Boolean = true;			// 启用鼠标
		
		protected var _render 			: DefaultRender;				// 渲染器
		protected var _bounds 			: Bounds3D;					// bounds
		
		
		public function Mesh3D(name : String = "") {
			super(name);
			this.geometries		= new Vector.<Geometry3D>();
			this._render 		= refaultRender;
		}
		
		public function get render() : DefaultRender {
			return _render;
		}
		
		public function set render(value : DefaultRender) : void {
			if (value == null) {
				return;
			}
			_render = value;
			if (value is FrameRender) {
				var fr : FrameRender = value as FrameRender;
				this.frames = fr.frames;
			} else if (value is SkeletonRender) {
				var sr : SkeletonRender = value as SkeletonRender;
				this.frames = new Vector.<Frame3D>();
				for (var i:int = 0; i < sr.totalFrames; i++) {
					this.frames.push(new Frame3D(null, Frame3D.TYPE_NULL));
				}
			}
		}
		
		/**
		 * 上传
		 * @param scene
		 * @param includeChildren
		 *
		 */
		override public function upload(scene : Scene3D, includeChildren : Boolean = true) : void {
			super.upload(scene, includeChildren);
			for each (var geo : Geometry3D in this.geometries) {
				geo.upload(scene);
			}
		}
		
		/**
		 * 卸载
		 * @param includeChildren
		 *
		 */
		override public function download(includeChildren : Boolean = true) : void {
			super.download();
			for each (var geo : Geometry3D in this.geometries) {
				geo.download();
			}
		}
		
		public function clone() : Mesh3D {
			var mesh : Mesh3D = new Mesh3D();
			for each (var geo : Geometry3D in this.geometries) {
				mesh.geometries.push(geo);
			}
			mesh.render = render;
			mesh.frames = frames;
			return mesh;
		}
		
		override public function draw(includeChildren : Boolean = true, shaderBase : Shader3D = null) : void {
			if (this._scene == null) {
				this._scene = Device3D.scene;
			}
			this._render.draw(this, shaderBase);
			if (includeChildren) {
				var i : int = children.length - 1;
				while (i >= 0) {
					children[i].draw(true, shaderBase);
					i--;
				}
			}
			this.dispatchEvent(new Event("exitFrame"));
		}
	}
}

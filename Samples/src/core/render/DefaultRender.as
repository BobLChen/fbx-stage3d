package core.render  {

	import flash.events.EventDispatcher;
	
	import core.utils.Device3D;
	import core.base.Geometry3D;
	import core.base.Mesh3D;
	import core.shader.Shader3D;
	import core.base.Mesh3D;
	import core.shader.Shader3D;
	import core.utils.Device3D;
	import core.base.Geometry3D;

	/**
	 * 渲染器
	 * @author neil
	 *
	 */
	public class DefaultRender extends EventDispatcher{
		
		public function DefaultRender() {
			
		}
		
		/**
		 * 绘制模型 
		 * @param mesh
		 * @param shader
		 * 
		 */		
		public function draw(mesh : Mesh3D, shader : Shader3D = null) : void {
			// 状态
			Device3D.world.copyFrom(mesh.world);
			Device3D.worldViewProj.copyFrom(Device3D.world);
			Device3D.worldViewProj.append(Device3D.viewProj);
			Device3D.objectsDrawn++;
			// 绘制			
			for each (var geometry : Geometry3D in mesh.geometries) {
				var retShader : Shader3D = (shader == null ? geometry.shader : shader);
				retShader.draw(mesh, geometry, geometry.firstIndex, geometry.numTriangles);
			}
		}

	}
}

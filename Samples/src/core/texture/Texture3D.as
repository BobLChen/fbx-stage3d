package core.texture {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import core.scene.Scene3D;
	import core.utils.Device3D;
	import core.utils.Texture3DUtils;

	public class Texture3D extends EventDispatcher {

		public static const FORMAT_RGBA : int = 0;
		public static const FORMAT_CUBEMAP : int = 0;

		public static const FILTER_NEAREST : String = 'nearest';
		public static const FILTER_LINEAR : String = 'linear';

		public static const WRAP_CLAMP : String = 'clamp';
		public static const WRAP_REPEAT : String = 'repeat';

		public static const TYPE_2D : String = '2d';
		public static const TYPE_CUBE : String = 'cube';

		public static const MIP_NONE : String = 'mipnone';
		public static const MIP_NEAREST : String = 'mipnearest';
		public static const MIP_LINEAR : String = 'miplinear';

		public var bitmapData : BitmapData;
		public var texture : TextureBase;
		private var _data : *;
		private var _request : *;
		private var _loader : Loader;
		private var _urlLoader : URLLoader;
		private var _bytesTotal : uint;
		private var _bytesLoaded : uint;
		private var _levels : BitmapData;
		private var _mips : BitmapData;
		private var _transparent : Boolean;
		private var _optimizeForRenderToTexture : Boolean;
		private var _loaded : Boolean = false;
		private var _isATF : Boolean;
		private var _width : int;
		private var _height : int;
		private var _url : String;
		public var scene : Scene3D;

		public var filterMode : String = FILTER_LINEAR;
		public var wrapMode : String = WRAP_REPEAT;
		public var mipMode : String = MIP_LINEAR;
		public var typeMode : String = TYPE_2D;

		public var bias : int = 0;
		public var options : int = 0;
		public var format : int;
		public var name : String = "";
		public var uploadTexture : Function;


		public function Texture3D(request = null, optimizeForRenderToTexture : Boolean = false, format : int = 0, type : String = TYPE_2D) {

			if ((request is DisplayObject)) {
				var d : DisplayObject = (request as DisplayObject);
				var r : Rectangle = d.getBounds(d);
				var m : Matrix = new Matrix(1, 0, 0, 1, -r.x, -r.y);
				request = new BitmapData((r.width || 1), (r.height || 1), true, 0);
				request.draw(d, m);
			}

			this._url = request as String;
			this._request = request || Device3D.nullBitmapData;
			this._optimizeForRenderToTexture = optimizeForRenderToTexture;
			this.typeMode = type;
			this.wrapMode = type == TYPE_2D ? wrapMode : WRAP_CLAMP;
			this.format = format;
			this.uploadTexture = this.uploadWithMipmaps;

			if (this._request is Point) {
				this._width = this._request.x;
				this._height = this._request.y;
				this._optimizeForRenderToTexture = true;
				this.loaded = true;
			} else if (this._request is BitmapData || (this._request is Bitmap)) {
				this.bitmapData = this._request as BitmapData || this._request.bitmapData;
				this.loaded = true;
				this._transparent = this.bitmapData.transparent;
			} else if (this._request is TextureBase) {
				this.texture = this._request;
				this.loaded = true;
			} else if (this._request is String) {
				this.name = this._request;
			} else {
				throw(new Error("Unknown texture object."));
			}
		}

		public function dispose() : void {
			this.download();

			if (this._loader) {
				this._loader.unloadAndStop(false);
				this._loader = null;
			}

			if (this._urlLoader) {
				this._urlLoader = null;
			}

			if (this.bitmapData) {
				if (this.bitmapData != Device3D.nullBitmapData) {
					this.bitmapData.dispose();
				}
				this.bitmapData = null;
			}

			if (this._levels) {
				this._levels.dispose();
				this._levels = null;
			}

			if (this._mips) {
				this._mips.dispose();
				this._mips = null;
			}
			this._request = null;
		}

		public function upload(scene : Scene3D) : void {
			if (this.scene) {
				return;
			}
			this.scene = scene;

			if (!this._loaded && !this._loader && !this._urlLoader) {
				this.texture = Device3D.defaultTexture.texture;
				this.load();
			}
			
			if (this.scene.context) {
				this.contextEvent();
			}
			this.scene.addEventListener(Event.CONTEXT3D_CREATE, this.contextEvent);
		}

		private function contextEvent(e : Event = null) : void {

			if (this._loaded) {
				this.texture = null;

				if (this.typeMode == TYPE_2D) {
					if (this._request is Point) {
						this.texture = this.scene.context.createTexture(this._request.x, this._request.y, Context3DTextureFormat.BGRA, this.optimizeForRenderToTexture);
						scene.context.setRenderToTexture(texture, true);
						scene.context.clear(0, 0, 0, 0);
						scene.context.setRenderToBackBuffer();
					} else if (this._request is TextureBase) {
						this.texture = this._request;
					} else {
						this.uploadTexture();
					}
				} else if (this.typeMode == TYPE_CUBE) {
					if (this._request is Point) {
						this.texture = this.scene.context.createCubeTexture(this._request.x, Context3DTextureFormat.BGRA, this.optimizeForRenderToTexture);
						scene.context.setRenderToTexture(texture, true);
						scene.context.clear(0, 0, 0, 0);
						scene.context.setRenderToBackBuffer();
					} else if (this._request is TextureBase) {
						this.texture = this._request;
					} else if (!this._data) {
						this._data = Texture3DUtils.extractCubeMap(this.bitmapData || this._request as BitmapData || this._request.bitmapData);
						var i : int = 0;

						while (i < 6) {
							this.uploadTexture(this._data[i], i);
							i = i + 1;
						}
					}
				}
			}
		}

		public function download() : void {
			
			if (this.texture) {
				this.texture.dispose();
				this.texture = null;
			}
			
			if (this.scene) {
				this.scene.removeEventListener(Event.CONTEXT3D_CREATE, this.contextEvent);
				this.scene = null;
			}
		}

		public function get bytesTotal() : uint {
			return this._bytesTotal;
		}

		public function get bytesLoaded() : uint {
			return this._bytesLoaded;
		}

		public function get request() : Object {
			return this._request;
		}

		public function set request(value : *) : void {
			this._request = value;
		}

		public function get loaded() : Boolean {
			return this._loaded;
		}

		public function set loaded(value : Boolean) : void {
			this._loaded = value;
		}

		public function get optimizeForRenderToTexture() : Boolean {
			return this._optimizeForRenderToTexture;
		}

		public function get url() : String {
			return this._url || this.name;
		}

		public function get width() : int {
			if (this.bitmapData) {
				return this.bitmapData.width;
			}
			return this._width;
		}

		public function get height() : int {
			if (this.bitmapData) {
				return (this.bitmapData.height);
			}
			return this._height;
		}

		public function load() : void {
			if (this._loader || this._urlLoader || this.loaded) {
				return;
			}
			var context : LoaderContext = new LoaderContext();
			context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;

			if (this.format == FORMAT_RGBA) {
				this._loader = new Loader();
				this._loader.contentLoaderInfo.addEventListener("complete", this.completeEvent, false, 0, true);
				this._loader.contentLoaderInfo.addEventListener("progress", this.progressEvent, false, 0, true);
				this._loader.contentLoaderInfo.addEventListener("ioError", this.ioErrorEvent, false, 0, true);

				if (this._request is String) {
					this._loader.load(new URLRequest(this._request), context);
				} else if (this._request is ByteArray) {
					this._loader.loadBytes(this._request as ByteArray, context);
				}
			}
		}

		public function close() : void {
			if (this._loader && this.loaded == false) {
				this._loader.close();
			}

			if (this._urlLoader && this.loaded == false) {
				this._urlLoader.close();
			}
		}

		private function ioErrorEvent(e : IOErrorEvent) : void {
			this.bitmapData = Device3D.nullBitmapData;

			if (this.typeMode == TYPE_CUBE) {
				this._data = Texture3DUtils.extractCubeMap(this.bitmapData);
			}
			this.loaded = true;
			this._transparent = false;

			if (this.scene && this.scene.context) {
				this.contextEvent();
			}
			trace(e);
			dispatchEvent(e);
		}

		private function progressEvent(e : ProgressEvent) : void {
			this._bytesLoaded = e.bytesLoaded;
			this._bytesTotal = e.bytesTotal;
			dispatchEvent(e);
		}

		private function completeEvent(e : Event) : void {
			if (this._loader) {
				this.bitmapData = Bitmap(this._loader.content).bitmapData;

				if (this.typeMode == TYPE_CUBE) {
					this._data = Texture3DUtils.extractCubeMap(this.bitmapData);
				}
				this._transparent = this.bitmapData.transparent;
				this._loader.unloadAndStop();
				this._loader = null;
			}
			this.loaded = true;

			if (this.scene && this.scene.context) {
				this.contextEvent();
			}
			dispatchEvent(e);
		}

		private function uploadWithMipmaps(source : BitmapData = null, side : int = 0) : void {

			var swapped : Boolean;
			var oldMips : BitmapData;
			var oldMip : BitmapData;

			if (!this.scene) {
				throw(new Error("The texture is not linked to any scene, you may need to call to Texture3D.upload method before."));
			}
			var bitmapData : BitmapData = source || this.bitmapData;
			var max : Number = Device3D.maxTextureSize;
			var width : int = bitmapData.width < max ? bitmapData.width : max;
			var height : int = bitmapData.height < max ? bitmapData.height : max;
			var w : int = 1;

			while ((w << 1) <= width) {
				w = w << 1;
			}
			var h : int = 1;

			while ((h << 1) <= height) {
				h = h << 1;
			}

			if (!this.texture) {
				if (this.typeMode == TYPE_2D) {
					this.texture = this.scene.context.createTexture(w, h, Context3DTextureFormat.BGRA, this._optimizeForRenderToTexture);
				} else if (this.typeMode == TYPE_CUBE) {
					this.texture = this.scene.context.createCubeTexture(w, Context3DTextureFormat.BGRA, this._optimizeForRenderToTexture);
				}
			}

			var transform : Matrix = new Matrix(w / bitmapData.width, 0, 0, h / bitmapData.height);
			var mipRect : Rectangle = new Rectangle();
			var level : int;

			if (this.mipMode == Texture3D.MIP_NONE) {
				if (w != width || h != height) {
					if (!this._levels) {
						this._levels = new BitmapData(w, h, this._transparent, 0);
					} else if (this._transparent) {
						this._levels.fillRect(this._levels.rect, 0);
					}
					this._levels.draw(bitmapData, transform, null, null, null, true);
				}

				if (this.typeMode == TYPE_2D) {
					Texture(this.texture).uploadFromBitmapData(this._levels || bitmapData, 0);
				} else if (this.typeMode == TYPE_CUBE) {
					CubeTexture(this.texture).uploadFromBitmapData(this._levels || bitmapData, side, 0);
				}
			} else {

				this._mips = this._optimizeForRenderToTexture ? bitmapData : bitmapData.clone();
				swapped = false;

				while (w >= 1 || h >= 1) {
					if (w == width && h == height) {
						if (this.typeMode == TYPE_2D) {
							Texture(this.texture).uploadFromBitmapData(bitmapData, level);
						} else if (this.typeMode == TYPE_CUBE) {
							CubeTexture(this.texture).uploadFromBitmapData(bitmapData, side, level);
						}
					} else {

						mipRect.width = w;
						mipRect.height = h;

						if (!this._levels) {
							this._levels = new BitmapData(w || 1, h || 1, this._transparent, 0);
						} else if (this._transparent) {
							this._levels.fillRect(mipRect, 0);
						}
						this._levels.draw(this._mips, transform, null, null, mipRect, true);

						if (this.typeMode == TYPE_2D) {
							Texture(this.texture).uploadFromBitmapData(this._levels, level);
						} else if (this.typeMode == TYPE_CUBE) {
							CubeTexture(this.texture).uploadFromBitmapData(this._levels, side, level);
						}
					}

					if (this._levels) {
						oldMips = this._mips;
						this._mips = this._levels;
						this._levels = oldMips;
						swapped = !swapped;
					}

					transform.a = 0.5;
					transform.d = 0.5;
					w = (w >> 1);
					h = (h >> 1);
					level++;
				}

				if (swapped) {
					oldMip = this._mips;
					this._mips = this._levels;
					this._levels = oldMip;
				}
			}

			if ((!this._optimizeForRenderToTexture) && (this._levels)) {
				this._levels.dispose();
				this._levels = null;

				if (this.mipMode != MIP_NONE) {
					this._mips.dispose();
					this._mips = null;
				}
			}
		}

		private function isPowerOfTwo(x : int) : Boolean {
			return (x & (x - 1)) == 0;
		}

		override public function toString() : String {
			return "[object Texture3D name:" + this.name + "]";
		}

	}
}

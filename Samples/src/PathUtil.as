package {


	public class PathUtil {
		
		public function PathUtil() {
			
		}
		
		/**
		 * @param path
		 * @return
		 */
		public static function dirShortName(path : String) : String {
			var parts : Array = path.split('/');
			var last : String = parts[parts.length - 1];

			if (last != '')
				return last
			else if (parts.length > 1)
				return parts[parts.length - 2]
			else
				return '';
		}

		public static function dirName(path : String, up : int = 0) : String {
			var parts : Array = path.split('/');
			parts.length -= up + 1;
			return parts.join('/');
		}

		public static function up(path : String, count : int) : String {
			var parts : Array = path.split('/');
			parts.length -= count;
			return parts.join('/');
		}
	}
}

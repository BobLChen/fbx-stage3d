环境需求:
	python2.7 FbxSdk2015.1

python下载对应平台的2.7版本 		下载地址:https://www.python.org/downloads/
FbxSdk下载对应平台的Python Binding 下载地址:http://usa.autodesk.com/adsk/servlet/pc/item?siteID=123112&id=10775847

windows环境配置:
	安装python2.7并配置好环境、环境变量配置方式参照:http://jingyan.baidu.com/article/48206aeafdcf2a216ad6b316.html
	安装Fbxsdk2015
	将Fbxsdk2015 安装目录\FBX Python SDK\2015.1\lib\Python27_x86\ 下所有的文件拷贝到python 安装目录\Lib\site-packages\ 目录

Mac环境配置:
	安装python2.7  
	安装fbxsdk2015
	将/Applications/Autodesk/FBX Python SDK/2015.1/lib/Python27路径下的所有文件拷贝至/Library/Python/2.7/site-packages目录

Linux环境配置:
	参照:http://docs.autodesk.com/FBX/2014/ENU/FBX-SDK-Documentation/index.html?url=cpp_ref/fbxtypes_8h.html,topicNumber=cpp_ref_fbxtypes_8h_html7cba7c66-9e54-43f8-a60c-f6986ac1c59d,hash=a171e72a1c46fc15c1a6c9c31948c1c5b

脚本快速使用方法:
	1、将脚本与fbx文件放置于同一目录
	
	2、运行
		windows:
			双击脚本即可
		mac:
			进入terminal、定位到脚本目录、输入:python FbxParser.py

注意事项:
	fbx文件名，fbx文件路径，建模过程中不要使用中文。

通过命令参数方式使用该脚本:
-noaml 	解析法线
-uv0   	解析UV0
-uv1   	解析UV1
-anim  	解析动画
-world	使用全局坐标
-path	指定Fbx文件路径

Updating:
脚本目前只能解析静态模型以及动画。不能解析相机、灯光、骨骼动画等等。脚本目前的所有参数无法使用，默认解析所有数据。



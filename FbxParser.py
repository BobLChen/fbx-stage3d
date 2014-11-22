# coding: utf-8

''' 

1、二进制文件采用小头并压缩方式保存。
2、不会保存三角形索引数据，三角索引数据自行生成，顺序为0，1，2，3，4，5，6...。使用顺时针顺序。
3、各个部分数据分块存储。可以将整块数据读入到bytes，然后整块直接上传。

'''

from FbxCommon import *
from string import count
import argparse
import json
import os
import re
import struct
import sys
import zlib

# object
class LObject(object):
    """docstring for LObject"""
    def __init__(self):
        pass # end func
    pass # end class

# 文件类型
MESH_TYPE = ".mesh"
ANIM_TYPE = ".anim"
# 坐标轴，对轴进行180°旋转，对X轴进行Flip操作。因此需要重构索引。
AXIS_FLIP_X    = FbxAMatrix(FbxVector4(0, 0, 0), FbxVector4(0, 180, 0), FbxVector4(-1, 1, 1))
# 坐标轴，未进行flip操作
AXIS_NO_FLIP_X = FbxAMatrix(FbxVector4(0, 0, 0), FbxVector4(0, 180, 0), FbxVector4(1, 1, 1))

# 配置文件
config = LObject()

# 解析命令行参数
def parseArgument():

    print("解析命令行参数...")

    parser = argparse.ArgumentParser()
    # 解析法线
    parser.add_argument("-normal",  help = "parse normal",      action = "store_true",      default = True)
    # 解析UV0
    parser.add_argument("-uv0",     help = "parse uv0",         action = "store_true",      default = True)
    # 解析UV1
    parser.add_argument("-uv1",     help = "parse uv1",         action = "store_true",      default = True)
    # 解析动画
    parser.add_argument("-anim",    help = "parse animation",   action = "store_true",      default = True)
    # 使用全局坐标
    parser.add_argument("-world",   help = "world Transofrm",   action = "store_true",      default = True)
    # 指定Fbx文件路径
    parser.add_argument("-path",    help = "fbx file path  ",   action = "store",           default = "")
    
    option = parser.parse_args()
    
    return option
    pass

# 扫描Fbx文件
def scanFbxFiles(args):
    sourceDir = None
    # 获取路径
    if len(args) == 0:
        sourceDir = os.getcwd()
        pass
    else:
        sourceDir = args[0]
        if not os.path.exists(sourceDir):
            sourceDir = os.getcwd()
            pass
        pass
    
    fbxList = []
    if os.path.isfile(sourceDir):
        fbxList.append(sourceDir)
        pass
    else:
        print("为发现Fbx文件，开始扫描当前目录:%s" % sourceDir)
        for parentDir, _, fileNames in os.walk(sourceDir):
            for fileName in fileNames:
                if fileName.endswith('FBX') or fileName.endswith('fbx'):
                    filePath = os.path.join(parentDir, fileName)
                    fbxList.append(filePath)
                    pass
                pass
        pass
    
    for item in fbxList:
        print("find fbx file: %s" % item)
        pass
    return fbxList
    pass # end func

# Matrix3D矩阵，通过FbxAMatrix初始化
# 使用主列矩阵，矩阵是反着的。
class Matrix3D(object):
    """docstring for Matrix3D"""
    def __init__(self, mt):
        super(Matrix3D, self).__init__()
        self.rawData = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
        for i in range(4):
            row = mt.GetRow(i)
            self.rawData[i * 4 + 0] = row[0]
            self.rawData[i * 4 + 1] = row[1]
            self.rawData[i * 4 + 2] = row[2]
            self.rawData[i * 4 + 3] = row[3]
            pass
        pass
    
    # 获取一列
    def getRaw(self, raw):
        vec = [0, 0, 0, 0]
        vec[0] = self.rawData[raw + 0];
        vec[1] = self.rawData[raw + 4];
        vec[2] = self.rawData[raw + 8];
        vec[3] = self.rawData[raw + 12];
        return vec
        pass
    
    # 获取一行
    def getColumn(self, column):
        vec = [0, 0, 0, 0]
        vec[0] = self.rawData[column * 4 + 0]
        vec[1] = self.rawData[column * 4 + 1]
        vec[2] = self.rawData[column * 4 + 2]
        vec[3] = self.rawData[column * 4 + 3]
        return vec
        pass # end func
    
    # deltaTransform
    def deltaTransformVector(self, vec):
        right = [self.rawData[0], self.rawData[4], self.rawData[8]]
        up    = [self.rawData[1], self.rawData[5], self.rawData[9]]
        ddir  = [self.rawData[2], self.rawData[6], self.rawData[10]]
        out   = [0, 0, 0]
        out[0] = vec[0] * right[0] + vec[1] * right[1] + vec[2] * right[2]
        out[1] = vec[0] * up[0]    + vec[1] * up[1]    + vec[2] * up[2]
        out[2] = vec[0] * ddir[0]  + vec[1] * ddir[1]  + vec[2] * ddir[2]
        return out
        pass
    
    # transform
    def transformVector(self, vec):
        right = [self.rawData[0],  self.rawData[4],  self.rawData[8]]
        up    = [self.rawData[1],  self.rawData[5],  self.rawData[9]]
        ddir  = [self.rawData[2],  self.rawData[6],  self.rawData[10]]
        out   = [self.rawData[12], self.rawData[13], self.rawData[14]]
        out[0] = out[0] + vec[0] * right[0] + vec[1] * right[1] + vec[2] * right[2]
        out[1] = out[1] + vec[0] * up[0]    + vec[1] * up[1]    + vec[2] * up[2]
        out[2] = out[2] + vec[0] * ddir[0]  + vec[1] * ddir[1]  + vec[2] * ddir[2]
        return out
        pass

# 获取GeometryTransform
def GetGeometryTransform(node):
    t = node.GetGeometricTranslation(FbxNode.eSourcePivot)
    r = node.GetGeometricRotation(FbxNode.eSourcePivot)
    s = node.GetGeometricScaling(FbxNode.eSourcePivot)
    return FbxAMatrix(t, r, s)
    pass # end func

# 打印矩阵
def printFBXAMatrix(sstr, transform):
    print("%s TX:%f\tTY:%f\tTZ:%f" % (sstr, transform.GetT()[0], transform.GetT()[1], transform.GetT()[2]))
    print("%s RX:%f\tRY:%f\tRZ:%f" % (sstr, transform.GetR()[0], transform.GetR()[1], transform.GetR()[2]))
    print("%s SX:%f\tSY:%f\tSZ:%f" % (sstr, transform.GetS()[0], transform.GetS()[1], transform.GetS()[2]))
    pass # end func

# 解析FBX文件目录
def parseFilepath(fbxfile):
    filepath = re.compile("[\\\/]").split(fbxfile)[0:-1]
    filepath.append("")
    if sys.platform == 'win32':
        filepath = "\\".join(filepath)
        pass
    else:
        filepath = '/'.join(filepath)
        pass
    return filepath
    pass # end func

# 相机
class Camera3D(object):
    """docstring for Camera3D"""
    def __init__(self):
        super(Camera3D, self).__init__()
        self.fbxCamera = None
        pass # end func
    
    # 通过FBXCamera初始化相机
    def initWithFbxCamera(self, fbxCamera):
        print("解析相机...")
        self.fbxCamera = fbxCamera
        # 相机名称
        self.name = fbxCamera.GetName()
        pass # end func

    pass # end class

# 场景
class Scene3D(object):

    """docstring for Scene3D"""
    def __init__(self):
        super(Scene3D, self).__init__()
        self.cameras = [] # 相机列表
        pass # end func
    
    pass # end class

# 模型
class Mesh(object):
    """docstring for Mesh"""
    def __init__(self):
        super(Mesh, self).__init__()
        self.fbxMesh            = None          # FbxMesh
        self.sdkManager         = None          # FbxSdk
        self.scene              = None          # FbxScene
        self.fbxFilePath        = None          # Fbx文件路径
        self.name               = None          # 模型名称
        self.skeleton           = False         # 是否为骨骼模型
        self.geometryTransform  = None          # geometry矩阵
        self.invGeometryTrans   = None          # geometry逆矩阵
        self.localTransform     = None          # 本地矩阵
        self.invLocalTransform  = None          # 本地矩阵逆矩阵
        self.globalTransform    = None          # 全局矩阵
        self.invGlobalTransform = None          # 全局逆矩阵
        self.axisTransform      = None          # 坐标系矩阵
        self.invAxisTransform   = None          # 坐标系逆矩阵
        self.vertices           = []            # 顶点
        self.weights            = []            # 权重以及索引数据|骨骼动画必须
        self.uvs0               = []            # UV
        self.uvs1               = []            # UV1,可能为烘焙贴图UV
        self.normals            = []            # 法线
        self.verticesIndices    = []            # 顶点索引
        self.uvIndices          = []            # uv索引
        self.indices            = []            # 索引
        self.anims              = []            # 动画|如果为骨骼模型，那么保存骨骼数据，否则就保存帧Transform数据
        self.bounds             = LObject()     # 包围盒
        self.meshBytes          = None          # Mesh数据
        self.animBytes          = None          # 动作数据
        self.meshFileName       = None          # Mesh文件名
        self.animFileName       = None          # 动作文件名
        self.bounds.min = [0, 0, 0]
        self.bounds.max = [0, 0, 0]
        pass #end func
    
    # 解析矩阵
    def parseTransform(self):
        print("\t解析矩阵...")
        
        self.geometryTransform  = GetGeometryTransform(self.fbxMesh.GetNode())
        self.invGeometryTrans   = FbxAMatrix(self.geometryTransform)
        self.invGeometryTrans.Inverse()
        
        self.localTransform     = self.fbxMesh.GetNode().EvaluateLocalTransform()
        self.invLocalTransform  = FbxAMatrix(self.localTransform)
        self.invLocalTransform.Inverse()
        
        self.globalTransform    = self.fbxMesh.GetNode().EvaluateGlobalTransform()
        self.invGlobalTransform = FbxAMatrix(self.globalTransform)
        self.invGlobalTransform.Inverse()
        
        printFBXAMatrix("\tGeomtryMatrix:", self.geometryTransform)
        printFBXAMatrix("\tLocal  Matrix:", self.localTransform)
        printFBXAMatrix("\tGlobal Matrix:", self.globalTransform)
        
        # 坐标系矩阵
        if config.world:
            self.axisTransform = AXIS_FLIP_X * self.globalTransform * self.geometryTransform  # 使用全局坐标系
            pass
        else:
            self.axisTransform = AXIS_FLIP_X * self.localTransform  * self.geometryTransform  # 使用本地坐标系
            pass
        self.invAxisTransform = FbxAMatrix(self.axisTransform)
        self.invAxisTransform = self.invAxisTransform.Inverse()
        
        pass # end func
    
    # 解析索引
    def parseIndices(self):
        print("\t解析索引...")
        count = self.fbxMesh.GetPolygonCount()
        print("\t三角形数量:%d" % (count))
        for i in range(count):
            for j in range(3):
                # 顶点索引
                vertIdx = self.fbxMesh.GetPolygonVertex(i, j)
                self.verticesIndices.append(vertIdx)
                # uv索引
                uvIdx = self.fbxMesh.GetTextureUVIndex(i, j)
                self.uvIndices.append(uvIdx)
                pass # end for
            pass # end for
        # 生成索引
        count = count * 3
        for i in range(count):
            self.indices.append(i)
            pass
        pass # end func
    
    # 解析顶点
    def parseVertices(self):
        print("\t解析顶点...")
        count = self.fbxMesh.GetControlPointsCount()
        points= self.fbxMesh.GetControlPoints()
        for i in range(count):
            vert = points[i]
            self.vertices.append(vert)
            pass # end for
        # 组织顶点数据
        vertices = []
        count = len(self.verticesIndices)
        for i in range(count):
            idx = self.verticesIndices[i]
            vert= self.vertices[idx]
            vertices.append(vert)
            pass
        self.vertices = vertices
        print("\t顶点数量:%d" % (len(self.vertices)))
        # 对顶点坐标轴转换
        count = len(self.vertices)
        for i in range(count):
            vert = self.vertices[i]
            vert = self.axisTransform.MultT(vert)
            self.vertices[i] = [vert[0], vert[1], vert[2]]
            pass # end for
        # 重构顶点索引顺序
        count = count / 3
        for i in range(count):
            v0 = self.vertices[i * 3 + 0]
            v1 = self.vertices[i * 3 + 1]
            v2 = self.vertices[i * 3 + 2]
            self.vertices[i * 3 + 0] = v0
            self.vertices[i * 3 + 1] = v2
            self.vertices[i * 3 + 2] = v1
            pass # end for
        pass # end func
    
    # 解析UV0
    def parseUV0(self):
        layerCount = self.fbxMesh.GetLayerCount()
        # 解析UV0
        if layerCount >= 1:
            print("\t解析UV0...")
            uvs   = self.fbxMesh.GetLayer(0).GetUVs()
            count = uvs.GetDirectArray().GetCount()
            data  = uvs.GetDirectArray()
            for i in range(count):
                uv = data.GetAt(i)
                self.uvs0.append([uv[0], 1 - uv[1]])
                pass # end for
            # 组织UV数据
            count = len(self.uvIndices)
            uvs   = []
            for i in range(count):
                idx = self.uvIndices[i]
                uv  = self.uvs0[idx]
                uvs.append(uv)
                pass # end for
            self.uvs0 = uvs
            print("\tUV0数量:%d" % (len(self.uvs0)))
            pass # end if
        pass # end func
    
    # 解析UV
    def parseUV1(self):
        layerCount = self.fbxMesh.GetLayerCount()
        if layerCount >= 2:
            print("\t解析UV1...")
            uvs   = self.fbxMesh.GetLayer(0).GetUVs()
            count = uvs.GetDirectArray().GetCount()
            data  = uvs.GetDirectArray()
            for i in range(count):
                uv = data.GetAt(i)
                self.uvs1.append([uv[0], 1 - uv[1]])
                pass # end for
            # 组织UV1数据
            count = len(self.uvIndices)
            uvs   = []
            for i in range(count):
                idx = self.uvIndices[i]
                uv  = self.uvs1[idx]
                uvs.append(uv)
                pass # end for
            self.uvs1 = uvs
            print("\tUV1数量:%d" % (len(self.uvs1)))
            pass # end if
        pass # end func
    
    # 解析法线
    def parseNormals(self):
        print("\t解析法线...")
        normals = self.fbxMesh.GetLayer(0).GetNormals()
        count   = normals.GetDirectArray().GetCount()
        print("\t法线数量:%d" % (count))
        data    = normals.GetDirectArray()
        for i in range(count):
            self.normals.append(data.GetAt(i))
            pass
        # 对法线进行转换
        count = len(self.normals)
        axis  = Matrix3D(self.axisTransform)
        for i in range(count):
            nrm = self.normals[i]
            nrm = axis.deltaTransformVector(nrm)
            nrm = FbxVector4(nrm[0], nrm[1], nrm[2], 1)
            nrm.Normalize()
            self.normals[i] = [nrm[0], nrm[1], nrm[2]]
            pass # end for
        # 重构法线索引顺序
        count = count / 3
        for i in range(count):
            v0 = self.normals[i * 3 + 0]
            v1 = self.normals[i * 3 + 1]
            v2 = self.normals[i * 3 + 2]
            self.normals[i * 3 + 0] = v0
            self.normals[i * 3 + 1] = v2
            self.normals[i * 3 + 2] = v1
            pass # end for
        pass # end func
    
    # 解析骨骼权重以及索引
    def parseCluster(self):   
        
        pass # end
    
    # 解析骨骼动画
    def parseSkeletonAnim(self, time):
        
        pass
    
    # 解析帧动画
    def parseFrameAnim(self, time):
        # 转换模型到原始状态
        # 顶点 * axis * axis的逆矩阵 * global * axis
        animMt = AXIS_FLIP_X * self.fbxMesh.GetNode().EvaluateGlobalTransform(time) * self.invAxisTransform
        matrix = Matrix3D(animMt)
        clip   = []
        # 丢弃最后一列数据
        for i in range(3):
            raw = matrix.getRaw(i)
            for j in range(len(raw)):
                clip.append(raw[j])
                pass
            pass
        # 保存数据
        self.anims.append(clip)
        pass # end func
    
    # 解析动画
    def parseAnim(self):
        print("\t解析动画...")
        # 检测是否为骨骼动画
        skinCount = self.fbxMesh.GetDeformerCount(FbxDeformer.eSkin)
        self.skeleton = skinCount > 0
        print("\t模型拥有骨骼:%s" % str(self.skeleton))
        # 如果为骨骼动画，则需要事先解析骨骼
        if self.skeleton:
            self.parseCluster()
            pass #
        # 获取帧频
        fps = FbxTime.GetFrameRate(self.scene.GetGlobalSettings().GetTimeMode())
        print("\t动画帧频:%d" % (fps))
        timeSpan  = self.scene.GetSrcObject(FbxAnimStack.ClassId, 0).GetLocalTimeSpan()
        totalTime = timeSpan.GetStop().Get() - timeSpan.GetStart().Get()
        time = FbxTime()
        timeStep = 1.0 / fps
        time.SetSecondDouble(timeStep)
        frameCount = totalTime / time.Get()
        print("\t动画总帧数:%d" % frameCount)
        # 解析每一帧数据
        for frame in range(frameCount):
            time.SetSecondDouble(frame * timeStep)
            if self.skeleton:                           
                self.parseSkeletonAnim(time)            # 解析骨骼动画
                pass
            else:
                self.parseFrameAnim(time)               # 解析帧动画
                pass
            pass
        pass # end func
    
    # 生成模型数据
    def generateMeshBytes(self):
        # 生成Mesh对应的文件名称
        tokens  = re.compile("[\\\/]").split(self.fbxFilePath)
        fbxName = tokens[-1]
        fbxName = fbxName.split(".")[0:-1]
        fbxName = ".".join(fbxName)
        fbxDir  = parseFilepath(self.fbxFilePath)
        self.meshFileName = fbxDir + fbxName + "_" + self.name + MESH_TYPE
        # 组织Mesh数据
        data = b''
        # 写名称
        data += struct.pack('<i', len(self.name)) 
        data += str(self.name)
        # 写顶点
        count = len(self.vertices)
        data += struct.pack('<i', count)            
        for i in range(count):                     
            vert = self.vertices[i]
            data += struct.pack('<fff', vert[0], vert[1], vert[2])
            pass # end for
        # 写UV0
        count = len(self.uvs0)                      
        data += struct.pack('<i', count)
        for i in range(count):
            uv = self.uvs0[0]
            data += struct.pack('<ff', uv[0], uv[1])
            pass # end for
        # 写UV1
        count = len(self.uvs1)
        data += struct.pack('<i', count)
        for i in range(count):
            uv = self.uvs1[i]
            data += struct.pack('<ff', uv[0], uv[1])
            pass # end for
        # 写法线
        count = len(self.normals)
        data += struct.pack('<i', count)
        for i in range(count):
            normal = self.normals[i]
            data  += struct.pack('<fff', normal[0], normal[1], normal[2])
            pass
        
        # 写包围盒数据
        data += struct.pack('<ffffff', self.bounds.min[0], self.bounds.min[1], self.bounds.min[2], self.bounds.max[0], self.bounds.max[1], self.bounds.max[2])
        # 压缩
        data = zlib.compress(data, 9)
        
        self.meshBytes = data
        pass # end func
    
    # 生成帧动画数据
    def generateFrameAnimBytes(self):
        data = b''
        # 写入动画类型
        data += struct.pack('<i', 0)
        # 写入帧数
        count = len(self.anims)
        data += struct.pack('<i', count)
        # 写入数据
        for i in range(count):
            clip = self.anims[i]
            for j in range(len(clip)):
                data += struct.pack('<f', clip[j])
                pass
            pass
        return data
        pass # end func
    
    # 生成动画数据
    def generateAnimBytes(self):
        # 生成Mesh对应的文件名称
        tokens  = re.compile("[\\\/]").split(self.fbxFilePath)
        fbxName = tokens[-1]
        fbxName = fbxName.split(".")[0:-1]
        fbxName = ".".join(fbxName)
        fbxDir  = parseFilepath(self.fbxFilePath)
        self.animFileName = fbxDir + fbxName + "_" + self.name + ANIM_TYPE
        # 动画类型:0->帧动画;1->矩阵骨骼动画;2->四元数骨骼动画
        data = None
        
        if self.skeleton:
            
            pass
        else:
            data = self.generateFrameAnimBytes()
            pass
        
        data = zlib.compress(data, 9)
        self.animBytes = data
        pass # end func
    
    # 初始化mesh
    def initWithFbxMesh(self, fbxMesh, sdkManager, scene, fbxFilePath):
        print("解析模型...")
        self.fbxMesh    = fbxMesh
        self.sdkManager = sdkManager
        self.scene      = scene
        self.name       = fbxMesh.GetNode().GetName()
        self.fbxFilePath= fbxFilePath
        print("\t%s" % (self.name))
        # 解析矩阵
        self.parseTransform()
        # 解析索引
        self.parseIndices()
        # 解析控制点
        self.parseVertices()
        # 解析UV0
        if config.uv0:
            self.parseUV0()
        # 解析UV1
        if config.uv1:
            self.parseUV1()
        # 解析法线
        if config.normal:
            self.parseNormals()
        # 解析动画
        if config.anim:
            self.parseAnim()
        # 生成模型数据
        self.generateMeshBytes()
        self.generateAnimBytes()
        # 生成动画数据
        
        open(self.meshFileName, 'w+b').write(self.meshBytes)
        open(self.animFileName, 'w+b').write(self.animBytes)
        
        pass



    pass # end class

# 解析相机
def parseCameras(sdkManager, scene, filepath):
    print("解析相机列表...")
    count = scene.GetSrcObjectCount(FbxCamera.ClassId)
    print("\t相机数量:%d" % (count))
    cameras = []
    for i in range(count):
        fbxCamera = scene.GetSrcObject(FbxCamera.ClassId, i)
        camera = Camera3D()
        camera.initWithFbxCamera(fbxCamera)
        cameras.append(camera)
        pass # end for
    return cameras
    pass # end func

# 解析所有的模型
def parseMeshs(sdkManager, scene, filepath):
    print("解析模型列表...")
    count = scene.GetSrcObjectCount(FbxMesh.ClassId)
    print("\t模型数量:%d" % (count))
    meshs = []
    for i in range(count):
        fbxMesh = scene.GetSrcObject(FbxMesh.ClassId, i)
        mesh = Mesh()
        mesh.initWithFbxMesh(fbxMesh, sdkManager, scene, filepath)
        meshs.append(mesh)
        pass # end for

    pass # end func

# 解析FBX文件
def parseFBX(fbxfile, config):
    print("开始解析FBX文件:%s" % (fbxfile))
    # 初始化SDKManager以及Scene
    sdkManager, scene = InitializeSdkObjects()
    # 加载FBX
    content = LoadScene(sdkManager, scene, fbxfile)
    # fbx文件装载失败
    if content == False:
        print("Fbx文件装载失败:%s" % fbxfile)
        sdkManager.Destroy()
        return
        pass
    # 对场景三角化
    converter = FbxGeometryConverter(sdkManager)
    converter.Triangulate(scene, True)
    axisSystem = FbxAxisSystem.OpenGL
    axisSystem.ConvertScene(scene)
    print("三角化整个场景...")
    # 开始解析
    parseCameras(sdkManager, scene, fbxfile)
    parseMeshs(sdkManager,   scene, fbxfile)
    
    pass # end func

if __name__ == "__main__":
    
    # 解析参数
    config = parseArgument()
    fbxList = scanFbxFiles(config.path)
    
    for item in fbxList:
        parseFBX(item, config)
        pass
    
    pass

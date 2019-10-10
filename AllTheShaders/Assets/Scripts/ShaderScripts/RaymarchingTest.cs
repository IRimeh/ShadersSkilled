using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class RaymarchingTest : MonoBehaviour
{

    [SerializeField]
    private Material _material;
    [SerializeField]
    private GameObject _container;
    [SerializeField]
    private ComputeShader _computeShader;

    [Header("Texture Options")]
    [SerializeField]
    private int _textureSize = 256;
    [SerializeField]
    private int _channel0GridSize = 8;
    [SerializeField]
    private int _channel1GridSize = 8;
    [SerializeField]
    private int _channel2GridSize = 8;
    [SerializeField]
    private int _channel3GridSize = 8;
    [SerializeField]
    private bool _generateTexture;


    private Vector3 boundsMin;
    private Vector3 boundsMax;

    private Texture3D tex3D;
    private Vector3[,,] texturePoints;

    private Vector3[] _points;
    private Vector3[] _newPoints;
    private RenderTexture _renderTex;

    private void CaluclateContainerBounds()
    {
        if (_container)
        {
            boundsMin = _container.transform.position - _container.transform.localScale / 2;
            boundsMax = _container.transform.position + _container.transform.localScale / 2;
        }
    }

    private void OnValidate()
    {
        if(_generateTexture)
        {
            _generateTexture = false;

            int mainKernel = _computeShader.FindKernel("CSMain");
            int pointGenerationKernel = _computeShader.FindKernel("PointGenerator");

            //Create rendertexture
            _renderTex = new RenderTexture(_textureSize, _textureSize, 0);
            _renderTex.enableRandomWrite = true;
            _renderTex.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
            _renderTex.volumeDepth = _textureSize;
            _renderTex.wrapMode = TextureWrapMode.Repeat;
            _renderTex.Create();

            //Channel 0 (Red)
            _points = new Vector3[_channel0GridSize * _channel0GridSize * _channel0GridSize];
            _newPoints = new Vector3[_channel0GridSize * _channel0GridSize * _channel0GridSize];
            GeneratePoints(pointGenerationKernel, _textureSize, _channel0GridSize);
            GenerateWorleyNoise(mainKernel, _renderTex, _textureSize, _channel0GridSize, 0);
            //Channel 1 (Green)
            _points = new Vector3[_channel1GridSize * _channel1GridSize * _channel1GridSize];
            _newPoints = new Vector3[_channel1GridSize * _channel1GridSize * _channel1GridSize];
            GeneratePoints(pointGenerationKernel, _textureSize, _channel1GridSize);
            GenerateWorleyNoise(mainKernel, _renderTex, _textureSize, _channel1GridSize, 1);
            //Channel 2 (Blue)
            _points = new Vector3[_channel2GridSize * _channel2GridSize * _channel2GridSize];
            _newPoints = new Vector3[_channel2GridSize * _channel2GridSize * _channel2GridSize];
            GeneratePoints(pointGenerationKernel, _textureSize, _channel2GridSize);
            GenerateWorleyNoise(mainKernel, _renderTex, _textureSize, _channel2GridSize, 2);
            //Channel 3 (Alpha)
            _points = new Vector3[_channel3GridSize * _channel3GridSize * _channel3GridSize];
            _newPoints = new Vector3[_channel3GridSize * _channel3GridSize * _channel3GridSize];
            GeneratePoints(pointGenerationKernel, _textureSize, _channel3GridSize);
            GenerateWorleyNoise(mainKernel, _renderTex, _textureSize, _channel3GridSize, 3);

            _material.SetTexture("_3DNoiseTex", _renderTex);
        }
    }

    private void GeneratePoints(int kernel, int textureSize, int gridSize)
    {
        ComputeBuffer buffer = new ComputeBuffer(_points.Length, 12);
        buffer.SetData(_points);
        _computeShader.SetBuffer(kernel, "points", buffer);
        _computeShader.SetInt("textureSize", textureSize);
        _computeShader.SetInt("gridSize", gridSize);
        _computeShader.Dispatch(kernel, 1, 1, 1);

        buffer.GetData(_newPoints);
    }

    private void GenerateWorleyNoise(int kernel, RenderTexture texture, int textureSize, int gridSize, int channel = 0)
    {
        ComputeBuffer buffer = new ComputeBuffer(_newPoints.Length, 12);
        buffer.SetData(_newPoints);
        _computeShader.SetBuffer(kernel, "points", buffer);
        _computeShader.SetTexture(kernel, "Result", texture);
        _computeShader.SetInt("textureSize", textureSize);
        _computeShader.SetInt("gridSize", gridSize);
        _computeShader.SetInt("textureChannel", channel);
        _computeShader.Dispatch(kernel, 8, 8, 8);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        CaluclateContainerBounds();
        _material.SetVector("_BoundsMin", boundsMin);
        _material.SetVector("_BoundsMax", boundsMax);
        if(GetComponent<Camera>())
            RaycastCornerBlit(source, destination, _material);
    }

    void RaycastCornerBlit(RenderTexture source, RenderTexture dest, Material mat)
    {
        Camera _camera = GetComponent<Camera>();
        // Compute Frustum Corners
        float camFar = _camera.farClipPlane;
        float camFov = _camera.fieldOfView;
        float camAspect = _camera.aspect;

        float fovWHalf = camFov * 0.5f;

        Vector3 toRight = _camera.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
        Vector3 toTop = _camera.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 topLeft = (_camera.transform.forward - toRight + toTop);
        float camScale = topLeft.magnitude * camFar;

        topLeft.Normalize();
        topLeft *= camScale;

        Vector3 topRight = (_camera.transform.forward + toRight + toTop);
        topRight.Normalize();
        topRight *= camScale;

        Vector3 bottomRight = (_camera.transform.forward + toRight - toTop);
        bottomRight.Normalize();
        bottomRight *= camScale;

        Vector3 bottomLeft = (_camera.transform.forward - toRight - toTop);
        bottomLeft.Normalize();
        bottomLeft *= camScale;

        // Custom Blit, encoding Frustum Corners as additional Texture Coordinates
        RenderTexture.active = dest;

        mat.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        mat.SetPass(0);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.MultiTexCoord(1, bottomLeft);
        GL.Vertex3(0.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.MultiTexCoord(1, bottomRight);
        GL.Vertex3(1.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.MultiTexCoord(1, topRight);
        GL.Vertex3(1.0f, 1.0f, 0.0f);

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.MultiTexCoord(1, topLeft);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }
}

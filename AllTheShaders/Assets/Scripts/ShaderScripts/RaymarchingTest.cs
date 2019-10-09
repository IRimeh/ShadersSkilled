using System.Collections;
using System.Collections.Generic;
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
    [SerializeField]
    private int _textureSize = 256;
    [SerializeField]
    private int _gridSize = 8;
    [SerializeField]
    private bool _generateTexture;
    [SerializeField]
    private bool _printArray = false;

    private Vector3 boundsMin;
    private Vector3 boundsMax;

    private Texture3D tex3D;
    private Vector3[,,] texturePoints;

    private Vector3[] _points;
    private Vector3[] _newPoints;

    private void Start()
    {
        Texture3D tex = CreateTexture3D(_textureSize, _gridSize);
        _material.SetTexture("_3DNoiseTex", tex);
    }

    private void CaluclateContainerBounds()
    {
        if (_container)
        {
            boundsMin = _container.transform.position - _container.transform.localScale / 2;
            boundsMax = _container.transform.position + _container.transform.localScale / 2;
        }
    }

    private void GenerateTexturePoints(int textureSize, int gridSize)
    {
        Vector3[,,] tempTexturePoints = new Vector3[gridSize, gridSize, gridSize];
        float textureStepSize = (float)textureSize / (float)gridSize;

        //Generate points in texture
        for (int x = 0; x < gridSize; x++)
        {
            for (int y = 0; y < gridSize; y++)
            {
                for (int z = 0; z < gridSize; z++)
                {
                    Vector3 startCoords = new Vector3(x * textureStepSize, y * textureStepSize, z * textureStepSize);
                    Vector3 randomOffset = new Vector3(Random.Range(0, textureStepSize), Random.Range(0, textureStepSize), Random.Range(0, textureStepSize));

                    tempTexturePoints[x, y, z] = startCoords + randomOffset;
                    //Debug.Log(tempTexturePoints[x, y, z]);
                }
            }
        }

        //Copy points to make texture wrap seamlessly
        texturePoints = new Vector3[gridSize * 3, gridSize * 3, gridSize * 3];
        for (int x = 0; x < 3; x++)
        {
            for (int y = 0; y < 3; y++)
            {
                for (int z = 0; z < 3; z++)
                {
                    int xStartPoint = x * gridSize;
                    int yStartPoint = y * gridSize;
                    int zStartPoint = z * gridSize;

                    Vector3 offset = new Vector3((x - 1) * textureSize, (y - 1) * textureSize, (z - 1) * textureSize);
                    for (int x2 = 0; x2 < gridSize; x2++)
                    {
                        for (int y2 = 0; y2 < gridSize; y2++)
                        {
                            for (int z2 = 0; z2 < gridSize; z2++)
                            {
                                texturePoints[xStartPoint + x2, yStartPoint + y2, zStartPoint + z2] = tempTexturePoints[x2, y2, z2] + offset;
                            }
                        }
                    }
                }
            }
        }
    }

    Texture3D CreateTexture3D(int textureSize, int gridSize)
    {
        Color[] colorArray = new Color[textureSize * textureSize * textureSize];
        Texture3D texture = new Texture3D(textureSize, textureSize, textureSize, TextureFormat.RGBA32, true);

        GenerateTexturePoints(textureSize, gridSize);

        float stepSize = textureSize / gridSize;
        float r = 1.0f / (textureSize - 1.0f);
        for (int x = 0; x < textureSize; x++)
        {
            for (int y = 0; y < textureSize; y++)
            {
                for (int z = 0; z < textureSize; z++)
                {
                    int xIndex = (int)Mathf.Floor((float)x / stepSize) + gridSize - 1;
                    int yIndex = (int)Mathf.Floor((float)y / stepSize) + gridSize - 1;
                    int zIndex = (int)Mathf.Floor((float)z / stepSize) + gridSize - 1;

                    float minDistance = float.MaxValue;
                    for (int width = xIndex; width < xIndex + 3; width++)
                    {
                        for (int height = yIndex; height < yIndex + 3; height++)
                        {
                            for (int depth = zIndex; depth < zIndex + 3; depth++)
                            {
                                float dist = Vector3.Distance(texturePoints[width, height, depth], new Vector3(x, y, z));
                                if (dist < minDistance)
                                    minDistance = dist;
                            }
                        }
                    }
                    minDistance /= stepSize;

                    Color c = new Color(minDistance, minDistance, minDistance, minDistance);
                    colorArray[x + (y * textureSize) + (z * textureSize * textureSize)] = c;
                }
            }
        }
        texture.SetPixels(colorArray);
        texture.Apply();
        return texture;
    }

    private void OnValidate()
    {
        if(_generateTexture)
        {
            _generateTexture = false;

            int mainKernel = _computeShader.FindKernel("CSMain");
            int pointGenerationKernel = _computeShader.FindKernel("PointGenerator");

            //Create rendertexture
            RenderTexture tex = new RenderTexture(_textureSize, _textureSize, 0);
            tex.enableRandomWrite = true;
            tex.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
            tex.volumeDepth = _textureSize;
            tex.wrapMode = TextureWrapMode.Repeat;
            tex.Create();

            //Create structuredbuffer
            _points = new Vector3[_gridSize * _gridSize * _gridSize];
            _newPoints = new Vector3[_gridSize * _gridSize * _gridSize];

            //Generate points
            GeneratePoints(pointGenerationKernel);

            //Generate worley noise
            GenerateWorleyNoise(mainKernel, tex);
            
            _material.SetTexture("_3DNoiseTex", tex);
        }
    }

    private void GeneratePoints(int kernel)
    {
        ComputeBuffer buffer = new ComputeBuffer(_points.Length, 12);
        buffer.SetData(_points);
        _computeShader.SetBuffer(kernel, "points", buffer);
        _computeShader.SetInt("textureSize", _textureSize);
        _computeShader.SetInt("gridSize", _gridSize);
        _computeShader.Dispatch(kernel, 1, 1, 1);

        buffer.GetData(_newPoints);
    }

    private void GenerateWorleyNoise(int kernel, RenderTexture texture)
    {
        ComputeBuffer buffer = new ComputeBuffer(_newPoints.Length, 12);
        buffer.SetData(_newPoints);
        _computeShader.SetBuffer(kernel, "points", buffer);
        _computeShader.SetTexture(kernel, "Result", texture);
        _computeShader.SetInt("textureSize", _textureSize);
        _computeShader.SetInt("gridSize", _gridSize);
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

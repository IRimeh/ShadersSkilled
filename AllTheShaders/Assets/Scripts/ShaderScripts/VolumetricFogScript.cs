using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class VolumetricFogScript : MonoBehaviour
{
    [SerializeField]
    private GameObject _container;
    [SerializeField]
    private Material _volumetricFogMaterial;
    [SerializeField]
    private bool FindSpotlights;

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
    private Vector3Int _dispatchGroupSize = new Vector3Int(1, 1, 1);
    [SerializeField]
    private bool _generateTexture;
    [SerializeField]
    private bool _generateOnStart = false;

    private Vector3 boundsMin;
    private Vector3 boundsMax;

    private Light[] lights;
    //Spotlights
    private List<Light> spotLights = new List<Light>();
    private List<Vector4> spotLightPositions = new List<Vector4>();
    private List<Vector4> spotLightDirections = new List<Vector4>();
    private List<Vector4> spotLightUpDirections = new List<Vector4>();
    private List<Vector4> spotLightRangeAngles = new List<Vector4>();
    private List<Vector4> spotLightColors = new List<Vector4>();
    private List<Texture2D> spotLightGrainTextures = new List<Texture2D>();
    private Texture2DArray finalSpotLightGrainTextures;
    private List<float> textureIndices = new List<float>();

    //Pointlights
    private List<Light> pointLights = new List<Light>();
    private List<Vector4> pointLightPositions = new List<Vector4>();
    private List<Vector4> pointLightColors = new List<Vector4>();
    private List<Vector4> pointLightRangeIntensity = new List<Vector4>();

    //Voronoi noise
    private Texture3D tex3D;
    private Vector3[,,] texturePoints;

    private Vector3[] _points;
    private Vector3[] _newPoints;
    private RenderTexture _renderTex;


    private void FindLights()
    {
        spotLights = new List<Light>();
        pointLights = new List<Light>();

        //Find lights
        lights = FindObjectsOfType(typeof(Light)) as Light[];
        foreach (Light light in lights)
        {
            switch (light.type)
            {
                case LightType.Spot:
                    spotLights.Add(light);
                    break;
                case LightType.Point:
                    pointLights.Add(light);
                    break;
                default:
                    break;
            }
        }

        FindSpotLights();
        FindPointLights();
    }

    private void FindSpotLights()
    {
        //Initialize lists
        spotLightPositions = new List<Vector4>();
        spotLightDirections = new List<Vector4>();
        spotLightUpDirections = new List<Vector4>();
        spotLightRangeAngles = new List<Vector4>();
        spotLightColors = new List<Vector4>();
        spotLightGrainTextures.Clear();
        spotLightGrainTextures = new List<Texture2D>();
        textureIndices = new List<float>();

        foreach (Light spot in spotLights)
        {
            spotLightPositions.Add(spot.transform.position);
            spotLightDirections.Add(spot.transform.forward);
            spotLightUpDirections.Add(spot.transform.up);
            spotLightColors.Add(new Vector4(spot.color.r, spot.color.g, spot.color.b, spot.intensity));
            Vector4 vec = new Vector4(spot.range, spot.spotAngle, 0.25f, 0);
            LightshaftSettings settings = spot.GetComponent<LightshaftSettings>();
            if (settings)
            {
                vec = new Vector4(vec.x, vec.y, settings.GetIntensity(), 0);
                if (settings.IsGrainEnabled())
                {
                    spotLightGrainTextures.Add(settings.GetGrainTexture());
                    textureIndices.Add(spotLightGrainTextures.Count - 1);
                }
                else
                {
                    textureIndices.Add(1000);
                }
            }
            spotLightRangeAngles.Add(vec);
        }

        //Create texture array for cookies
        if (spotLightGrainTextures.Count > 0)
        {
            finalSpotLightGrainTextures = new Texture2DArray(spotLightGrainTextures[0].width, spotLightGrainTextures[0].height, spotLightGrainTextures.Count, TextureFormat.RGBA32, true, false);
            finalSpotLightGrainTextures.filterMode = FilterMode.Bilinear;
            finalSpotLightGrainTextures.wrapMode = TextureWrapMode.Repeat;
            for (int i = 0; i < spotLightGrainTextures.Count; i++)
            {
                finalSpotLightGrainTextures.SetPixels(spotLightGrainTextures[i].GetPixels(0), i, 0);
            }
            finalSpotLightGrainTextures.Apply();
        }
    }

    private void FindPointLights()
    {
        //Point lights
        pointLightPositions = new List<Vector4>();
        pointLightColors = new List<Vector4>();
        pointLightRangeIntensity = new List<Vector4>();

        foreach (Light point in pointLights)
        {
            pointLightPositions.Add(point.transform.position);
            pointLightColors.Add(new Vector4(point.color.r, point.color.g, point.color.b, point.intensity));
            Vector4 vec = new Vector4(point.range, 0.25f, 0, 0);
            LightshaftSettings settings = point.GetComponent<LightshaftSettings>();
            if (settings)
            {
                vec = new Vector4(vec.x, settings.GetIntensity());
            }
            pointLightRangeIntensity.Add(vec);
        }
    }
    private void Start()
    {
        if (_generateOnStart)
        {
            Generate();
        }
    }

    private void Update()
    {
        FindLights();
    }

    private void OnValidate()
    {
        FindLights();
        if (_generateTexture)
        {
            _generateTexture = false;
            Generate();
        }
    }

    private void Generate()
    {
        DateTime startTime = DateTime.Now;
        Debug.Log("Starting time: " + startTime.TimeOfDay);


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

        DateTime endTime = DateTime.Now;
        Debug.Log("End time: " + endTime.TimeOfDay);
        Debug.Log("Time elapsed: " + (endTime - startTime).TotalSeconds + " seconds");

        _volumetricFogMaterial.SetTexture("_FogVolume", _renderTex);
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
        _computeShader.Dispatch(kernel, _dispatchGroupSize.x, _dispatchGroupSize.y, _dispatchGroupSize.z);
    }

    private void CaluclateContainerBounds()
    {
        if (_container)
        {
            boundsMin = _container.transform.position - _container.transform.localScale / 2;
            boundsMax = _container.transform.position + _container.transform.localScale / 2;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (GetComponent<Camera>())
        {
            //Bounds
            CaluclateContainerBounds();
            _volumetricFogMaterial.SetVector("_BoundsMin", boundsMin);
            _volumetricFogMaterial.SetVector("_BoundsMax", boundsMax);

            //Lights
            //SpotLights
            _volumetricFogMaterial.SetInt("_NumSpotLights", spotLights.Count);
            if (spotLights.Count > 0)
            {
                _volumetricFogMaterial.SetVectorArray("_SpotLightPositions", spotLightPositions);
                _volumetricFogMaterial.SetVectorArray("_SpotLightDirections", spotLightDirections);
                _volumetricFogMaterial.SetVectorArray("_SpotLightUpDirections", spotLightUpDirections);
                _volumetricFogMaterial.SetVectorArray("_SpotLightRangeAngles", spotLightRangeAngles);
                _volumetricFogMaterial.SetVectorArray("_SpotLightColors", spotLightColors);
                _volumetricFogMaterial.SetTexture("_CookieTextures", finalSpotLightGrainTextures);
                _volumetricFogMaterial.SetFloatArray("_CookieIndices", textureIndices);
            }

            //PointLights
            _volumetricFogMaterial.SetInt("_NumPointLights", pointLights.Count);
            if(pointLights.Count > 0)
            {
                _volumetricFogMaterial.SetVectorArray("_PointLightPositions", pointLightPositions);
                _volumetricFogMaterial.SetVectorArray("_PointLightColors", pointLightColors);
                _volumetricFogMaterial.SetVectorArray("_PointLightRangeIntensity", pointLightRangeIntensity);
            }

            //Blit
            RaycastCornerBlit(source, destination, _volumetricFogMaterial);
        }
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

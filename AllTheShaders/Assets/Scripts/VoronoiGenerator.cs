using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

[ExecuteInEditMode]
public class VoronoiGenerator : MonoBehaviour
{
    [SerializeField]
    private ComputeShader _computeShader;
    [SerializeField]
    private Texture2D _texture;
    private RenderTexture _renderTexture;

    [Header("Texture Options")]
    [SerializeField]
    private bool _inverted = false;
    [SerializeField]
    private int _gridSize = 8;
    [SerializeField]
    private Vector3Int _dispatchGroupSize = new Vector3Int(1, 1, 1);
    [SerializeField]
    private bool _generateTexture;
    [SerializeField]
    private bool _generateOnStart;


    private Texture3D tex3D;
    private Vector2[,,] texturePoints;

    private Vector2[] _points;
    private Vector2[] _newPoints;

    private RenderTexture _tempRenderTex;

    private void Awake()
    {
        if (_generateOnStart)
        {
            _generateOnStart = false;
            Generate();
        }
    }

    private void OnValidate()
    {
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
        _renderTexture = new RenderTexture(_texture.width, _texture.height, 32);
        _renderTexture.enableRandomWrite = true;
        _renderTexture.dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
        _renderTexture.wrapMode = TextureWrapMode.Repeat;
        _renderTexture.Create();

        //Dispatch compute shader to generate texture
        _points = new Vector2[_gridSize * _gridSize];
        _newPoints = new Vector2[_gridSize * _gridSize];
        GeneratePoints(pointGenerationKernel, _renderTexture.width, _gridSize);
        GenerateWorleyNoise(mainKernel, _renderTexture, _renderTexture.width, _gridSize);

        RenderTexture.active = _renderTexture;
        _texture.ReadPixels(new Rect(0, 0, _renderTexture.width, _renderTexture.height), 0, 0);
        _texture.Apply();

        DateTime endTime = DateTime.Now;
        Debug.Log("End time: " + endTime.TimeOfDay);
        Debug.Log("Time elapsed: " + (endTime - startTime).TotalSeconds + " seconds");
    }

    private void GeneratePoints(int kernel, int textureSize, int gridSize)
    {
        ComputeBuffer buffer = new ComputeBuffer(_points.Length, gridSize * gridSize * 2);
        buffer.SetData(_points);
        _computeShader.SetBuffer(kernel, "points", buffer);
        _computeShader.SetInt("textureSize", textureSize);
        _computeShader.SetInt("gridSize", gridSize);
        _computeShader.Dispatch(kernel, 1, 1, 1);

        buffer.GetData(_newPoints);
    }

    private void GenerateWorleyNoise(int kernel, RenderTexture texture, int textureSize, int gridSize)
    {
        ComputeBuffer buffer = new ComputeBuffer(_newPoints.Length, gridSize * gridSize * 2);
        buffer.SetData(_newPoints);
        _computeShader.SetBuffer(kernel, "points", buffer);
        _computeShader.SetTexture(kernel, "Result", texture);
        _computeShader.SetInt("textureSize", textureSize);
        _computeShader.SetInt("gridSize", gridSize);
        _computeShader.SetBool("inverted", _inverted);
        _computeShader.Dispatch(kernel, _dispatchGroupSize.x, _dispatchGroupSize.y, _dispatchGroupSize.z);
    }
}

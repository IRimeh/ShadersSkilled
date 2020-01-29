using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ScanEffect : MonoBehaviour
{
    [SerializeField]
    private Material scanMaterial;
    [SerializeField]
    private Transform scanner;
    [SerializeField]
    private float distance = 0;
    [SerializeField]
    [Range(0, 1)]
    private float scanSpeed = 1;
    [Header("Rim Variables")]
    [SerializeField]
    private Color rimStartColor;
    [SerializeField]
    private Color rimEndColor;
    [SerializeField]
    [Range(0, 1)]
    private float rimWidth = 0.1f;
    [Header("Background Variables")]
    [SerializeField]
    private Color backgroundColor;
    [SerializeField]
    private Color backgroundFadeColor;
    [SerializeField]
    private Color lineColor;
    [SerializeField]
    [Range(0, 100)]
    private float backgroundWidth = 5;
    [SerializeField]
    [Range(0, 10)]
    private float lineDensity = 2;
    [SerializeField]
    [Range(0, 100)]
    private float lineSize = 100;

    private Camera _camera;
    private bool _scanning = false;

    // Start is called before the first frame update
    void OnEnable()
    {
        _camera = GetComponent<Camera>();
        _camera.depthTextureMode = DepthTextureMode.Depth;
    }

    private void Start()
    {
        if (scanner)
            scanMaterial.SetVector("_WorldSpaceScannerPos", scanner.transform.position);
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.F))
        {
            _scanning = true;
            distance = 0;
            if (scanner)
                scanMaterial.SetVector("_WorldSpaceScannerPos", scanner.transform.position);
        }

        if (_scanning)
        {
            distance = Mathf.Lerp(distance, 500, Time.deltaTime * scanSpeed);
            if (distance >= 999.9f)
            {
                _scanning = false;
                distance = 0;
            }
        }
    }

    void OnRenderImage(RenderTexture source, RenderTexture dest)
    {
        RaycastCornerBlit(source, dest, scanMaterial);
        scanMaterial.SetFloat("_Distance", distance);
        //Rim
        scanMaterial.SetColor("_RimStartColor", rimStartColor);
        scanMaterial.SetColor("_RimEndColor", rimEndColor);
        scanMaterial.SetFloat("_RimWidth", rimWidth);
        //Background
        scanMaterial.SetColor("_BackgroundColor", backgroundColor);
        scanMaterial.SetColor("_BackgroundFadeColor", backgroundFadeColor);
        scanMaterial.SetColor("_LineColor", lineColor);
        scanMaterial.SetFloat("_LineDensity", lineDensity);
        scanMaterial.SetFloat("_LineSize", lineSize);
        scanMaterial.SetFloat("_BackgroundWidth", backgroundWidth);
    }

    void RaycastCornerBlit(RenderTexture source, RenderTexture dest, Material mat)
    {
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

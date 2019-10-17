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

    private Vector3 boundsMin;
    private Vector3 boundsMax;

    private Light[] lights;
    private List<Light> spotLights = new List<Light>();
    private List<Vector4> spotLightPositions = new List<Vector4>();
    private List<Vector4> spotLightDirections = new List<Vector4>();
    private List<Vector4> spotLightRangeAngles = new List<Vector4>();
    private List<Vector4> spotLightColors = new List<Vector4>();

    private void FindSpotLights()
    {
        spotLights = new List<Light>();
        spotLightPositions = new List<Vector4>();
        spotLightDirections = new List<Vector4>();
        spotLightRangeAngles = new List<Vector4>();
        spotLightColors = new List<Vector4>();
        lights = FindObjectsOfType(typeof(Light)) as Light[];
        foreach (Light light in lights)
        {
            if (light.type == LightType.Spot)
            {
                spotLights.Add(light);
            }
        }

        foreach (Light spot in spotLights)
        {
            spotLightPositions.Add(spot.transform.position);
            spotLightDirections.Add(spot.transform.forward);
            spotLightRangeAngles.Add(new Vector4(spot.range, spot.spotAngle, 0, 0));
            spotLightColors.Add(new Vector4(spot.color.r, spot.color.g, spot.color.b, spot.intensity));
        }
    }

    private void Update()
    {
        FindSpotLights();
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
            _volumetricFogMaterial.SetInt("_NumSpotLights", spotLights.Count);
            if (spotLights.Count > 0)
            {
                _volumetricFogMaterial.SetVectorArray("_SpotLightPositions", spotLightPositions);
                _volumetricFogMaterial.SetVectorArray("_SpotLightDirections", spotLightDirections);
                _volumetricFogMaterial.SetVectorArray("_SpotLightRangeAngles", spotLightRangeAngles);
                _volumetricFogMaterial.SetVectorArray("_SpotLightColors", spotLightColors);
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

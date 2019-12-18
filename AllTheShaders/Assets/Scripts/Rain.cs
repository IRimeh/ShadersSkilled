using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Rain : MonoBehaviour
{
    [SerializeField]
    private RenderTexture tex;

    private Renderer renderer;

    // Start is called before the first frame update
    void OnEnable()
    {
        renderer = GetComponent<Renderer>();
    }

    private void Update()
    {
        Camera camera = Camera.main;

        // boundsTarget is the center of the camera's frustum, in world coordinates:
        Vector3 camPosition = camera.transform.position;
        Vector3 normCamForward = Vector3.Normalize(camera.transform.forward);
        float boundsDistance = (camera.farClipPlane - camera.nearClipPlane) / 2 + camera.nearClipPlane;
        Vector3 boundsTarget = camPosition + (normCamForward * boundsDistance);

        // The game object's transform will be applied to the mesh's bounds for frustum culling checking.
        // We need to "undo" this transform by making the boundsTarget relative to the game object's transform:
        Vector3 realtiveBoundsTarget = this.transform.InverseTransformPoint(boundsTarget);

        // Set the bounds of the mesh to be a 1x1x1 cube (actually doesn't matter what the size is)
        Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
        mesh.bounds = new Bounds(realtiveBoundsTarget, Vector3.one * 10000);



        renderer.sharedMaterial.SetTexture("_DepthTexture", tex);
        renderer.sharedMaterial.SetVector("_UVscale", new Vector4(renderer.bounds.size.x, renderer.bounds.size.z, 0, 0));
        renderer.sharedMaterial.SetVector("_BottomRightCorner", new Vector4(transform.position.x, transform.position.z, 0, 0) - new Vector4(renderer.bounds.extents.x, renderer.bounds.extents.z, 0, 0));
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class TransitionScript : MonoBehaviour
{
    [SerializeField]
    private Texture2D Texture;
    [SerializeField]
    private Vector2 Tiling = new Vector2(1,1);
    [SerializeField]
    [ColorUsageAttribute(true, true)]
    private Color TransitionColor;
    [SerializeField]
    private Color TransitionSecondaryColor;
    [SerializeField]
    [Range(-1, 20)]
    private float Range = 0;
    [SerializeField]
    [Range(0, 10)]
    private float Width = 1;
    [SerializeField]
    [Range(0, 1)]
    private float OppositeWidth = 0.2f;
    [SerializeField]
    [Range(1, 16)]
    private float ThickeningValue = 1;
    [SerializeField]
    [Range(1, 16)]
    private float ThinningValue = 1;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("_OriginPosition", transform.position);
    }

    private void OnValidate()
    {
        Shader.SetGlobalFloat("_TransitionRange", Range);
        Shader.SetGlobalFloat("_TransitionWidth", Width);
        Shader.SetGlobalFloat("_TransitionOppositeWidth", OppositeWidth);
        Shader.SetGlobalTexture("_TransitionTexture", Texture);
        Shader.SetGlobalVector("_TransitionTextureTiling", Tiling);

        Shader.SetGlobalFloat("_Thickening", ThickeningValue);
        Shader.SetGlobalFloat("_Thinning", ThinningValue);
        Shader.SetGlobalColor("_TransitionColor", TransitionColor);
        Shader.SetGlobalColor("_TransitionSecondaryColor", TransitionSecondaryColor);
    }
}

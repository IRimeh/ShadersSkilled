using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(LightshaftSettings))]
public class LightshaftAnimation : MonoBehaviour
{
    [SerializeField]
    private List<Texture2D> textures = new List<Texture2D>();
    [SerializeField]
    [Range(0, 5)]
    private int frameSkip = 0;
    [SerializeField]
    private bool playAnimation = false;

    private int index = 0;
    private int frameSkipIndex = 0;
    private int changeVal = 1;

    LightshaftSettings settings;
    // Start is called before the first frame update
    void Start()
    {
        settings = GetComponent<LightshaftSettings>();
    }

    // Update is called once per frame
    void Update()
    {
        if (textures.Count > 1 && playAnimation)
        {
            if (frameSkipIndex >= frameSkip)
            {
                frameSkipIndex = 0;

                settings.SetGrainTexture(textures[index]);

                index += changeVal;
                if (index >= textures.Count - 1)
                    changeVal = -1;
                else if (index <= 0)
                    changeVal = 1;
            }
            else
            {
                frameSkipIndex++;
            }
        }
    }
}

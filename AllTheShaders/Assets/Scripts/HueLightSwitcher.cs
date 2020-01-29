using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Light))]
public class HueLightSwitcher : MonoBehaviour
{
    [SerializeField]
    private float _cycleSpeed = 1.0f;

    private Light light;

    // Start is called before the first frame update
    void Start()
    {
        light = GetComponent<Light>();
    }

    // Update is called once per frame
    void Update()
    {
        float hue;
        float saturation;
        float brightness;
        Color.RGBToHSV(light.color, out hue, out saturation, out brightness);

        hue += Time.deltaTime * _cycleSpeed;

        light.color = Color.HSVToRGB(hue, saturation, brightness);
    }
}

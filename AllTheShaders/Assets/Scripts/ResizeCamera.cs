using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class ResizeCamera : MonoBehaviour
{

    public enum CameraView
    {
        Free = 0,
        Square
    }

    [SerializeField]
    CameraView cameraView = CameraView.Square;
    [SerializeField]
    bool center = true;
    [SerializeField]
    [Range(0.0f, 1.0f)]
    float scale = 1.0f;
    [SerializeField]
    bool runOnlyOnce = false;

    // Internal
    float _cachedHeight = 0.0f;
    float _cachedWidth = 0.0f;

    void Start()
    {
        this.CheckScreenType();
    }

    void Update()
    {
        if (!this.runOnlyOnce)
        {
            this.CheckScreenType();
        }
    }

    void CheckScreenType()
    {
        switch (this.cameraView)
        {
            case CameraView.Square:
                this.SetSquare();
                break;
            case CameraView.Free:
                {
                    this.GetComponent<Camera>().rect = new Rect(0.0f, 0.0f, 1.0f, 1.0f);
                }
                break;
            default:
                break;
        }
    }

    /// <summary>
    /// Gets the size of the screen.
    /// </summary>
    void RefreshScreenSize()
    {
        this._cachedHeight = Screen.height;
        this._cachedWidth = Screen.width;
    }

    /// <summary>
    /// Sets the square.
    /// </summary>
    void SetSquare()
    {
        this.RefreshScreenSize();
        if (this._cachedHeight < this._cachedWidth)
        {
            float ratio = this._cachedHeight / this._cachedWidth;

            this.GetComponent<Camera>().rect = new Rect(this.GetComponent<Camera>().rect.x, this.GetComponent<Camera>().rect.y, ratio, 1.0f);

            if (this.center == true)
            {
                this.GetComponent<Camera>().rect = new Rect(((1.0f - ratio * this.scale) / 2), this.GetComponent<Camera>().rect.y * this.scale, this.GetComponent<Camera>().rect.width * this.scale, this.GetComponent<Camera>().rect.height * this.scale);
            }
        }
        else
        {
            float ratio = this._cachedWidth / this._cachedHeight;

            this.GetComponent<Camera>().rect = new Rect(this.GetComponent<Camera>().rect.x, this.GetComponent<Camera>().rect.y, 1.0f, ratio);

            if (this.center == true)
            {
                this.GetComponent<Camera>().rect = new Rect(this.GetComponent<Camera>().rect.x, (1.0f - ratio) / 2, this.GetComponent<Camera>().rect.width, this.GetComponent<Camera>().rect.height);
            }
        }
    }

    public void ScrictView(CameraView cameraView)
    {
        this.cameraView = cameraView;
    }
}
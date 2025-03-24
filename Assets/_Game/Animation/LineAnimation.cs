using UnityEngine;

public class LineAnimation : MonoBehaviour
{
    public Material material;
    public float speed = 0.5f;
    private float offsetY = 0f;

    void Update()
    {
        if (material != null)
        {
            offsetY += Time.deltaTime * speed;
            material.SetTextureOffset("_BaseMap", new Vector2(0, offsetY));
        }
    }
}
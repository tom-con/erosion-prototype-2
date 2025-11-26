shader_type canvas_item;
uniform vec4 team_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Default to red

void fragment() {
    // Get the current pixel's color from the texture
    vec4 col = texture(TEXTURE, UV);

    // Define the color to be replaced (e.g., pure green)
    vec4 mask_color = vec4(0.0, 1.0, 0.0, 1.0);

    // Use a small tolerance for floating point comparisons
    float tolerance = 0.01;

    // Check if the pixel color is close to the mask color
    if (abs(col.r - mask_color.r) < tolerance && 
        abs(col.g - mask_color.g) < tolerance && 
        abs(col.b - mask_color.b) < tolerance) {
        
        // If it matches, use the team color, preserving original alpha/darkness
        COLOR.rgb = team_color.rgb * col.g; // Multiply by the green channel's intensity to keep shading/darkness
        COLOR.a = col.a;
    } else {
        // Otherwise, keep the original color
        COLOR = col;
    }
}
// ~/.config/ghostty/border.glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 color = texture(iChannel0, fragCoord / iResolution.xy);
    float w = 1.0; // border width in pixels
    if (fragCoord.x < w || fragCoord.y < w ||
        fragCoord.x > iResolution.x - w || fragCoord.y > iResolution.y - w) {
        color = vec4(0.4, 0.4, 0.4, 1.0); // border color (RGBA, 0–1)
    }
    fragColor = color;
}

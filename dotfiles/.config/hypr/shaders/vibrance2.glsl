/*
 * Vibrance seguro - ThinkPad T14 Gen 1 / AUO B140HAN04.0 / LEN40A9
 *
 * Objetivo:
 * - reduzir o aspecto lavado do painel 45% NTSC;
 * - aquecer levemente a imagem;
 * - aumentar a percepção de cor sem estourar pele, anime, fotos e gradientes.
 *
 * Ajustes recomendados:
 * Vibrance: 0.10 a 0.18
 * Warmth:   0.00 a 0.03
 */

#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// Seguro para uso diário
const float Vibrance = 0.13;

// Leve aquecimento. Aumenta um pouco vermelho e reduz um pouco azul.
// 0.00 = neutro
// 0.015–0.025 = bom para painel frio/azulado
const float Warmth = 0.018;

// Evita que a imagem passe dos limites depois dos ajustes
vec3 safeClamp(vec3 c) {
    return clamp(c, 0.0, 1.0);
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 color = pixColor.rgb;

    /*
     * Leve correção de temperatura.
     * Isso é mais seguro que mexer agressivamente em RGB com
     * vec3(1.05, 1.10, 0.90), porque não empurra o verde demais.
     */
    color *= vec3(1.0 + Warmth, 1.0, 1.0 - Warmth);
    color = safeClamp(color);

    /*
     * Luminância Rec.709.
     * Mantém a percepção de brilho mais natural.
     */
    const vec3 lumaCoeff = vec3(0.2126, 0.7152, 0.0722);
    float luma = dot(color, lumaCoeff);

    /*
     * Mede saturação simples pelo intervalo entre maior e menor canal.
     */
    float maxColor = max(color.r, max(color.g, color.b));
    float minColor = min(color.r, min(color.g, color.b));
    float saturation = maxColor - minColor;

    /*
     * Vibrance:
     * - cores pouco saturadas recebem mais aumento;
     * - cores já saturadas recebem menos aumento;
     * - isso evita o visual artificial de "modo vívido".
     */
    float vib = Vibrance * (1.0 - saturation);

    /*
     * Mistura entre cinza/luminância e a cor original.
     * Fator acima de 1.0 aumenta saturação de forma controlada.
     */
    vec3 adjustedColor = mix(vec3(luma), color, 1.0 + vib);

    adjustedColor = safeClamp(adjustedColor);

    fragColor = vec4(adjustedColor, pixColor.a);
}

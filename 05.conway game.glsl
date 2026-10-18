#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform int pointerCount;
uniform vec3 pointers[10];
uniform sampler2D backbuffer;

float oneIfZero(float value) {
	return step(abs(value), 0.1);
}

vec4 get4(float x, float y) {
	return texture2D(
		backbuffer,
		(gl_FragCoord.xy + vec2(x, y)) / resolution
	);
}

/*
 * R 通道 = 生命状态
 * B 通道 = 余晖
 *
 * 不再使用原 backbuffer 的 alpha 作为生命状态。
 */
float get(float x, float y) {
	return step(0.5, get4(x, y).r);
}

vec4 evaluate(float sum) {
	vec4 cell = get4(0.0, 0.0);

	float wasAlive = step(0.5, cell.r);

	float has3 = oneIfZero(sum - 3.0);
	float has2 = oneIfZero(sum - 2.0);

	float isAlive = min(1.0, has3 + has2 * wasAlive);
	float justDied = (1.0 - isAlive) * wasAlive;

	/*
	 * B 通道只保存我们自己的余晖。
	 */
	float oldGlow = cell.b;

	float glow;

	if (isAlive > 0.0) {
		/*
		 * 活细胞保持完整亮度。
		 */
		glow = 1.0;
	}
	else if (justDied > 0.0) {
		/*
		 * 刚死亡，从完整亮度开始进入余晖。
		 */
		glow = 1.0;
	}
	else {
		/*
		 * 已经死亡，继续衰减余晖。
		 */
		glow = oldGlow * 0.96;
	}

	if (glow < 0.005) {
		glow = 0.0;
	}

	/*
	 * R = alive 状态
	 * G/B = 可见的青色余晖
	 *
	 * 因此：
	 * 没有生命、没有余晖 -> RGB 全黑
	 */
	return vec4(
		isAlive,
		glow,
		glow,
		isAlive
	);
}

void main() {
	float sum =
		get(-1.0, -1.0) +
		get(-1.0,  0.0) +
		get(-1.0,  1.0) +
		get( 0.0, -1.0) +
		get( 0.0,  1.0) +
		get( 1.0, -1.0) +
		get( 1.0,  0.0) +
		get( 1.0,  1.0);

	float tapSize = min(resolution.x, resolution.y) * 0.05;

	for (int n = 0; n < pointerCount; ++n) {
		if (distance(pointers[n].xy, gl_FragCoord.xy) < tapSize) {
			sum = 3.0;
			break;
		}
	}

	gl_FragColor = evaluate(sum);
}

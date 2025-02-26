shader_type sky;
render_mode use_debanding;

uniform vec4 sky_top_day_color : source_color = vec4(0.385, 0.454, 0.55, 1.0);
uniform vec4 sky_top_sunset_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform vec4 sky_top_night_color : source_color = vec4(0.0, 0.0, 0.1, 1.0);
uniform vec4 sky_horizon_day_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);
uniform vec4 sky_horizon_sunset_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform vec4 sky_horizon_night_color : source_color = vec4(0.0, 0.0, 0.2, 1.0);
uniform float sky_curve : hint_range(0, 1) = 0.15;
uniform float sky_energy = 1.0; // In Lux.
uniform sampler2D sky_cover : filter_linear, source_color, hint_default_black;
uniform vec4 sky_cover_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 ground_bottom_color : source_color = vec4(0.2, 0.169, 0.133, 1.0);
uniform float ground_curve : hint_range(0, 1) = 0.02;
uniform float ground_energy = 1.0;
uniform float sun_angle_max = 30.0;
uniform float sun_curve : hint_range(0, 1) = 0.15;

uniform sampler2D cloud_texture;
uniform sampler2D cloud_texture2;
uniform vec2 cloud_direction;
uniform vec2 cloud_direction2;
uniform vec2 cloud_scale;
uniform float cloud_distance;
uniform float cloud_speed;
uniform float cloud_speed2;

uniform float time : hint_range(0, 1) = 0.5; // Time of day, from 0.0 (midnight) to 1.0 (next midnight).

void sky() {
    float v_angle = acos(clamp(EYEDIR.y, -1.0, 1.0));
    float c = (1.0 - v_angle / (PI * 0.5));

    vec3 sky_top_color, sky_horizon_color;

    if (time < 0.021) {
        // Sunset to Day
        sky_top_color = mix(sky_top_sunset_color.rgb, sky_top_day_color.rgb, smoothstep(0.0, 0.021, time));
        sky_horizon_color = mix(sky_horizon_sunset_color.rgb, sky_horizon_day_color.rgb, smoothstep(0.0, 0.021, time));
    } else if (time < 0.51) {
        // Day to Sunset
        sky_top_color = mix(sky_top_day_color.rgb, sky_top_sunset_color.rgb, smoothstep(0.48, 0.50, time));
        sky_horizon_color = mix(sky_horizon_day_color.rgb, sky_horizon_sunset_color.rgb, smoothstep(0.48, 0.50, time));
    } else if (time < 0.52) {
        // Sunset to Night
        sky_top_color = mix(sky_top_sunset_color.rgb, sky_top_night_color.rgb, smoothstep(0.50, 0.52, time));
        sky_horizon_color = mix(sky_horizon_sunset_color.rgb, sky_horizon_night_color.rgb, smoothstep(0.50, 0.52, time));
    } else if (time < 0.98) {
        // Night
        sky_top_color = sky_top_night_color.rgb;
        sky_horizon_color = sky_horizon_night_color.rgb;
    } else {
        // Night to Sunset
        sky_top_color = mix(sky_top_night_color.rgb, sky_top_sunset_color.rgb, smoothstep(0.98, 1.0, time));
        sky_horizon_color = mix(sky_horizon_night_color.rgb, sky_horizon_sunset_color.rgb, smoothstep(0.98, 1.0, time));
    }

    vec3 sky = mix(sky_horizon_color, sky_top_color, clamp(1.0 - pow(1.0 - c, 1.0 / sky_curve), 0.0, 1.0));
    sky *= sky_energy;

    vec3 sun_color = vec3(1.0, 0.85, 0.55); // Sun color.
    vec3 moon_color = vec3(0.8, 0.8, 1.0); // Moon color.
    vec3 light_color = mix(moon_color, sun_color, smoothstep(0.15, 0.75, time));

    vec3 light_direction = vec3(0.0, sin(time * PI * 2.0), cos(time * PI * 2.0));

    float sun_angle = acos(dot(light_direction, EYEDIR));
    if (sun_angle < 0.1) {
        sky = light_color * sky_energy;
    }

    vec4 sky_cover_texture = texture(sky_cover, SKY_COORDS);
    sky += (sky_cover_texture.rgb * sky_cover_modulate.rgb) * sky_cover_texture.a * sky_cover_modulate.a * sky_energy;

    c = (v_angle - (PI * 0.5)) / (PI * 0.5);
    vec3 ground = mix(sky_horizon_color, ground_bottom_color.rgb, clamp(1.0 - pow(1.0 - c, 1.0 / ground_curve), 0.0, 1.0));
    ground *= ground_energy;

    vec2 sky_uv = EYEDIR.xz / EYEDIR.y;
    vec3 clouds = texture(cloud_texture, (sky_uv * cloud_scale) + (TIME * cloud_direction * cloud_speed * 0.01)).rgb - texture(cloud_texture2, (sky_uv * cloud_scale) + (TIME * cloud_direction2 * cloud_speed2 * 0.01)).rgb;
    clouds = clouds - smoothstep(0.0, EYEDIR.y, cloud_distance);
    clouds = clamp(clouds, 0, 1);
    sky += clouds;

    COLOR = mix(ground, sky, step(0.0, EYEDIR.y));
}

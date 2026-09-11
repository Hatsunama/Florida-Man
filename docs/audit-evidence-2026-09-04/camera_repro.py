"""Scalar reproduction of CameraController.lua:125-143, without Roblox.

This is arithmetic evidence, not a rendered camera or game-engine test.
Run with Python 3. It does not edit source or contact external services.
"""

import json

results = []
for hz in (30, 60, 120):
    for start in (100, 400, 800):
        look_x, velocity = start + 8.0, 0.0
        errors = []
        for frame in range(hz * 5):
            player_x = start + min(frame / hz, 3) * 18
            focus_x = player_x
            delta = focus_x - (look_x - 8)
            if abs(delta) > 3.5:
                sign = 1 if delta > 0 else -1
                focus_x = look_x - 8 + sign * (abs(delta) - 3.5) * 0.15 + focus_x * 0.85
            target = focus_x + 8
            velocity += ((target - look_x) * 48 - velocity * 15) / hz
            look_x += velocity / hz
            errors.append(look_x - player_x - 8)
        results.append({"hz": hz, "start_x": start, "final_look_error": errors[-1],
                        "min_look_error": min(errors), "max_look_error": max(errors)})

print(json.dumps(results, indent=2))

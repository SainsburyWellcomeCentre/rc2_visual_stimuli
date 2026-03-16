# Setup Configuration Files

This directory contains JSON configuration files for experimental setups. Each file defines the screen dimensions, resolution, and viewing geometry for a specific hardware configuration.

## File Structure

Each configuration file should follow this format:

```json
{
  "name": "setup_identifier",
  "description": "Brief description of the setup",
  "screen": {
    "width_mm": 347.0,
    "height_mm": 195.6,
    "width_px": 960,
    "height_px": 540
  },
  "viewing_geometry": {
    "eye_distance_mm": 150.0,
    "eye_position_mm": {
      "horizontal": 150.0,
      "vertical": 25.0
    }
  },
  "notes": "Optional notes about this configuration"
}
```

## Fields

- **name**: Identifier for the setup (should match the filename without .json)
- **description**: User-friendly description shown when listing available setups
- **screen.width_mm**: Physical width of the screen in millimeters
- **screen.height_mm**: Physical height of the screen in millimeters
- **screen.width_px**: Screen resolution width in pixels
- **screen.height_px**: Screen resolution height in pixels
- **viewing_geometry.eye_distance_mm**: Distance from the eye to the screen in millimeters
- **viewing_geometry.eye_position_mm.horizontal**: Horizontal position on screen closest to eye (mm)
- **viewing_geometry.eye_position_mm.vertical**: Vertical position on screen closest to eye (mm)
- **notes**: Optional field for additional information

## Adding a New Setup

1. Copy `_template.json` to a new file named `your_setup_name.json`
2. Fill in all the fields with your setup's parameters
3. Save the file
4. The setup will automatically be available in `get_setup_config()`

## Example Usage

```matlab
% List all available setups
get_setup_config()

% Load a specific setup with verbose output
config = get_setup_config('mp_300', true);

% Load silently
config = get_setup_config('wisecoco', false);
```

## Available Setups

- **mp_300.json**: MP-300 projector setup for mouse visual neuroscience
- **wisecoco.json**: Wisecoco OLED goggles for binocular mouse stimulation
- **stereo_goggles.json**: Generic stereo goggle display (800x400px split-screen)
- **samsung_cfg73.json**: Samsung CFG73 monitor configuration
- **sony_projector.json**: Sony projector setup

## Stereo Display Configuration

For stereo displays (e.g., VR goggles with side-by-side eye views), additional fields can be specified:

```json
{
  "name": "stereo_goggles",
  "screen": {
    "width_mm": 30.0,
    "height_mm": 30.0,
    "width_px": 400,
    "height_px": 400
  },
  "stereo": {
    "enabled": true,
    "mode": 4,
    "full_display_px": [800, 400],
    "per_eye_px": [400, 400]
  },
  "notes": "Per-eye dimensions should be specified in screen.width/height_px"
}
```

**Important**: For stereo setups, use `StereoPsychoToolbox` instead of `PsychoToolbox`:

```matlab
ptb = StereoPsychoToolbox();
ptb.stereo_mode = 4;  % Dual-display split-screen
setup = SetupInfo(ptb, 'stereo_goggles', screen_number);
```

See `examples/stereo_example.m` for a complete usage example.

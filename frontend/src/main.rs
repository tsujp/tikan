use bevy::{prelude::*, sprite::MaterialMesh2dBundle, window::WindowResolution};

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ColorMaterial>>,
) {
    commands.spawn(Camera2dBundle::default());
    commands.spawn(MaterialMesh2dBundle {
        // TODO: What is `.into()`?
        mesh: meshes.add(Mesh::from(shape::Quad::default())).into(),
        transform: Transform::default().with_scale(Vec3 {
            x: 50.,
            y: 50.,
            z: 0.,
        }),
        // 2d mesh material tinted by given `Color`.
        material: materials.add(ColorMaterial::from(Color::PURPLE)),
        ..default()
    });
}

pub struct TikanPlugin;

// TODO:
// - Board from Mesh2D.
// - Button on screen with a callback(?) for when it is clicked.
// - Rust hello world WASM bundle.
// - Try and call the hello world bundle from the button callback and display
//   the text that the hello world wasm bundle returns.

impl Plugin for TikanPlugin {
    fn build(&self, app: &mut App) {
        app.add_plugins(DefaultPlugins.set(WindowPlugin {
            // Customise window properties as part of DefaultPlugins PluginGroup.
            primary_window: Some(Window {
                title: "Tikan - Zero Knowledge Fog of War Chess".to_string(),
                resolution: WindowResolution::new(1024., 768.),
                resizable: false,
                ..default()
            }),
            ..default()
        }))
        .insert_resource(ClearColor(Color::Rgba {
            red: 0.,
            green: 1.,
            blue: 0.1,
            alpha: 1.,
        }))
        .add_systems(Startup, setup);
    }
}

fn main() {
    App::new().add_plugins(TikanPlugin).run();
}

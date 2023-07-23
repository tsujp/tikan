use bevy::{prelude::*, sprite::MaterialMesh2dBundle, window::WindowResolution};

// Marker component to make querying for our camera easier.
#[derive(Component)]
struct MainCamera;

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ColorMaterial>>,
) {
    // Queues an entity comprised of the Camera2dBundle (set of components) and
    //   our marker component MainCamera. I.e. the camera we're spawning here
    //   we've added our `MainCamera` component to. The tuple syntax here is for
    //   an anonymous bundle (bundles are just sets of components).
    commands.spawn((Camera2dBundle::default(), MainCamera));

    // Board (TODO: entire board and in parent container for easier moving)
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

fn debug_coordinates(
    // Parameter `camera` contains all `Camera` components that also have a
    //   `MainCamera` component.
    mut camera: Query<(&Camera, &GlobalTransform, &mut Transform), With<MainCamera>>,
) {
    // for c in &camera {
    //     println!("camera info: {:?}", c);
    // }

    // XXX: `get_single()` does not panic if there is a non-single but exception
    //      handling... how best to abort out. Maybe later.
    let (c, c_globtrans, mut c_trans) = camera.single_mut();

    println!("Camera is at: {:?}", c_globtrans.translation());

    c_trans.translation = Vec3 {
        x: 50.,
        y: 50.,
        z: 999.9,
    };

    // the size of the area being rendered to
    // let view_dimensions = c.logical_viewport_size().unwrap();

    // // the top-left and bottom-right coordinates
    // let (corner1, corner2) = c.logical_viewport_rect().unwrap();

    // println!(
    //     "View dimen: {:?}, coords {:?} {:?}",
    //     view_dimensions, corner1, corner2
    // );
}

// TODO:
// - Show camera's coordinates.
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
        .add_systems(Startup, setup)
        .add_systems(Update, debug_coordinates);
    }
}

fn main() {
    App::new().add_plugins(TikanPlugin).run();
}

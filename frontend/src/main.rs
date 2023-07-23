use bevy::{prelude::*, sprite::MaterialMesh2dBundle, window::WindowResolution};

// Marker (unit) component to make querying for our camera easier.
#[derive(Component)]
struct MainCamera;

// Unit component for debug text.
#[derive(Component)]
struct DebugText;

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

    // Camera position text.
    // To construct template-able strings you must use multiple sections for a
    //   single TextBundle and then set the appropriate section in your system.
    // You could use a single section and rewrite it but different colours
    //   per characters and static characters become harder to manage.
    commands.spawn((
        TextBundle::from_sections([
            // TextSection at index 0, used as static text.
            TextSection::new(
                "Camera pos: ",
                TextStyle {
                    font: TextStyle::default().font,
                    font_size: 18.,
                    color: Color::BLACK,
                },
            ),
            // TextSection at index 1, where we'll set the value to be the
            //   camera's translation in our Update system. Since we don't
            //   want a default value we'll create a TextSection using the
            //       `from_style` helper.
            TextSection::from_style(TextStyle {
                font_size: 18.,
                color: Color::RED,
                ..default()
            }),
        ])
        // Alignment (optional AFAIK).
        .with_text_alignment(TextAlignment::Left)
        // Style (optional AFAIK).
        .with_style(Style {
            position_type: PositionType::Absolute,
            left: Val::Px(5.),
            top: Val::Px(5.),
            ..default()
        }),
        DebugText,
    ));
}

pub struct TikanPlugin;

fn debug_coordinates(
    // Parameter `camera` contains all `Camera` components that also have a
    //   `MainCamera` component.
    mut camera: Query<(&Camera, &GlobalTransform, &mut Transform), With<MainCamera>>,
    mut q_text: Query<&mut Text, With<DebugText>>,
) {
    // for c in &camera {
    //     println!("camera info: {:?}", c);
    // }

    // XXX: `get_single()` does not panic if there is a non-single but exception
    //      handling... how best to abort out. Maybe later.
    let (c, c_globtrans, mut c_trans) = camera.single_mut();

    // println!("Camera is at: {:?}", c_globtrans.translation());

    let mut text = q_text.single_mut();
    text.sections[1].value = format!("{}", c_globtrans.translation());

    // c_trans.translation = Vec3 {
    //     x: 50.,
    //     y: 50.,
    //     z: 999.9,
    // };

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

use std::rc::Rc;

use bevy::{
    math,
    prelude::*,
    render::view::NoFrustumCulling,
    sprite::{MaterialMesh2dBundle, Mesh2dHandle},
    window::WindowResolution,
};

// Marker (unit) component to make querying for our camera easier.
#[derive(Component)]
struct MainCamera;

// Debug text unit component.
#[derive(Component)]
struct DebugText;

// Chess board unit component.
#[derive(Component)]
struct ChessBoard;

// Chess board square unit component.
#[derive(Component)]
struct ChessBoardSquare;

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ColorMaterial>>,
    q_window: Query<&Window>,
) {
    // Default camera origin of 0,0 in the centre I do not want. No corner is
    //   best but 0,0 at the top-left means +x moves rightwards and -y moves
    //   downwards. This new origin I'll call: canonical.
    let window = q_window.single();
    let x_canonical = window.width() / 2.;
    let y_canonical = window.height() / 2. * -1.;

    // Queues an entity comprised of the Camera2dBundle (set of components) and
    //   our marker component MainCamera. I.e. the camera we're spawning here
    //   we've added our `MainCamera` component to. The tuple syntax here is for
    //   an anonymous bundle (bundles are just sets of components).
    commands.spawn((
        Camera2dBundle {
            transform: Transform::from_xyz(x_canonical, y_canonical, 500.),
            // transform: Transform::from_xyz(0., 0., 999.),
            ..default()
        },
        MainCamera,
    ));

    // Board (TODO: entire board and in parent container for easier moving)

    // TODO: Move to constants and/or some config area.
    let SQUARE_SIZE = 60.;
    let BOARD_SIZE = 8;

    let board_width = (SQUARE_SIZE * BOARD_SIZE as f32);

    let square = meshes.add(Mesh::from(shape::Quad::new(
        (SQUARE_SIZE, SQUARE_SIZE).into(),
    )));
    let black = materials.add(ColorMaterial::from(Color::hex("#D18B47").unwrap()));
    let white = materials.add(ColorMaterial::from(Color::hex("#FFCE9E").unwrap()));

    commands
        .spawn((
            SpatialBundle {
                transform: Transform::from_xyz(
                    x_canonical - ((board_width - SQUARE_SIZE) / 2.),
                    y_canonical + ((board_width - SQUARE_SIZE) / -2.),
                    0.,
                ),
                ..default()
            },
            ChessBoard,
        ))
        .with_children(|parent| {
            for i in 0..64 {
                let x = (i % BOARD_SIZE) as f32 * SQUARE_SIZE;
                let y = (i / BOARD_SIZE) as f32 * SQUARE_SIZE;
                let square_idx = i + 1 + (i / BOARD_SIZE);

                // Board squares are children of ChessBoard.
                parent.spawn((
                    MaterialMesh2dBundle {
                        mesh: square.clone().into(),
                        material: if square_idx % 2 == 0 {
                            white.clone()
                        } else {
                            black.clone()
                        },
                        transform: Transform::from_translation(Vec3 { x, y, z: 0. }),
                        ..default()
                    },
                    ChessBoardSquare,
                ));
            }
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

fn mouse_button_input(buttons: Res<Input<MouseButton>>) {
    if buttons.just_pressed(MouseButton::Left) {
        println!("Left mouse button clicked!");
    }
}

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
// - How does Bevy implement it's UI elements? If they are just meshes with
//   custom hover logic etc consider using them -- however 2d intersection
//   detection isn't particularly hard.
// - Button on screen with a callback(?) for when it is clicked.
// - Rust hello world WASM bundle.
// - Try and call the hello world bundle from the button callback and display
//   the text that the hello world wasm bundle returns.

impl Plugin for TikanPlugin {
    fn build(&self, app: &mut App) {
        app.add_plugins(DefaultPlugins.set(WindowPlugin {
            // Customise window properties as part of DefaultPlugins PluginGroup.
            primary_window: Some(Window {
                title: "Tikan - Zero Knowledge Fog of War Chess".into(),
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
        .add_systems(Update, (mouse_button_input, debug_coordinates));
    }
}

fn main() {
    App::new().add_plugins(TikanPlugin).run();
}

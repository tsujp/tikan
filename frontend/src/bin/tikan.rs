use bevy::{prelude::*, sprite::MaterialMesh2dBundle, window::WindowResolution};
use gloo_console::log;
use gloo_worker::Spawnable;
// use tikan::CoinFlip;
use tikan::Multiplier;

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

// Move trigger (call Noir circuit) unit component.
#[derive(Component)]
struct MoveTrigger;

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ColorMaterial>>,
    q_window: Query<&Window>,
) {
    // Basic button element.
    // TODO: This is a proof of concept for (1) click a thing, (2) something
    //       happens (3) result is shown back. Eventually this will be hooked
    //       up to chess pieces such that when the player makes a move the
    //       callback to invoke the Noir circuit is run.
    commands
        .spawn((
            ButtonBundle {
                style: Style {
                    width: Val::Px(150.),
                    height: Val::Px(50.),
                    border: UiRect::all(Val::Px(5.)),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    position_type: PositionType::Absolute,
                    left: Val::Px(10.),
                    bottom: Val::Px(200.),
                    ..default()
                },
                border_color: BorderColor(Color::RED),
                background_color: BackgroundColor(Color::BLACK),
                ..default()
            },
            MoveTrigger,
        ))
        .with_children(|parent| {
            parent.spawn(TextBundle::from_section(
                "Do The Thing",
                TextStyle {
                    font: TextStyle::default().font,
                    font_size: 18.,
                    color: Color::WHITE,
                },
            ));
        });

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

    let board_width = SQUARE_SIZE * BOARD_SIZE as f32;

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

fn mouse_button_input(
    mut q_triggers: Query<
        (&Interaction, &mut BackgroundColor),
        (Changed<Interaction>, With<MoveTrigger>),
    >,
    // buttons: Res<Input<MouseButton>>
) {
    if let Ok((interaction, mut colour)) = q_triggers.get_single_mut() {
        // TODO: Why does this work with and without a dereference on the
        //       variable `interaction` i.e. with or without `*interaction`?
        match interaction {
            Interaction::Pressed => {
                println!("Button pressed");
                *colour = BackgroundColor(Color::CYAN);
            }
            Interaction::Hovered => {
                println!("Button hovered");
                *colour = BackgroundColor(Color::GRAY);
            }
            Interaction::None => {
                println!("Button back to normal");
                *colour = BackgroundColor(Color::BLACK);
            }
        }
    }

    // Iteration equivalent.
    // for (interaction, mut colour, mut border_colour) in &mut q_triggers {
    //     // TODO: What is the asterisk here?
    //     match *interaction {
    //         Interaction::Pressed => {
    //             println!("Button pressed");
    //         }
    //         Interaction::Hovered => {
    //             println!("Button hovered");
    //         }
    //         Interaction::None => {
    //             println!("Button back to normal");
    //         }
    //     }
    // }

    // if buttons.just_pressed(MouseButton::Left) {
    //     println!("Left mouse button clicked!");
    // }
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
        // console::log_1("Executing TikanPlugin".into());

        // Noir WASM backend is intimately tied to Tikan, I could make it
        //   optional in the future so that without the Noir WASM backend
        //   Tikan can be played in which case Tikan would be like any other
        //   Fog of War Chess implementation as there would be no guaranteed
        //   lack of information sharing; no zero-knowledge.
        // So, Noir WASM backend required.
        console_error_panic_hook::set_once();

        log!("Hello from Tikan!");

        let bridge = Multiplier::spawner()
            .callback(move |((a, b), result)| {
                log!(format!("{} * {} = {}", a, b, result));
            })
            .spawn("./worker.js");
        let bridge = Box::leak(Box::new(bridge));

        bridge.send((2, 5));
        bridge.send((3, 3));
        bridge.send((50, 5));

        // async {
        //     let mut coin_flip_bridge = CoinFlip::spawner().spawn("coin_flip.js");
        //     let res = coin_flip_bridge.run(5).await;
        //     log!("Waiting for future completion");
        //     assert_eq!(res, 10);
        // };

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

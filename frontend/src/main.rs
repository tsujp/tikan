use bevy::{prelude::*, window::WindowResolution};

fn setup(mut commands: Commands) {
    commands.spawn(Camera2dBundle::default());
}

pub struct TikanPlugin;

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
            alpha: 1.0,
        }))
        .add_systems(Startup, setup);
    }
}

fn main() {
    App::new().add_plugins(TikanPlugin).run();
}

use bevy::{prelude::*, window::WindowResolution};

pub struct TikanPlugin;

impl Plugin for TikanPlugin {
    fn build(&self, app: &mut App) {}
}

fn main() {
    App::new()
        // Customise window properties as part of DefaultPlugins PluginGroup.
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Tikan - Zero Knowledge Fog of War Chess".to_string(),
                // position: WindowPosition::Centered(MonitorSelection::Current),
                resolution: WindowResolution::new(1024., 768.),
                resizable: false,
                ..default()
            }),
            ..default()
        }))
        .run();
}

fn hello_world() {
    println!("hello world!");
}

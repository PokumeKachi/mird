use bevy::prelude::*;

#[derive(Component)]
struct Position {
    x: f32,
    y: f32,
}
#[derive(Component)]
struct Person;

fn main() {
    App::new()
        .add_systems(Startup, add_people)
        .add_systems(Update, (hello_world_system, print_position_system))
        .run();
}

fn hello_world_system() {
    println!("Hello world!");
}

fn add_people(mut commands: Commands) {
    commands.spawn((Person, Position { x: 4.5, y: 4.5 }));
}

fn print_position_system(query: Query<&Position>) {
    for position in &query {
        println!("position: {} {}", position.x, position.y);
    }
}

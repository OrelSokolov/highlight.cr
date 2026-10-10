//! Сервис пользователей
use std::collections::HashMap;
use std::fmt::{self, Display};

pub const MAX_RETRIES: u32 = 3;

#[derive(Debug, Clone, PartialEq)]
pub struct User {
    pub id: u64,
    pub name: String,
    pub age: u8,
}

impl Display for User {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} #{} ({})", self.name, self.id, self.age)
    }
}

pub fn find_users(ids: &[u64], map: &HashMap<u64, User>) -> Result<Vec<&User>, String> {
    let mut found = ids.iter().filter_map(|id| map.get(id)).collect::<Vec<_>>();
    if found.is_empty() {
        return Err(format!("no users in {:?}", ids));
    }
    found.sort_by_key(|u| u.age);
    Ok(found)
}

#[derive(thiserror::Error, Debug)]
enum Error {
    #[error("не найдено: {0}")]
    NotFound(String),
}

async fn process() -> anyhow::Result<()> {
    let v: Vec<i32> = (1..=5).map(|x| x * 2).filter(|x| x % 4 == 0).collect();
    let s = format!("сумма = {}", v.iter().sum::<i32>());
    println!("{s} 0x{:X} {:b} {}", 0xFF_u32, 0b1010, 1_000.5);
    let mut m = HashMap::new();
    m.insert("ключ", r#"raw "string""#);
    let Some(x) = v.first() else { return Ok(()) };
    let closure = |a: i32, b: i32| a + b + x;
    Ok(())
}

fn main() { let _ = 'outer: loop { break 'outer; }; }

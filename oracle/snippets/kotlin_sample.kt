package com.example.app

import kotlinx.coroutines.*
import java.time.LocalDate

// Сервис пользователей
data class User(val id: Int, val name: String, val age: Int = 0)

sealed interface Result<out T> {
    data class Ok<T>(val value: T) : Result<T>
    data class Err(val message: String) : Result<Nothing>
    object Loading : Result<Nothing>
}

class UserService(private val repo: UserRepository) {
    var cacheEnabled: Boolean = true
        get() = field && !BuildConfig.DEBUG

    suspend fun findUser(id: Int): Result<User> = withContext(Dispatchers.IO) {
        when (val u = repo.findById(id)) {
            null -> Result.Err("not found: $id")
            else -> Result.Ok(u)
        }
    }

    inline fun <reified T> parse(json: String): T? = try {
        mapper.readValue(json, T::class.java)
    } catch (e: Exception) {
        null
    }
}

fun main() = runBlocking {
    val svc = UserService(Repo())
    val nums = listOf(1, 2, 3).map { it * 2 }.filter { it > 2 }
    val (a, b) = 1 to "two"
    val range = 1..10 step 2
    val label = """raw "string" $not_interp"""
    repeat(3) { i -> println("iter $i") }
    println(svc.findUser(1).toString() + nums + a + label)
}

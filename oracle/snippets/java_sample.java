package com.example.app;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/** Сервис пользователей. */
public class UserService implements AutoCloseable {
    private static final int MAX_RETRIES = 3;

    private final Map<String, List<String>> roles;

    public UserService(Map<String, List<String>> roles) {
        this.roles = roles;
    }

    public List<String> findActiveUsers(List<User> users) throws IllegalAccessException {
        if (users == null || users.isEmpty()) {
            throw new IllegalAccessException("users required");
        }
        return users.stream()
                .filter(u -> u.isActive() && u.getAge() >= 18)
                .map(User::getName)
                .collect(Collectors.toList());
    }

    @Override
    public void close() {
        System.out.println("closed");
    }

    record Point(int x, int y) {}
    enum Status { OK, ERROR }
}

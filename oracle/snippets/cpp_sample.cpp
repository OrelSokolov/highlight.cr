#include <vector>
#include <string>
#include <memory>
#include <iostream>

// Современный C++
template <typename T, std::size_t N>
class Array {
public:
    explicit Array() : size_(N) {}
    T& operator[](std::size_t i) { return data_[i]; }
    constexpr std::size_t size() const noexcept { return size_; }
private:
    T data_[N]{};
    std::size_t size_;
};

namespace app::detail {
    using String = std::string;
    enum class Status : uint8_t { Ok, Error, Retry };

    struct Result {
        Status status{Status::Ok};
        String message;
        std::vector<int> codes{};
    };
}

int main() {
    auto ptr = std::make_unique<app::detail::Result>();
    ptr->message = "готово\x21";
    long long big = 1'000'000'000LL;
    double d = 3.14159e-5f;
    std::cout << ptr->message << ' ' << big << std::endl;
    return static_cast<int>(app::detail::Status::Ok);
}

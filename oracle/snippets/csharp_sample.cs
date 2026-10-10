using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MyApp.Services
{
    /// <summary>Сервис пользователей.</summary>
    public class UserService : IUserService
    {
        private readonly IReadOnlyList<string> _roles = new[] { "admin", "user" };

        public async Task<User?> FindAsync(int id, bool includeDeleted = false)
        {
            if (id <= 0) throw new ArgumentOutOfRangeException(nameof(id));

            var users = new Dictionary<int, User>
            {
                [1] = new User("Олег", 42),
            };
            var query = from u in users.Values
                        where u.Age > 18 && !includeDeleted
                        select u.Name;

            await Task.Delay(10);
            return users.GetValueOrDefault(id);
        }

        [Obsolete("Use FindAsync")]
        public User? Find(int id) => default;
    }

    public record User(string Name, int Age);
}

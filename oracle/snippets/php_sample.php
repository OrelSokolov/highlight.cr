<?php
declare(strict_types=1);

namespace App\Service;

use App\Models\{User, Post};
use Illuminate\Support\Collection;

/**
 * Сервис пользователей.
 */
final class UserService
{
    public const MAX_AGE = 100;

    private array $cache = [];

    public function __construct(
        private readonly string $dsn = 'mysql:host=localhost',
    ) {
    }

    public function findUsers(array $ids = []): Collection
    {
        $ids ??= [1, 2, 3];
        $users = User::whereIn('id', $ids)->orderBy('name', 'desc')->get();
        $names = $users->map(fn (User $u) => mb_strtoupper($u->name))->toArray();

        return collect($names)->filter(function ($n) {
            return mb_strlen($n ?? '') > 2;
        });
    }

    public static function parse(string $json = '{"a":1}'): ?array
    {
        try {
            $data = json_decode($json, true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException $e) {
            return null;
        }
        return $data;
    }
}

$svc = new UserService();
echo "Привет, {$user->name}!", PHP_EOL;
$x = 0x1F + 0b101 + 1_000 + 1.5e3;
if ($x > 100 && $x !== null) { echo "big"; } elseif (!$x) { echo 'small'; }
?>
<b>вне PHP</b> <?= $x ?> plain text

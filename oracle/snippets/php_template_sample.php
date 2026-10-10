<html>
<head><title>Отчёт <?= $title ?></title></head>
<body>
<?php foreach ($items as $key => $item): ?>
  <div class="item" data-id="<?= (int) $item['id'] ?>">
    <?= htmlspecialchars($item['name'], ENT_QUOTES) ?>
    <?php if ($item['active']): ?><b>активен</b><?php endif; ?>
  </div>
<?php endforeach; ?>
<?php if (empty($items)): ?>
  <p>Ничего не найдено</p>
<?php endif; ?>
<footer><?php include 'footer.php' ?></footer>
</body>
</html>

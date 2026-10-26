-- NEXRIG STORE sample catalog. Run AFTER schema.sql in Supabase SQL Editor.
-- Prices in PHP are DEMO values, not live store quotations.
-- Product images use bundled category illustrations in the Flutter app.
-- Safe to re-run: existing product names are skipped.
insert into public.products (name, category, description, image_url, price, stock)
select v.name, v.category, v.description, v.image_url, v.price, v.stock
from (values
  ('AMD Ryzen 5 5600', 'Processors', '6-core AM4 desktop processor', 'assets/products/cpu.webp', 6795, 18),
  ('AMD Ryzen 7 5700X', 'Processors', '8-core AM4 processor', 'assets/products/cpu.webp', 10995, 12),
  ('AMD Ryzen 5 7600', 'Processors', '6-core AM5 processor', 'assets/products/cpu.webp', 12495, 10),
  ('Intel Core i5-12400F', 'Processors', '12th-gen desktop CPU', 'assets/products/cpu.webp', 7995, 16),
  ('Intel Core i5-13400F', 'Processors', '13th-gen desktop CPU', 'assets/products/cpu.webp', 11995, 9),
  ('GeForce RTX 4060 8GB', 'Graphics Cards', '1080p gaming graphics card', 'assets/products/gpu.webp', 18995, 8),
  ('GeForce RTX 4060 Ti 8GB', 'Graphics Cards', 'High-refresh 1080p GPU', 'assets/products/gpu.webp', 24995, 6),
  ('GeForce RTX 4070 SUPER 12GB', 'Graphics Cards', '1440p gaming graphics card', 'assets/products/gpu.webp', 38995, 5),
  ('Radeon RX 7600 8GB', 'Graphics Cards', 'Mainstream gaming graphics card', 'assets/products/gpu.webp', 16995, 10),
  ('Radeon RX 7700 XT 12GB', 'Graphics Cards', '1440p gaming graphics card', 'assets/products/gpu.webp', 28995, 6),
  ('B550M AM4 Motherboard', 'Motherboards', 'Micro-ATX motherboard for AM4 CPUs', 'assets/products/motherboard.webp', 5995, 15),
  ('B650M AM5 Motherboard', 'Motherboards', 'DDR5-ready AM5 motherboard', 'assets/products/motherboard.webp', 9495, 10),
  ('B760M DDR4 Motherboard', 'Motherboards', 'Intel LGA1700 micro-ATX board', 'assets/products/motherboard.webp', 7495, 12),
  ('X670E ATX Motherboard', 'Motherboards', 'Premium AM5 motherboard', 'assets/products/motherboard.webp', 19995, 4),
  ('16GB DDR4 3200MHz Kit', 'Memory', '2x8GB dual-channel DDR4', 'assets/products/ram.webp', 2495, 25),
  ('32GB DDR4 3200MHz Kit', 'Memory', '2x16GB dual-channel DDR4', 'assets/products/ram.webp', 4495, 20),
  ('16GB DDR5 5600MHz Kit', 'Memory', '2x8GB DDR5 memory', 'assets/products/ram.webp', 3495, 20),
  ('32GB DDR5 6000MHz Kit', 'Memory', '2x16GB DDR5 gaming memory', 'assets/products/ram.webp', 6495, 14),
  ('500GB NVMe SSD', 'Storage', 'M.2 solid-state storage', 'assets/products/ram.webp', 2295, 30),
  ('1TB NVMe SSD', 'Storage', 'M.2 SSD for games and apps', 'assets/products/ram.webp', 3995, 28),
  ('2TB NVMe SSD', 'Storage', 'High-capacity M.2 SSD', 'assets/products/ram.webp', 7495, 15),
  ('2TB SATA HDD', 'Storage', 'Hard drive for bulk storage', 'assets/products/ram.webp', 3295, 15),
  ('Mesh Airflow mATX Case', 'Cases', 'Ventilated micro-ATX PC case', 'assets/products/case.webp', 2795, 18),
  ('Tempered Glass ATX Case', 'Cases', 'Mid-tower case with glass panel', 'assets/products/case.webp', 3995, 12),
  ('Compact Mini Tower Case', 'Cases', 'Space-saving PC case', 'assets/products/case.webp', 2395, 10),
  ('120mm RGB Fan Triple Pack', 'Cooling', 'Three RGB case cooling fans', 'assets/products/cooler.webp', 1495, 20),
  ('Tower CPU Air Cooler', 'Cooling', 'Heatpipe air cooling solution', 'assets/products/cooler.webp', 1795, 20),
  ('240mm AIO Liquid Cooler', 'Cooling', 'All-in-one liquid CPU cooler', 'assets/products/cooler.webp', 4995, 10),
  ('550W 80+ Bronze PSU', 'Power Supplies', 'Entry-level desktop power supply', 'assets/products/case.webp', 2895, 16),
  ('650W 80+ Bronze PSU', 'Power Supplies', 'Midrange desktop power supply', 'assets/products/case.webp', 3595, 14),
  ('750W 80+ Gold PSU', 'Power Supplies', 'Efficient modular power supply', 'assets/products/case.webp', 6295, 10),
  ('24-inch 1080p 100Hz Monitor', 'Monitors', 'Full HD monitor for work and play', 'assets/products/monitor.webp', 5995, 12),
  ('24-inch 1080p 165Hz Monitor', 'Monitors', 'High-refresh gaming display', 'assets/products/monitor.webp', 8495, 10),
  ('27-inch 1440p 165Hz Monitor', 'Monitors', 'QHD gaming monitor', 'assets/products/monitor.webp', 15995, 6),
  ('RGB Mechanical Keyboard', 'Keyboards', 'Mechanical gaming keyboard', 'assets/products/keyboard.webp', 1995, 25),
  ('TKL Mechanical Keyboard', 'Keyboards', 'Compact tenkeyless gaming keyboard', 'assets/products/keyboard.webp', 2495, 20),
  ('Wired Gaming Mouse', 'Mice', 'Adjustable DPI gaming mouse', 'assets/products/mouse.webp', 895, 30),
  ('Wireless Gaming Mouse', 'Mice', 'Rechargeable wireless mouse', 'assets/products/mouse.webp', 1795, 25)
) as v(name, category, description, image_url, price, stock)
where not exists (select 1 from public.products p where p.name = v.name);

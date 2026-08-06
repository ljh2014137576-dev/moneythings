/// 自定义分类可选图标集（黑白线性，符合视觉规范）
library;

import 'package:flutter/material.dart';

const List<(String, IconData)> kCategoryIconChoices = [
  ('flight', Icons.flight_outlined),
  ('pets', Icons.pets_outlined),
  ('fitness', Icons.fitness_center_outlined),
  ('coffee', Icons.coffee_outlined),
  ('fastfood', Icons.fastfood_outlined),
  ('local_cafe', Icons.local_cafe_outlined),
  ('local_drink', Icons.local_drink_outlined),
  ('liquor', Icons.liquor_outlined),
  ('cake', Icons.cake_outlined),
  ('child_friendly', Icons.child_friendly_outlined),
  ('school', Icons.school_outlined),
  ('book', Icons.menu_book_outlined),
  ('headphones', Icons.headphones_outlined),
  ('videogame', Icons.sports_esports_outlined),
  ('camera', Icons.photo_camera_outlined),
  ('favorite', Icons.favorite_outline_rounded),
  ('celebration', Icons.celebration_outlined),
  ('card_gift', Icons.card_giftcard_outlined),
  ('redeem', Icons.redeem_outlined),
  ('handyman', Icons.handyman_outlined),
  ('home_repair', Icons.home_repair_service_outlined),
  ('cleaning', Icons.cleaning_services_outlined),
  ('laundry', Icons.local_laundry_service_outlined),
  ('directions_car', Icons.directions_car_outlined),
  ('two_wheeler', Icons.two_wheeler_outlined),
  ('local_taxi', Icons.local_taxi_outlined),
  ('train', Icons.train_outlined),
  ('directions_bike', Icons.directions_bike_outlined),
  ('local_gas', Icons.local_gas_station_outlined),
  ('phone', Icons.phone_outlined),
  ('laptop', Icons.laptop_outlined),
  ('tv', Icons.tv_outlined),
  ('device', Icons.devices_outlined),
  ('monitor', Icons.monitor_heart_outlined),
  ('health', Icons.health_and_safety_outlined),
  ('spa', Icons.spa_outlined),
  ('baby', Icons.stroller_outlined),
  ('music', Icons.music_note_outlined),
  ('palette', Icons.palette_outlined),
  ('more', Icons.more_horiz_outlined),
];

/// 按 key 找图标；找不到回退到「更多」
IconData categoryIconByKey(String key) {
  for (final c in kCategoryIconChoices) {
    if (c.$1 == key) return c.$2;
  }
  return Icons.more_horiz_outlined;
}

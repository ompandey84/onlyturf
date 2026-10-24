import 'package:flutter/material.dart';

class AmenityItem {
  final String name;
  final IconData icon;

  const AmenityItem({required this.name, required this.icon});
}

// Ensure you export this list to be used in AddFacilityScreen & EditFacilityScreen
const List<AmenityItem> amenitiesList = [
  AmenityItem(name: 'WiFi', icon: Icons.wifi),
  AmenityItem(name: 'Parking', icon: Icons.local_parking),
  AmenityItem(name: 'Drinking Water', icon: Icons.water_drop),
  AmenityItem(name: 'First Aid', icon: Icons.medical_services),
  AmenityItem(name: 'Washroom', icon: Icons.wc),
  AmenityItem(name: 'Changing Room', icon: Icons.checkroom),
  AmenityItem(name: 'Lockers', icon: Icons.lock),
  AmenityItem(name: 'Showers', icon: Icons.shower),
  AmenityItem(name: 'Seating Area', icon: Icons.chair),
  AmenityItem(name: 'Cafeteria', icon: Icons.restaurant),
  AmenityItem(name: 'Vending Machine', icon: Icons.kitchen),
  AmenityItem(name: 'CCTV Security', icon: Icons.videocam),
  AmenityItem(name: 'Floodlights', icon: Icons.lightbulb),
  AmenityItem(name: 'Equipment Rental', icon: Icons.sports_tennis),
  AmenityItem(name: 'Balls Provided', icon: Icons.sports_soccer),
  AmenityItem(name: 'Bibs Provided', icon: Icons.checkroom),
  AmenityItem(name: 'Scoreboard', icon: Icons.score),
  AmenityItem(name: 'Referee Available', icon: Icons.sports),
  AmenityItem(name: 'Coaching Available', icon: Icons.people),
  AmenityItem(name: 'Physio On-Call', icon: Icons.health_and_safety),
  AmenityItem(name: 'Wheelchair Accessible', icon: Icons.accessible_forward),
  AmenityItem(name: 'Power Backup', icon: Icons.battery_charging_full),
  AmenityItem(name: 'Live Screening', icon: Icons.tv),
  AmenityItem(name: 'Music System', icon: Icons.speaker),
  AmenityItem(name: 'AC Indoor', icon: Icons.ac_unit),
  AmenityItem(name: 'Clean Turf', icon: Icons.grass),
  AmenityItem(name: 'Wooden Floor', icon: Icons.layers),
  AmenityItem(name: 'Synthetic Track', icon: Icons.directions_run),
  AmenityItem(name: 'Swimming Pool', icon: Icons.pool),
  AmenityItem(name: 'Gym Access', icon: Icons.fitness_center),
  AmenityItem(name: 'Warm-up Area', icon: Icons.fitness_center),
  AmenityItem(name: 'Resting Lounge', icon: Icons.weekend),
  AmenityItem(name: 'Pro Shop', icon: Icons.storefront),
  AmenityItem(name: 'Shoe Rental', icon: Icons.shopping_bag),
  AmenityItem(name: 'Dedicated Umpire Chair', icon: Icons.chair_alt),
  AmenityItem(name: 'Water Cooler', icon: Icons.kitchen),
  AmenityItem(name: 'Ice Bath Facility', icon: Icons.hot_tub),
  AmenityItem(name: 'Yoga Mats', icon: Icons.sports_gymnastics),
  AmenityItem(name: 'Free Weights', icon: Icons.fitness_center),
  AmenityItem(name: 'Cardio Machines', icon: Icons.directions_run),
  AmenityItem(name: 'Child Play Area', icon: Icons.child_care),
  AmenityItem(name: 'Pet Friendly', icon: Icons.pets),
  AmenityItem(name: 'Electric Vehicle Charging', icon: Icons.ev_station),
  AmenityItem(name: 'Bike Parking', icon: Icons.pedal_bike),
  AmenityItem(name: 'Valet Parking', icon: Icons.directions_car),
  AmenityItem(name: 'Locker Rental', icon: Icons.vpn_key),
  AmenityItem(name: 'Towel Service', icon: Icons.dry_cleaning),
  AmenityItem(name: 'Massage Therapy', icon: Icons.spa),
  AmenityItem(name: 'Video Recording', icon: Icons.video_camera_front),
  AmenityItem(name: 'Photography Services', icon: Icons.camera_alt),
];

const List<String> cancellationPolicies = ['Flexible', 'Moderate', 'Strict'];

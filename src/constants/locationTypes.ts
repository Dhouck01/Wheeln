import { LocationType } from '../types';

// Friendly names for the location_type values stored in the database
export const LOCATION_TYPE_LABELS: Record<LocationType, string> = {
  track: 'Track',
  autocross: 'Autocross',
  drag_strip: 'Drag Strip',
  off_road_trail: 'Off-Road Trail',
  off_road_park: 'Off-Road Park',
  car_show: 'Car Show',
  overlanding: 'Overlanding',
  karting: 'Karting',
  moto_track: 'Moto Track',
  gravel_ride: 'Gravel Ride',
  rock_crawl: 'Rock Crawl',
  cars_and_coffee: 'Cars & Coffee',
  other: 'Other',
};

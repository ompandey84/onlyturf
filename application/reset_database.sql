-- DATABASE RESET SCRIPT
-- WARNING: This script will DELETE ALL DATA and RECREATE tables from scratch.

-- ==========================================
-- 1. DROP EXISTING TABLES (CLEANUP)
-- ==========================================

DROP TABLE IF EXISTS public.bookings CASCADE;
DROP TABLE IF EXISTS public.facilities CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Also drop functions/triggers to be safe
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- ==========================================
-- 2. SETUP TABLES & SECURITY
-- ==========================================

-- Create Profiles Table (Linked to Auth)
create table public.profiles (
  id uuid references auth.users not null primary key,
  email text,
  full_name text,
  city text,
  mobile text,
  avatar_url text,
  updated_at timestamp with time zone
);

-- Handle New User Signups (Trigger)
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, city, mobile, avatar_url)
  values (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'full_name', 
    new.raw_user_meta_data->>'city',
    new.raw_user_meta_data->>'mobile',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- Create Facilities Table
create table public.facilities (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text not null,
  description text,
  location text,
  lat numeric, -- Latitude
  long numeric, -- Longitude
  sport_type text, -- e.g., 'Football', 'Tennis', 'Badminton'
  price_per_hour numeric not null,
  rating numeric default 0,
  image_url text, -- Main display image
  images text[], -- Array of additional images
  amenities text[], -- e.g. ['Parking', 'Showers']
  is_featured boolean default false,
  is_partnered boolean default false,
  open_24_7 boolean default false,
  turf_height text -- e.g., '50mm', '60mm'
);

-- Create Bookings Table
create table public.bookings (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  facility_id uuid references public.facilities(id) not null,
  user_id uuid references auth.users not null,
  date date not null,
  time_slot text not null, -- e.g., '18:00 - 19:00'
  status text default 'confirmed', -- confirmed, cancelled, pending
  total_price numeric not null,
  sport text
);

-- Create Reviews Table
create table public.reviews (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  facility_id uuid references public.facilities(id) not null,
  user_id uuid references public.profiles(id) not null,
  rating numeric not null,
  comment text not null
);

-- RLS Policies (Row Level Security)
alter table public.profiles enable row level security;
alter table public.facilities enable row level security;
alter table public.bookings enable row level security;

-- Profiles: Public read, User update own
create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);
create policy "Users can update own profile." on public.profiles for update using (auth.uid() = id);

-- Facilities: Public read
create policy "Facilities are viewable by everyone." on public.facilities for select using (true);

-- Bookings: User view/create own
create policy "Users can view own bookings." on public.bookings for select using (auth.uid() = user_id);
create policy "Users can create bookings." on public.bookings for insert with check (auth.uid() = user_id);

-- Reviews: Public read, User create own
alter table public.reviews enable row level security;
create policy "Reviews are viewable by everyone." on public.reviews for select using (true);
create policy "Users can insert own reviews." on public.reviews for insert with check (auth.uid() = user_id);
create policy "Users can update own reviews." on public.reviews for update using (auth.uid() = user_id);
create policy "Users can delete own reviews." on public.reviews for delete using (auth.uid() = user_id);


-- ==========================================
-- 3. INSERT INITIAL DATA (INDIAN LOCALIZATION)
-- ==========================================
-- Data updated with Coordinates (approximated for demo), Partnered, 24x7, and Turf Height info.

INSERT INTO public.facilities (name, description, location, lat, long, sport_type, price_per_hour, rating, image_url, images, amenities, is_featured, is_partnered, open_24_7, turf_height) VALUES
('Demo Turf', 'A perfect turf for testing functionality. Located in the heart of Mumbai.', 'Mumbai, Maharashtra', 19.0760, 72.8777, 'Football', 1500.0, 5.0, 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?q=80&w=2070&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1529900748604-07564a03e7a6'], ARRAY['Parking', 'Changing Room', 'Water'], true, true, true, '50mm'),
('Mumbai Football Arena', 'Professional standard football turf.', 'Andheri Sports Complex, Mumbai', 19.1171, 72.8347, 'Football', 2500.0, 4.8, 'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?q=80&w=2070&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d'], ARRAY['Floodlights', 'Seating', 'Cafe'], true, true, false, '60mm'),
('Bengaluru Badminton Club', 'Indoor wooden courts with BWF standards.', 'Koramangala, Bangalore', 12.9352, 77.6245, 'Badminton', 800.0, 4.7, 'https://images.unsplash.com/photo-1626224583764-847890e058f5?q=80&w=2000&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1626224583764-847890e058f5'], ARRAY['Lockers', 'Showers', 'Pro Shop'], true, false, false, NULL),
('Delhi Smashers Tennis', 'Clay and hard courts available.', 'Saket, Delhi', 28.5245, 77.2183, 'Tennis', 1200.0, 4.5, 'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=2000&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0'], ARRAY['Coaching', 'Parking'], false, false, false, NULL),
('Hyderabad Cricket Ground', 'Net practice with bowling machine.', 'Gachibowli, Hyderabad', 17.4401, 78.3489, 'Cricket', 2000.0, 4.6, 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?q=80&w=2000&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1531415074968-036ba1b575da'], ARRAY['Kit Rental', 'Cafe'], true, true, true, NULL),
('Pune Swimming Complex', 'Olympic size pool with temperature control.', 'Balewadi, Pune', 18.5793, 73.7630, 'Swimming', 500.0, 4.4, 'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?q=80&w=2000&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7'], ARRAY['Lifeguard', 'Showers'], false, false, false, NULL),
('Chennai Smash Court', 'Synthetic badminton courts.', 'Anna Nagar, Chennai', 13.0827, 80.2117, 'Badminton', 600.0, 4.3, 'https://images.unsplash.com/photo-1613918108466-292b78a8ef95?q=80&w=2000&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1613918108466-292b78a8ef95'], ARRAY['Parking'], false, false, false, NULL),
('Kolkata Kickoff', '5-a-side rooftop football.', 'Salt Lake, Kolkata', 22.5726, 88.3639, 'Football', 1800.0, 4.7, 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=2000&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1518609878373-06d740f60d8b'], ARRAY['Floodlights', 'Beverages'], true, true, true, '40mm'),
('Holkar Cricket Stadium', 'Iconic cricket stadium available for practice sessions.', 'Race Course Road, Indore', 22.7238, 75.8837, 'Cricket', 3000.0, 4.9, 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?q=80&w=2000&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1531415074968-036ba1b575da'], ARRAY['Pavilion', 'Floodlights', 'Dressing Room'], true, true, false, NULL),
('Indore Tennis Club', 'Premium clay courts in the heart of the city.', 'Palasia, Indore', 22.7262, 75.8887, 'Tennis', 1000.0, 4.6, 'https://images.unsplash.com/photo-1622163642998-1ea36b0d52f6?q=80&w=2000&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1622163642998-1ea36b0d52f6'], ARRAY['Coaching', 'Equipment Rental'], true, false, false, NULL),
('Smash Zone Indore', 'Indoor badminton and box cricket.', 'Vijay Nagar, Indore', 22.7533, 75.8937, 'Badminton', 600.0, 4.5, 'https://images.unsplash.com/photo-1551829142-d9b8cf2c061d?q=80&w=2000&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1551829142-d9b8cf2c061d'], ARRAY['AC', 'Refreshments', 'Cafe', 'Covered'], true, true, true, NULL);

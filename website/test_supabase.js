import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.VITE_SUPABASE_URL, process.env.VITE_SUPABASE_ANON_KEY);

async function test() {
    const { data, error } = await supabase.from('facilities').select('*').limit(1);
    if (error) {
        console.error('Error:', error);
    } else {
        if (data && data.length > 0) {
            console.log('Sample data keys:', Object.keys(data[0]));
            console.log('Sample data:', data[0]);
        } else {
            console.log('No data found in facilities table.');
        }
    }
}
test();

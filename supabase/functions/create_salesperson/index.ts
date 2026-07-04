import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parse the request body from the Dashboard App
    const { email, password, name, phone, business_id, id_card_url, address } = await req.json()

    if (!email || !password || !name || !phone || !business_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 1. Create the user in Supabase Auth using the Admin API
    const { data: authData, error: authError } = await supabaseClient.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true,
      user_metadata: { name: name }
    })

    if (authError) throw authError
    const userId = authData.user.id

    // 2. Insert into profiles (the database trigger usually does this, but we explicitly set the role)
    const { error: profileError } = await supabaseClient
      .from('profiles')
      .upsert({
        id: userId,
        business_id: business_id,
        full_name: name,
        phone: phone,
        email: email,
        role: 'salesperson',
      })

    if (profileError) {
      // Rollback Auth user if profile fails
      await supabaseClient.auth.admin.deleteUser(userId)
      throw profileError
    }

    // 3. Insert into salespersons table
    const { error: salespersonError } = await supabaseClient
      .from('salespersons')
      .insert({
        business_id: business_id,
        profile_id: userId,
        name: name,
        phone: phone,
        address: address,
        id_card_url: id_card_url,
      })

    if (salespersonError) throw salespersonError

    return new Response(
      JSON.stringify({ 
        message: 'Salesperson created successfully', 
        user_id: userId 
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

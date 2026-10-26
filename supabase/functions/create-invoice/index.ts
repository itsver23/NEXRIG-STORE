import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
});
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  try {
    const url = Deno.env.get('SUPABASE_URL')!;
    const anon = Deno.env.get('SUPABASE_ANON_KEY')!;
    const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const secret = Deno.env.get('XENDIT_SECRET_KEY');
    if (!secret) return json({ error: 'Payment provider not configured' }, 503);
    const token = req.headers.get('Authorization');
    if (!token?.startsWith('Bearer ')) return json({ error: 'Sign in required' }, 401);
    const authClient = createClient(url, anon);
    const { data: auth, error: authError } = await authClient.auth.getUser(token.slice(7));
    if (authError || !auth.user) return json({ error: 'Invalid session' }, 401);
    const admin = createClient(url, service);
    const body = await req.json();
    const lines = body.items;
    if (!Array.isArray(lines) || lines.length < 1 || lines.length > 30) return json({ error: 'Invalid cart' }, 400);
    const quantities = new Map<string, number>();
    for (const line of lines) {
      if (typeof line.product_id !== 'string' || !/^[0-9a-f-]{36}$/i.test(line.product_id) || !Number.isSafeInteger(line.quantity) || line.quantity < 1 || line.quantity > 100) return json({ error: 'Invalid item' }, 400);
      quantities.set(line.product_id, (quantities.get(line.product_id) ?? 0) + line.quantity);
    }
    const { data: products, error: productError } = await admin.from('products').select('id,name,price,stock,is_active').in('id', [...quantities.keys()]);
    if (productError) throw productError;
    if (!products || products.length !== quantities.size || products.some(p => !p.is_active || p.stock < quantities.get(p.id)!)) return json({ error: 'Product unavailable or insufficient stock' }, 400);
    const total = products.reduce((sum, p) => sum + Number(p.price) * quantities.get(p.id)!, 0);
    if (!Number.isFinite(total) || total < 1 || total > 1000000) return json({ error: 'Invalid total' }, 400);
    // Resolve the selected saved address on the server and snapshot it onto
    // the order so later edits to the user's address book cannot change history.
    const delivery = body.delivery_address;
    if (!delivery || typeof delivery.address_id !== 'string' ||
        !/^[0-9a-f-]{36}$/i.test(delivery.address_id)) {
      return json({ error: 'Please select a saved delivery address' }, 400);
    }
    const { data: savedAddress, error: addressError } = await admin
      .from('addresses')
      .select('id, full_name, phone, street, barangay, city, province, zip_code')
      .eq('id', delivery.address_id)
      .eq('user_id', auth.user.id)
      .maybeSingle();
    if (addressError) throw addressError;
    if (!savedAddress) return json({ error: 'Selected delivery address was not found' }, 400);

    const recipientName = String(savedAddress.full_name ?? '').trim();
    const recipientPhone = String(savedAddress.phone ?? '').trim();
    const addressParts = [
      savedAddress.street, savedAddress.barangay, savedAddress.city,
      savedAddress.province, savedAddress.zip_code,
    ].map((part) => String(part ?? '').trim()).filter(Boolean);
    const deliveryAddress = addressParts.join(', ');
    if (!recipientName || !recipientPhone || !deliveryAddress) {
      return json({ error: 'Selected address is missing recipient details' }, 400);
    }

    const externalId = `nexrig_${crypto.randomUUID()}`;
    const { data: order, error: orderError } = await admin.from('orders').insert({
      user_id: auth.user.id,
      external_id: externalId,
      amount: total,
      status: 'PENDING',
      recipient_name: recipientName,
      recipient_phone: recipientPhone,
      delivery_address: deliveryAddress,
    }).select('id').single();
    if (orderError) throw orderError;
    const { error: itemError } = await admin.from('order_items').insert(products.map(p => ({ order_id: order.id, product_id: p.id, quantity: quantities.get(p.id), unit_price: p.price })));
    if (itemError) throw itemError;
    const invoice = await fetch('https://api.xendit.co/v2/invoices', {
      method: 'POST',
      headers: { Authorization: 'Basic ' + btoa(secret + ':'), 'Content-Type': 'application/json' },
      body: JSON.stringify({ external_id: externalId, amount: total, currency: 'PHP', description: 'NEXRIG STORE order', payer_email: auth.user.email }),
    });
    const result = await invoice.json();
    if (!invoice.ok || !result.invoice_url) {
      console.error('Xendit invoice error', invoice.status, result);
      await admin.from('orders').update({ status: 'FAILED' }).eq('id', order.id);
      return json({ error: 'Unable to create payment invoice' }, 502);
    }
    await admin.from('orders').update({ invoice_url: result.invoice_url }).eq('id', order.id);
    return json({ invoice_url: result.invoice_url, order_id: order.id });
  } catch (e) {
    console.error('create-invoice error', e);
    return json({ error: 'Checkout error' }, 500);
  }
});
